// Messages of the AI assistant, as the server stores and streams them.
//
// The server (happyheartsdash, /api/agent/*) uses the Vercel AI SDK's
// "UI message" format: a message is a list of parts (text, tool calls, ...).
// History comes as JSON parts; a new reply comes as a stream of chunks
// (text-delta, tool-input-available, tool-approval-request, ...) that
// [AgentMessageAssembler] turns into the same parts, the way the SDK's own
// client does (processUIMessageStream in the `ai` package).

/// Tool names the app reacts to (server: src/lib/server/agent/tools.ts).
const String kSearchTool = 'searchKnowledge';
const String kWebSearchTool = 'webSearch';

/// The care-team offer the assistant made until 2026-11-23 (removed: requests
/// go through the side menu). Older replies still contain it: it is not shown,
/// but its situation still marks an emergency reply.
const String kOldCareteamTool = 'notifyCareteam';

/// Tool-call states (AI SDK): input-streaming, input-available,
/// approval-requested, approval-responded, output-available, output-error,
/// output-denied.
class AgentPart {
  /// `text`, `reasoning`, `step-start`, `tool-<name>`, `dynamic-tool`, ...
  String type;

  /// Text of a text or reasoning part.
  String text;

  /// Tool calls only.
  String? toolCallId;
  String? state;
  Object? input;
  Object? output;
  String? errorText;
  String? approvalId;

  /// The user's answer to an approval request (approval-responded).
  bool? approved;
  String? approvalReason;

  /// Tool name of a 'dynamic-tool' part (others carry it in [type]).
  String? dynamicToolName;

  AgentPart({
    required this.type,
    this.text = '',
    this.toolCallId,
    this.state,
    this.input,
    this.output,
    this.errorText,
    this.approvalId,
    this.approved,
    this.approvalReason,
    this.dynamicToolName,
  });

  bool get isTool =>
      toolCallId != null &&
      (type.startsWith('tool-') || type == 'dynamic-tool');

  String? get toolName => type == 'dynamic-tool'
      ? dynamicToolName
      : (type.startsWith('tool-') ? type.substring(5) : null);

  bool get isText => type == 'text';

  /// The tool call is still being written or run.
  bool get isRunning =>
      state == 'input-streaming' || state == 'input-available';

  /// The tool input as a map (empty when missing).
  Map<String, dynamic> get inputMap =>
      input is Map ? Map<String, dynamic>.from(input as Map) : const {};

  Map<String, dynamic> get outputMap =>
      output is Map ? Map<String, dynamic>.from(output as Map) : const {};

  factory AgentPart.fromJson(Map<String, dynamic> j) {
    final approval = j['approval'];
    return AgentPart(
      type: (j['type'] as String?) ?? '',
      text: (j['text'] as String?) ?? '',
      toolCallId: j['toolCallId'] as String?,
      state: j['state'] as String?,
      input: j['input'],
      output: j['output'],
      errorText: j['errorText'] as String?,
      approvalId: approval is Map ? approval['id'] as String? : null,
      approved: approval is Map ? approval['approved'] as bool? : null,
      approvalReason: approval is Map ? approval['reason'] as String? : null,
      dynamicToolName: j['toolName'] as String?,
    );
  }
}

class AgentMessage {
  String id;

  /// 'user' or 'assistant'.
  final String role;
  final List<AgentPart> parts;
  DateTime createdAt;

  /// The versions of this message (itself included), oldest first: editing a
  /// message adds a version, and "‹ 2/3 ›" switches between them.
  List<String> siblingIds;

  AgentMessage({
    required this.id,
    required this.role,
    required this.parts,
    DateTime? createdAt,
    List<String>? siblingIds,
  }) : createdAt = createdAt ?? DateTime.now(),
       siblingIds = siblingIds ?? [id];

  bool get isUser => role == 'user';

  /// The plain text of the message (text parts joined).
  String get text => parts.where((p) => p.isText).map((p) => p.text).join('\n');

