import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/agent_api.dart';
import '../../services/agent_messages.dart';
import '../../services/app_language.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chat/chat_widgets.dart';
import 'ai_chat_controller.dart';
import 'ai_chat_strings.dart';
import 'ai_tool_strings.dart';
import 'widgets/ai_conversation_list.dart';
import 'widgets/ai_message_view.dart';
import 'widgets/ai_notice_dialog.dart';
import 'widgets/answer_rating_bar.dart';
import 'widgets/message_menu.dart';

/// The AI assistant tab of the Chat screen, in the app's own UI. Same
/// bubbles, input bar and colors as the Care Team chat: AI notice,
/// past conversations, streaming answers with sources, and 911 / 988 replies.
/// Requests to the care team are sent from the side menu ("I need
/// assistance"), not from the assistant.
class AiChatView extends StatefulWidget {
  final String userId;

  /// The AI tab is the one on screen (the AI notice opens only then).
  final bool active;

  const AiChatView({required this.userId, required this.active, super.key});

  @override
  State<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<AiChatView> {
  late final AiChatController _c = AiChatController();
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();

  /// Keep the latest message in view while the patient is at the bottom.
  bool _stickToBottom = true;

  /// The patient's message being edited in the input bar (a new version
  /// replaces it), and the draft that was in the input bar before.
  String? _editingId;
  String _draftBeforeEdit = '';
  bool _noticeOpen = false;

  AiChatStrings get _t => AiChatStrings.of(AppLanguageController.instance.code);

  @override
  void initState() {
    super.initState();
    _c.addListener(_onChanged);
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final p = _scroll.position;
      _stickToBottom = p.maxScrollExtent - p.pixels < 80;
    });
    unawaited(_c.init());
  }

  @override
  void didUpdateWidget(AiChatView old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _afterFrame(_maybeOpenDialogs);
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _c.dispose();
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _afterFrame(VoidCallback f) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) f();
      });

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    if (_stickToBottom) _afterFrame(_jumpToBottom);
    _afterFrame(_maybeOpenDialogs);
  }

  void _jumpToBottom() {
    if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  // ---------------------------------------------------------------- dialogs

  void _maybeOpenDialogs() {
    if (!widget.active || !mounted) return;
    if (_c.phase == AiChatPhase.ready && _c.noticeNeeded && !_noticeOpen) {
      _noticeOpen = true;
      showAiNoticeDialog(
        context,
        controller: _c,
        onOpenLink: _openLink,
      ).whenComplete(() {
        _noticeOpen = false;
      });
    }
  }

  // ---------------------------------------------------------------- editing

  /// Long press on the patient's message: Copy and Edit, over a blurred
  /// screen ([bubbleContext] is the bubble, drawn sharp where it is).
  void _showMessageActions(
    BuildContext bubbleContext,
    AgentMessage m,
    AiChatStrings t,
    Widget bubble,
  ) {
    final box = bubbleContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _focus.unfocus();
    unawaited(HapticFeedback.mediumImpact());
    unawaited(
      showMessageMenu(
        context,
        anchor: box.localToGlobal(Offset.zero) & box.size,
        preview: bubble,
        items: [
          MessageMenuItem(
            icon: Icons.copy_rounded,
            label: t.copy,
            onTap: () => Clipboard.setData(ClipboardData(text: m.text)),
          ),
          if (isServerMessageId(m.id))
            MessageMenuItem(
              icon: Icons.edit_outlined,
              label: t.edit,
              onTap: () => _startEdit(m),
            ),
        ],
      ),
    );
  }

  /// The message's text goes into the input bar; what came after it leaves
  /// the screen until the edit is sent or cancelled.
  void _startEdit(AgentMessage m) {
    if (_c.busy) return;
    setState(() {
      if (_editingId == null) _draftBeforeEdit = _input.text;
      _editingId = m.id;
      _input.text = m.text;
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
    });
    _focus.requestFocus();
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _input.text = _draftBeforeEdit;
      _draftBeforeEdit = '';
    });
    _focus.unfocus();
  }

  Widget _editBanner(AiChatStrings t) => ChatEditBanner(
    label: t.editingMessage,
    cancelLabel: t.cancel,
    onCancel: _cancelEdit,
  );

  Future<void> _switchVersion(String messageId) async {
    try {
      await _c.switchVersion(messageId);
    } catch (e) {
      debugPrint('AI chat: could not switch version: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(_t.versionFailed),
        ),
      );
    }
  }

  // ---------------------------------------------------------------- links

  static const Set<String> _externalSchemes = {
    'https',
    'http',
    'tel',
    'mailto',
    'sms',
  };

  /// Links in answers open on the phone: web pages in the browser, tel: in
  /// the dialer (911 / 988), mailto: / sms: in those apps.
  void _openLink(Uri uri) {
    if (!_externalSchemes.contains(uri.scheme.toLowerCase())) return;
    unawaited(
      launchUrl(uri, mode: LaunchMode.externalApplication).catchError((
        Object e,
      ) {
        debugPrint('AI chat: could not open a ${uri.scheme} link: $e');
        return false;
      }),
    );
  }

  /// The original file of a cited library document (a short-lived link).
  Future<void> _openDocument(String documentId) async {
    final url = await AgentApi.instance.documentUrl(documentId);
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok) throw const AgentApiException('Could not open the file.');
  }

  // ---------------------------------------------------------------- send

  void _send([String? suggestion]) {
    final text = (suggestion ?? _input.text).trim();
    if (text.isEmpty || _c.busy) return;
    _stickToBottom = true;
    _c.clearProblem();
    final editing = _editingId;
    if (editing != null && suggestion == null) {
      setState(() {
        _editingId = null;
        _draftBeforeEdit = '';
      });
      unawaited(_c.edit(editing, text));
    } else {
      unawaited(_c.send(text));
    }
    if (suggestion == null) _input.clear();
    _focus.unfocus();
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final t = _t;
    if (_c.phase == AiChatPhase.connecting) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.purple),
      );
    }
    if (_c.showingList) {
      return AiConversationList(controller: _c, strings: t);
    }
    return Column(
      children: [
        _buildThreadHeader(t),
        Expanded(
          child: _c.threadLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.purple),
                )
              : _c.messages.isEmpty
              ? _buildEmptyState(t)
              : _buildMessageList(t),
        ),
        ChatInputBar(
          controller: _input,
          focusNode: _focus,
          enabled: !_c.threadLoading,
          hintText: t.placeholder,
          sendLabel: t.send,
          onSend: _send,
          busy: _c.busy,
          onStop: _c.stop,
          stopLabel: t.stop,
          banner: _editingId == null ? null : _editBanner(t),
        ),
      ],
    );
  }

  /// History (past conversations), the conversation's title, and New.
  Widget _buildThreadHeader(AiChatStrings t) {
    final title = _c.titleOf(_c.conversationId) ?? t.newConversation;
    return Container(
      height: 52,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 4, 0),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          // A labeled button, not a second ☰: testers did not find their old
          // chats behind an icon that looks like the side menu's.
          Semantics(
            button: true,
            label: t.yourConversations,
            child: Material(
              color: AppTheme.surfaceVariantLight,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _c.busy ? null : _c.showList,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: 17,
                        color: AppTheme.textDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t.history,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
          IconButton(
            tooltip: t.newConversation,
            onPressed: _c.busy ? null : _c.startNew,
            icon: const Icon(Icons.add_comment_outlined),
            color: AppTheme.textDark,
            iconSize: 21,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AiChatStrings t) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focus.unfocus(),
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppTheme.purpleContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppTheme.purple,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t.emptyTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.emptySubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textMedium,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              for (final s in t.suggestions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _c.busy ? null : () => _send(s),
                      style: OutlinedButton.styleFrom(
                        alignment: AlignmentDirectional.centerStart,
                        backgroundColor: AppTheme.surfaceLight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        side: const BorderSide(color: AppTheme.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        s,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_c.chatProblem != null) ...[
                const SizedBox(height: 8),
                _problemLine(t),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime dt) {
    final l = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(l.year, l.month, l.day);
    if (day == today) return context.l10n.dateToday;
    if (day == today.subtract(const Duration(days: 1))) {
      return context.l10n.dateYesterday;
    }
    return context.l10n.monthDayYear(l);
  }

  Widget _problemLine(AiChatStrings t) {
    final text = _c.chatProblem == AiChatProblem.signInAgain
        ? t.signInAgain
        : t.chatError;
    return Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 16,
          color: AppTheme.errorColor,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.errorColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList(AiChatStrings t) {
    // While a message is being edited, what came after it is not shown.
    final editAt = _editingId == null
        ? -1
        : _c.messages.indexWhere((m) => m.id == _editingId);
    final msgs = editAt < 0 ? _c.messages : _c.messages.sublist(0, editAt + 1);
    final busy = _c.busy;
    final last = msgs.last;
    final waitingForFirstToken =
        _c.status == AiChatStatus.submitted && last.isUser;
    final extra =
        (waitingForFirstToken ? 1 : 0) + (_c.chatProblem != null ? 1 : 0);
    return ListView.builder(
      controller: _scroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      itemCount: msgs.length + extra,
      itemBuilder: (context, i) {
        if (i >= msgs.length) {
          if (waitingForFirstToken && i == msgs.length) {
            return ChatBubble(
              isUser: false,
              avatar: _aiAvatar,
              senderLabel: context.l10n.chatAiTitle,
              maxWidth: 82.w,
              child: AiWaitingStatus(label: t.thinking, hint: t.waitHint),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _problemLine(t),
          );
        }
        final m = msgs[i];
        final isLast = i == msgs.length - 1;
        final showDate =
            i == 0 || !chatIsSameDay(msgs[i - 1].createdAt, m.createdAt);
        final streaming = busy && isLast && !m.isUser;
        final userBubble = m.isUser
            ? ChatBubble(
                isUser: true,
                maxWidth: 75.w,
                footer: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (m.siblingIds.length > 1) ...[
                      _VersionSwitcher(
                        message: m,
                        strings: t,
                        enabled: !busy && _editingId == null,
                        onSwitch: _switchVersion,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      context.l10n.time(m.createdAt.toLocal()),
                      style: chatMetaTextStyle(),
                    ),
                  ],
                ),
                child: Text(m.text, style: chatBubbleTextStyle(isUser: true)),
              )
            : null;
        final bubble = userBubble != null
            ? Builder(
                builder: (bubbleContext) => GestureDetector(
                  onLongPress: busy
                      ? null
                      : () => _showMessageActions(
                          bubbleContext,
                          m,
                          t,
                          userBubble,
                        ),
                  child: userBubble,
                ),
              )
            : ChatBubble(
                isUser: false,
                avatar: _aiAvatar,
                senderLabel: context.l10n.chatAiTitle,
                maxWidth: 82.w,
                footer: streaming
                    ? null
                    : Text(
                        context.l10n.time(m.createdAt.toLocal()),
                        style: chatMetaTextStyle(),
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AiMessageView(
                      message: m,
                      streaming: streaming,
                      strings: t,
                      toolStrings: AiToolStrings.of(
                        AppLanguageController.instance.code,
                      ),
                      onOpenLink: _openLink,
                      onOpenDocument: _openDocument,
                    ),
                    // Trial ratings, as in the web chat: once the answer is
                    // complete and has the server's id.
                    if (!streaming && isServerMessageId(m.id))
                      AnswerRatingBar(
                        key: ValueKey('rating-${m.id}'),
                        messageId: m.id,
                        rating: _c.ratings[m.id],
                        onChange: _c.changeRating,
                      ),
                  ],
                ),
              );
        return Column(
          key: ValueKey(m.id),
          children: [
            if (showDate) ChatDateSeparator(label: _dateLabel(m.createdAt)),
            bubble,
          ],
        );
      },
    );
  }

  static const Widget _aiAvatar = ChatAvatar(
    icon: Icons.auto_awesome_outlined,
    color: AppTheme.purple,
    background: AppTheme.purpleContainer,
  );
}

/// "‹ 2/3 ›" under a message with several versions.
class _VersionSwitcher extends StatelessWidget {
  final AgentMessage message;
  final AiChatStrings strings;
  final bool enabled;
  final void Function(String messageId) onSwitch;

  const _VersionSwitcher({
    required this.message,
    required this.strings,
    required this.enabled,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final versions = message.siblingIds;
    final at = versions.indexOf(message.id);
    if (at < 0) return const SizedBox.shrink();
    Widget arrow(IconData icon, String label, int to) {
      final ok = enabled && to >= 0 && to < versions.length;
      return Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: ok ? () => onSwitch(versions[to]) : null,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              icon,
              size: 18,
              color: ok ? AppTheme.textMedium : AppTheme.borderColor,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        arrow(Icons.chevron_left_rounded, strings.previousVersion, at - 1),
        Text('${at + 1}/${versions.length}', style: chatMetaTextStyle()),
        arrow(Icons.chevron_right_rounded, strings.nextVersion, at + 1),
      ],
    );
  }
}
