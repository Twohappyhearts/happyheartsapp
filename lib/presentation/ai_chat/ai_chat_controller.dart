import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../services/agent_api.dart';
import '../../services/agent_messages.dart';
import '../../services/auth_service.dart';

enum AiChatPhase { connecting, ready }

enum AiChatStatus { idle, submitted, streaming }

/// Why the conversation list shows an error (kept as a kind, so the text
/// follows a language change).
enum AiListProblem { listError, openError, deleteError, signInAgain }

/// Why the open chat shows an error.
enum AiChatProblem { chatError, signInAgain }

/// All state of the native AI chat for ONE signed-in account: the AI notice,
/// the conversation list, the open conversation and its streaming reply.
/// Talks to the dashboard's AI assistant API (/api/agent/*).
class AiChatController extends ChangeNotifier {
  AiChatController({AgentApi? api}) : _api = api ?? AgentApi.instance {
    _generation = AuthService.instance.generation;
  }

  final AgentApi _api;
  late final int _generation;
  bool _alive = true;

  // ---- Page state
  AiChatPhase phase = AiChatPhase.connecting;

  /// The patient must accept the AI notice first (first use, or it changed).
  bool noticeNeeded = false;
  bool acceptingNotice = false;
  bool noticeFailed = false;

  // ---- Conversation list
  List<AgentConversation> conversations = [];
  bool listLoading = true;
  AiListProblem? listProblem;
  bool showingList = false;

  // ---- Open conversation
  String? conversationId;
  List<AgentMessage> messages = [];
  bool threadLoading = false;
  AiChatStatus status = AiChatStatus.idle;
  AiChatProblem? chatProblem;

  /// conversationId → its messages as last seen (opening it again is instant).
  final Map<String, List<AgentMessage>> _cache = {};
  final Map<String, Future<List<AgentMessage>>> _inflight = {};

  /// conversationId → the patient's trial ratings there (messageId → rating).
  final Map<String, Map<String, AgentAnswerRating>> _ratings = {};

  /// Conversations whose reply the patient stopped: the copy here is partial
  /// (the server finished it), so it is loaded again instead of cached.
  final Set<String> _partial = {};

  CancelToken? _cancel;
  Timer? _throttle;
  bool _dirty = false;

  /// Loading another version of a message.
  bool switching = false;

  bool get busy =>
      status == AiChatStatus.submitted ||
      status == AiChatStatus.streaming ||
      switching;

  bool get _stale => !_alive || AuthService.instance.generation != _generation;

  String? titleOf(String? id) {
    if (id == null) return null;
    for (final c in conversations) {
      if (c.id == id) {
        final t = c.title?.trim();
        return t == null || t.isEmpty ? null : t;
      }
    }
    return null;
  }

  void _notify() {
    if (_alive) notifyListeners();
  }

  /// While a reply streams, redraw at most every 60 ms.
  void _notifyThrottled() {
    _dirty = true;
    if (_throttle != null) return;
    _throttle = Timer(const Duration(milliseconds: 60), () {
      _throttle = null;
      if (_dirty) {
        _dirty = false;
        _notify();
      }
    });
  }