  factory AgentMessage.fromJson(Map<String, dynamic> j) {
    final parts = (j['parts'] as List? ?? const [])
        .whereType<Map>()
        .map((p) => AgentPart.fromJson(Map<String, dynamic>.from(p)))
        .toList();
    final id = (j['id'] as String?) ?? '';
    final siblings = (j['siblingIds'] as List? ?? const [])
        .whereType<String>()
        .toList();
    return AgentMessage(
      id: id,
      role: (j['role'] as String?) ?? 'assistant',
      parts: parts,
      createdAt: DateTime.tryParse((j['createdAt'] as String?) ?? ''),
      siblingIds: siblings.isEmpty ? [id] : siblings,
    );
  }

  /// A user message written on this phone (before the server has it).
  factory AgentMessage.user(String text) => AgentMessage(
    id: 'local-${DateTime.now().microsecondsSinceEpoch}',
    role: 'user',
    parts: [AgentPart(type: 'text', text: text)],
  );
}

class AgentConversation {
  final String id;
  String? title;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  AgentConversation({
    required this.id,
    required this.title,
    required this.lastMessageAt,
    required this.createdAt,
  });

  factory AgentConversation.fromJson(Map<String, dynamic> j) =>
      AgentConversation(
        id: j['id'] as String,
        title: j['title'] as String?,
        lastMessageAt: DateTime.tryParse((j['lastMessageAt'] as String?) ?? ''),
        createdAt:
            DateTime.tryParse((j['createdAt'] as String?) ?? '') ??
            DateTime.now(),
      );
}

/// Turns the chunks of one reply stream into an assistant message.
///
/// A reply that continues after the user answered an approval keeps adding to
/// the same message (the server sends the old message id in its `start` chunk).
class AgentMessageAssembler {
  AgentMessageAssembler({required this.message, this.onTitle});

  /// The message being built (a new one, or the last assistant message when
  /// the reply continues after an approval).
  final AgentMessage message;

  /// The generated title of a new conversation (a transient data chunk).
  final void Function(String conversationId, String title)? onTitle;

  final Map<String, AgentPart> _activeText = {};

  /// Set by an `error` chunk.
  String? errorText;
  bool finished = false;
  bool aborted = false;

  List<AgentPart> get _currentStep {
    final parts = message.parts;
    var i = parts.length - 1;
    while (i >= 0 && parts[i].type != 'step-start') {
      i--;
    }
    return parts.sublist(i + 1);
  }

  AgentPart? _tool(String? toolCallId) {
    if (toolCallId == null) return null;
    for (final p in _currentStep) {
      if (p.isTool && p.toolCallId == toolCallId) return p;
    }
    for (final p in message.parts.reversed) {
      if (p.isTool && p.toolCallId == toolCallId) return p;
    }
    return null;
  }

  AgentPart _toolOrNew(Map<String, dynamic> c) {
    final existing = _tool(c['toolCallId'] as String?);
    if (existing != null) return existing;
    final dynamicTool = c['dynamic'] == true;
    final name = (c['toolName'] as String?) ?? '';
    final part = AgentPart(
      type: dynamicTool ? 'dynamic-tool' : 'tool-$name',
      toolCallId: c['toolCallId'] as String?,
      dynamicToolName: dynamicTool ? name : null,
    );
    message.parts.add(part);
    return part;
  }