  @override
  void dispose() {
    _alive = false;
    _throttle?.cancel();
    _cancel?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------- start

  Future<void> init() async {
    unawaited(loadList());
    await checkNotice();
    if (_stale) return;
    phase = AiChatPhase.ready;
    _notify();
  }

  /// Has the patient accepted the current notice and Terms of Use? If the
  /// check fails, show the notice: accepting again changes nothing.
  Future<void> checkNotice() async {
    AgentConsentStatus? consent;
    try {
      consent = await _api.consent();
    } catch (_) {
      consent = null;
    }
    if (_stale) return;
    noticeNeeded = consent == null || consent.needsNotice;
    _notify();
  }

  Future<void> acceptNotice() async {
    acceptingNotice = true;
    noticeFailed = false;
    _notify();
    try {
      await _api.acceptConsent();
      if (_stale) return;
      noticeNeeded = false;
    } catch (_) {
      if (_stale) return;
      noticeFailed = true;
    } finally {
      if (!_stale) {
        acceptingNotice = false;
        _notify();
      }
    }
  }

  // ---------------------------------------------------------------- list

  Future<void> loadList({bool silent = false}) async {
    if (!silent) {
      listLoading = true;
      _notify();
    }
    try {
      final list = await _api.conversations();
      if (_stale) return;
      conversations = list;
      listProblem = null;
      // Load the newest few ahead, so opening them is instant.
      for (final c in list.take(5)) {
        if (!_cache.containsKey(c.id)) {
          unawaited(_fetch(c.id).then((_) {}, onError: (_) {}));
        }
      }
    } catch (e) {
      if (_stale) return;
      listProblem = e is AgentApiException && e.unauthorized
          ? AiListProblem.signInAgain
          : AiListProblem.listError;
    } finally {
      if (!_stale) {
        listLoading = false;
        _notify();
      }
    }
  }

  Future<List<AgentMessage>> _fetch(String id) {
    final running = _inflight[id];
    if (running != null) return running;
    final f = _api.messages(id).then((list) {
      _cache[id] = list;
      _partial.remove(id);
      return list;
    });
    _inflight[id] = f;
    f.whenComplete(() => _inflight.remove(id)).ignore();
    return f;
  }

  void showList() {
    if (busy) return;
    showingList = true;
    _notify();
    unawaited(loadList(silent: true));
  }

  /// The patient's ratings of the answers in the open conversation.
  Map<String, AgentAnswerRating> get ratings =>
      _ratings[conversationId] ?? const {};

  /// Loads the ratings of a conversation (also ones made in the web chat). A
  /// rating saved here in the meantime wins over the loaded one.
  Future<void> _loadRatings(String id) async {
    try {
      final list = await _api.ratings(id);
      if (_stale) return;
      _ratings[id] = {for (final r in list) r.messageId: r, ...?_ratings[id]};
      if (conversationId == id) _notify();
    } catch (e) {
      debugPrint('AI chat: could not load ratings: $e');
    }
  }

  /// Changes the patient's rating of an answer: only the fields in [change]
  /// ('usability' / 'safety', null clears it; 'comment'). Returns the rating
  /// as saved, or null when it was deleted. Throws [AgentApiException].
  Future<AgentAnswerRating?> changeRating(
    String messageId,
    Map<String, Object?> change,
  ) async {
    final id = conversationId;
    AgentAnswerRating? saved;
    try {
      saved = await _api.saveRating(messageId, change);
    } on AgentApiException catch (e) {
      // The server saves an answer when its stream ends, so a rating made
      // right after it can arrive first (404): try once more a moment later.
      if (e.status != 404) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      saved = await _api.saveRating(messageId, change);
    }
    if (_stale || id == null) return saved;
    final map = _ratings[id] ??= {};
    if (saved == null) {
      map.remove(messageId);
    } else {
      map[messageId] = saved;
    }
    _notify();
    return saved;
  }

  void showChat() {
    showingList = false;
    _notify();
  }

  void startNew() {
    if (busy) return;
    _rememberCurrent();
    conversationId = null;
    messages = [];
    chatProblem = null;
    threadLoading = false;
    showingList = false;
    _notify();
  }

  /// Opens a conversation: cached messages right away, else a spinner.
  Future<void> open(String id) async {
    listProblem = null;
    if (id == conversationId && !threadLoading) {
      showChat();
      return;
    }
    _rememberCurrent();
    conversationId = id;
    chatProblem = null;
    showingList = false;
    unawaited(_loadRatings(id));
    final cached = _cache[id];
    if (cached != null) {
      messages = List.of(cached);
      threadLoading = false;
      _notify();
      return;
    }
    messages = [];
    threadLoading = true;
    _notify();
    try {
      final list = await _fetch(id);
      if (_stale || conversationId != id) return;
      messages = List.of(list);
      threadLoading = false;
      _notify();
    } catch (e) {
      if (_stale || conversationId != id) return;
      conversationId = null;
      messages = [];
      threadLoading = false;
      showingList = true;
      listProblem = e is AgentApiException && e.unauthorized
          ? AiListProblem.signInAgain
          : AiListProblem.openError;
      _notify();
    }
  }

  Future<bool> delete(AgentConversation c) async {
    try {
      await _api.deleteConversation(c.id);
      if (_stale) return false;
      conversations = conversations.where((x) => x.id != c.id).toList();
      _cache.remove(c.id);
      _ratings.remove(c.id);
      if (c.id == conversationId) {
        conversationId = null;
        messages = [];
      }
      _notify();
      return true;
    } catch (e) {
      if (_stale) return false;
      listProblem = e is AgentApiException && e.unauthorized
          ? AiListProblem.signInAgain
          : AiListProblem.deleteError;
      _notify();
      return false;
    }
  }

  void _rememberCurrent() {
    final id = conversationId;
    if (id != null && !busy && messages.isNotEmpty && !_partial.contains(id)) {
      _cache[id] = List.of(messages);
    }
  }

  void _applyTitle(String id, String title) {
    final i = conversations.indexWhere((c) => c.id == id);
    if (i >= 0) {
      conversations[i].title = title;
    } else {
      final now = DateTime.now();
      conversations = [
        AgentConversation(
          id: id,
          title: title,
          lastMessageAt: now,
          createdAt: now,
        ),
        ...conversations,
      ];
    }
    _notifyThrottled();
  }

  // ---------------------------------------------------------------- chat

  void clearProblem() {
    if (chatProblem == null) return;
    chatProblem = null;
    _notify();
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || busy || trimmed.length > 4000) return;
    chatProblem = null;
    final mine = AgentMessage.user(trimmed);
    messages = [...messages, mine];
    await _runTurn(message: trimmed, mine: mine);
  }

  /// Sends [text] as a new version of the patient's message [messageId]: it
  /// and everything after it leave the screen, and the reply starts a new
  /// branch (the old one stays, under "‹ 1/2 ›").
  Future<void> edit(String messageId, String text) async {
    final trimmed = text.trim();
    final i = messages.indexWhere((m) => m.id == messageId);
    if (i < 0 || trimmed.isEmpty || busy || trimmed.length > 4000) return;
    chatProblem = null;
    final old = messages[i];
    final mine = AgentMessage.user(trimmed)
      ..siblingIds = List.of(old.siblingIds);
    messages = [...messages.sublist(0, i), mine];
    await _runTurn(message: trimmed, mine: mine, editOf: old.id);
  }

  /// Shows another version of a message: the branch under it replaces what
  /// is on screen. Throws [AgentApiException].
  Future<void> switchVersion(String messageId) async {
    final id = conversationId;
    if (id == null || busy) return;
    switching = true;
    chatProblem = null;
    _notify();
    try {
      final list = await _api.switchBranch(id, messageId);
      if (_stale || conversationId != id) return;
      messages = list;
      _cache[id] = List.of(list);
      _partial.remove(id);
    } finally {
      switching = false;
      _notify();
    }
  }

  /// Stops showing the reply. The server still finishes and saves it.
  void stop() {
    _cancel?.cancel();
  }

  /// [mine]: the patient's message on screen (it gets the server's id).
  /// [editOf]: the message [mine] is a new version of.
  Future<void> _runTurn({
    required String message,
    required AgentMessage mine,
    String? editOf,
  }) async {
    final cancel = CancelToken();
    _cancel = cancel;
    status = AiChatStatus.submitted;
    _notify();
    final startedFor = conversationId;
    var gotChunks = false;
    try {
      final turn = await _api.startTurn(
        conversationId: conversationId,
        message: message,
        editOf: editOf,
        cancelToken: cancel,
      );
      if (_stale) return;
      final serverId = turn.userMessageId;
      if (serverId != null) {
        mine.id = serverId;
        mine.siblingIds = editOf == null
            ? [serverId]
            : [...mine.siblingIds, serverId];
      }
      final newId = turn.conversationId;
      if (startedFor == null && newId != null && conversationId == null) {
        conversationId = newId;
        unawaited(loadList(silent: true));
      }
      final chunks = turn.chunks;
      final target = AgentMessage(
        id: 'reply-${DateTime.now().microsecondsSinceEpoch}',
        role: 'assistant',
        parts: [],
      );
      final assembler = AgentMessageAssembler(
        message: target,
        onTitle: _applyTitle,
      );
      await for (final chunk in chunks) {
        if (_stale || cancel.isCancelled) break;
        if (!gotChunks) {
          gotChunks = true;
          messages = [...messages, target];
          status = AiChatStatus.streaming;
        }
        if (assembler.apply(chunk)) _notifyThrottled();
      }
      if (assembler.errorText != null) {
        chatProblem = AiChatProblem.chatError;
      }
    } on DioException catch (e) {
      if (!CancelToken.isCancel(e) && !_stale) {
        chatProblem = AiChatProblem.chatError;
      }
    } on AgentApiException catch (e) {
      if (_stale) return;
      if (e.forbidden) {
        // A new notice or Terms of Use came out while the chat was open.
        unawaited(checkNotice());
      }
      chatProblem = e.unauthorized
          ? AiChatProblem.signInAgain
          : AiChatProblem.chatError;
    } catch (_) {
      if (!_stale && !cancel.isCancelled) chatProblem = AiChatProblem.chatError;
    } finally {
      if (identical(_cancel, cancel)) _cancel = null;
      if (!_stale) {
        status = AiChatStatus.idle;
        _throttle?.cancel();
        _throttle = null;
        _dirty = false;
        final id = conversationId;
        if (id != null) {
          // Stopped: the server still finishes and saves the reply, so the
          // next open loads it instead of this partial copy.
          if (cancel.isCancelled) {
            _cache.remove(id);
            _partial.add(id);
          } else {
            _cache[id] = List.of(messages);
          }
        }
        _notify();
        unawaited(loadList(silent: true));
      }
    }
  }
}