  /// Applies one chunk. Returns true when the message changed.
  bool apply(Map<String, dynamic> c) {
    final type = c['type'] as String? ?? '';
    switch (type) {
      case 'start':
        {
          final id = c['messageId'] as String?;
          if (id != null && id.isNotEmpty) message.id = id;
          return false;
        }
      case 'text-start':
        {
          final part = AgentPart(type: 'text');
          _activeText[(c['id'] as String?) ?? ''] = part;
          message.parts.add(part);
          return true;
        }
      case 'text-delta':
        {
          final key = (c['id'] as String?) ?? '';
          var part = _activeText[key];
          if (part == null) {
            // Be forgiving: a delta without its start still shows.
            part = AgentPart(type: 'text');
            _activeText[key] = part;
            message.parts.add(part);
          }
          part.text += (c['delta'] as String?) ?? '';
          return true;
        }
      case 'text-end':
        {
          _activeText.remove((c['id'] as String?) ?? '');
          return false;
        }
      case 'tool-input-start':
        {
          final part = _toolOrNew(c);
          part.state = 'input-streaming';
          return true;
        }
      case 'tool-input-delta':
        {
          return false;
        }
      case 'tool-input-available':
        {
          final part = _toolOrNew(c);
          part.state = 'input-available';
          part.input = c['input'];
          return true;
        }
      case 'tool-input-error':
        {
          final part = _toolOrNew(c);
          part.state = 'output-error';
          part.input = c['input'];
          part.errorText = c['errorText'] as String?;
          return true;
        }
      case 'tool-approval-request':
        {
          final part = _tool(c['toolCallId'] as String?);
          if (part == null) return false;
          part.state = 'approval-requested';
          part.approvalId = c['approvalId'] as String?;
          return true;
        }
      case 'tool-approval-response':
        {
          final id = c['approvalId'] as String?;
          for (final p in message.parts) {
            if (p.isTool && p.approvalId == id) {
              p.state = 'approval-responded';
              p.approved = c['approved'] as bool?;
              p.approvalReason = c['reason'] as String?;
              return true;
            }
          }
          return false;
        }
      case 'tool-output-available':
        {
          final part = _tool(c['toolCallId'] as String?);
          if (part == null) return false;
          part.state = 'output-available';
          part.output = c['output'];
          return true;
        }
      case 'tool-output-error':
        {
          final part = _tool(c['toolCallId'] as String?);
          if (part == null) return false;
          part.state = 'output-error';
          part.errorText = c['errorText'] as String?;
          return true;
        }
      case 'tool-output-denied':
        {
          final part = _tool(c['toolCallId'] as String?);
          if (part == null) return false;
          part.state = 'output-denied';
          return true;
        }
      case 'start-step':
        {
          message.parts.add(AgentPart(type: 'step-start'));
          return false;
        }
      case 'reset-step':
        {
          // The server discarded the step: drop what it had added.
          final step = _currentStep;
          _activeText.clear();
          if (step.isEmpty) return false;
          message.parts.removeRange(
            message.parts.length - step.length,
            message.parts.length,
          );
          return true;
        }
      case 'finish':
        {
          finished = true;
          return false;
        }
      case 'abort':
        {
          aborted = true;
          return false;
        }
      case 'error':
        {
          errorText = (c['errorText'] as String?) ?? 'error';
          return false;
        }
      case 'data-conversation-title':
        {
          final data = c['data'];
          if (data is Map) {
            final id = data['conversationId'];
            final title = data['title'];
            if (id is String && title is String && title.trim().isNotEmpty) {
              onTitle?.call(id, title.trim());
            }
          }
          return false;
        }
      default:
        {
          // reasoning-*, sources, files, step ends, metadata: nothing to show.
          return false;
        }
    }
  }
}

/// The patient's trial rating of one AI answer (table agent_answer_ratings,
/// API /api/agent/ratings). Each score is saved as soon as it is picked, so
/// one of them may still be empty.
class AgentAnswerRating {
  /// Highest scores: usability 1-5, safety 1 (unsafe) to 3 (safe).
  static const int topUsability = 5;
  static const int topSafety = 3;
  static const int maxComment = 300;

  final String messageId;
  final int? usability;
  final int? safety;
  final String comment;

  const AgentAnswerRating({
    required this.messageId,
    this.usability,
    this.safety,
    this.comment = '',
  });

  factory AgentAnswerRating.fromJson(Map<String, dynamic> j) =>
      AgentAnswerRating(
        messageId: j['messageId'].toString(),
        usability: (j['usability'] as num?)?.toInt(),
        safety: (j['safety'] as num?)?.toInt(),
        comment: (j['comment'] as String?) ?? '',
      );
}

final RegExp _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// The server's id of a saved message (a UUID); local placeholders are not.
bool isServerMessageId(String id) => _uuid.hasMatch(id);
