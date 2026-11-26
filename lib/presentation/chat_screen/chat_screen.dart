import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/app_language.dart';
import '../../services/auth_service.dart';
import '../../services/chat_controller.dart';
import '../../services/chat_service.dart';
import '../../services/message_language_settings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/chat/chat_widgets.dart';
import '../../widgets/message_language_check.dart';
import '../ai_chat/ai_chat_view.dart';
import '../ai_chat/widgets/message_menu.dart';
import '../assistance/assistance_request_sheet.dart';
import '../assistance/my_assistance_requests_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  /// The language check before sending is running (blocks a second tap).
  bool _checkingLanguage = false;

  /// The sent message being edited in the input bar (null: writing a new one),
  /// and the draft that was in the input bar before.
  String? _editingId;
  String _draftBeforeEdit = '';
  bool _savingEdit = false;
  final ScrollController _scrollController = ScrollController();
  ChatController? _chat;
  int _boundGeneration = -1;
  int _lastCount = 0;

  /// 0 = Care Team (human staff chat), 1 = AI Assistant (our agent).
  int _tab = 0;

  /// The AI chat is created shortly after this screen opens (or right away
  /// when its tab is opened), then kept alive (IndexedStack) so switching tabs
  /// doesn't reload the conversation. Loading it in the background means the
  /// assistant is usually ready by the time the patient taps the tab.
  bool _aiStarted = false;
  Timer? _aiPrewarm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthService.instance.addListener(_onAuthChanged);
    _scrollController.addListener(_onScroll);
    _bind();
    // Languages the research team reads, for the check before sending.
    MessageLanguageSettings.instance.prefetch();
    // Let the Care Team chat render first, then start the AI assistant.
    _aiPrewarm = Timer(const Duration(milliseconds: 800), () {
      if (mounted && !_aiStarted) setState(() => _aiStarted = true);
    });
  }

  @override
  void dispose() {
    _aiPrewarm?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    AuthService.instance.removeListener(_onAuthChanged);
    _scrollController.removeListener(_onScroll);
    _chat?.removeListener(_onChatChanged);
    _chat?.dispose(); // unsubscribes Realtime
    _chat = null;
    _messageController.dispose();
    _inputFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// (Re)creates the controller whenever the signed-in account changes, so the
  /// previous user's subscription and in-memory messages are discarded.
  void _bind() {
    final auth = AuthService.instance;
    if (_boundGeneration == auth.generation && _chat != null) return;

    _chat?.removeListener(_onChatChanged);
    _chat?.dispose();
    _chat = null;
    _lastCount = 0;
    _messageController.clear();
    _editingId = null;
    _draftBeforeEdit = '';
    _boundGeneration = auth.generation;

    if (auth.isSignedIn) {
      final c = ChatController();
      c.addListener(_onChatChanged);
      _chat = c;
      c.init();
    }
    if (mounted) setState(() {});
  }

  void _onAuthChanged() => _bind();

  void _onChatChanged() {
    if (!mounted) return;
    final count = _chat?.messages.length ?? 0;
    final grew = count > _lastCount;
    final nearBottom =
        !_scrollController.hasClients ||
        _scrollController.position.maxScrollExtent -
                _scrollController.position.pixels <
            160;
    setState(() {});
    if (grew && nearBottom) _scrollToBottom();
    _lastCount = count;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <= 80) {
      _chat?.loadOlder();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _chat?.onResumed();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _checkingLanguage || _savingEdit) return;
    // Warn (don't block) when the team may not read the message's language.
    _checkingLanguage = true;
    final bool send;
    try {
      send = await confirmMessageLanguage(context, text);
    } finally {
      _checkingLanguage = false;
    }
    if (!mounted) return;
    if (!send) {
      _inputFocus.requestFocus(); // "Edit message": the draft stays
      return;
    }
    final editing = _editingId;
    if (editing != null) {
      await _saveEdit(editing, text);
      return;
    }
    final id = await _chat?.send(text);
    if (id != null) {
      // Draft is cleared only once the message is queued locally; a failure
      // leaves it visible in the list (with retry), never overwriting a newer draft.
      _messageController.clear();
      _scrollToBottom();
    }
  }

  // ---- Editing and deleting your own messages -------------------------------

  /// Long press on a message: Copy, and for your own message Edit (within 15
  /// minutes) and Delete, over a blurred screen.
  void _showMessageActions(
    BuildContext bubbleContext,
    ChatMessage m,
    Widget bubble,
  ) {
    final chat = _chat;
    final box = bubbleContext.findRenderObject() as RenderBox?;
    if (chat == null || box == null || !box.hasSize) return;
    _inputFocus.unfocus();
    unawaited(HapticFeedback.mediumImpact());
    unawaited(
      showMessageMenu(
        context,
        anchor: box.localToGlobal(Offset.zero) & box.size,
        preview: bubble,
        items: [
          MessageMenuItem(
            icon: Icons.copy_rounded,
            label: context.l10n.chatCopy,
            onTap: () => Clipboard.setData(ClipboardData(text: m.content)),
          ),
          if (chat.canEdit(m))
            MessageMenuItem(
              icon: Icons.edit_outlined,
              label: context.l10n.chatEdit,
              onTap: () => _startEdit(m),
            ),
          if (chat.canDelete(m))
            MessageMenuItem(
              icon: Icons.delete_outline_rounded,
              label: context.l10n.chatDelete,
              onTap: () => unawaited(_confirmDelete(m)),
            ),
        ],
      ),
    );
  }

  void _startEdit(ChatMessage m) {
    setState(() {
      if (_editingId == null) _draftBeforeEdit = _messageController.text;
      _editingId = m.id;
      _messageController.text = m.content;
      _messageController.selection = TextSelection.collapsed(
        offset: _messageController.text.length,
      );
    });
    _inputFocus.requestFocus();
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _messageController.text = _draftBeforeEdit;
      _draftBeforeEdit = '';
    });
    _inputFocus.unfocus();
  }

  Future<void> _saveEdit(String messageId, String text) async {
    final chat = _chat;
    if (chat == null) return;
    setState(() => _savingEdit = true);
    try {
      await chat.edit(messageId, text);
      if (!mounted) return;
      setState(() {
        _editingId = null;
        _messageController.text = _draftBeforeEdit;
        _draftBeforeEdit = '';
      });
      _inputFocus.unfocus();
    } on ChatException catch (e) {
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError(context.l10n.chatEditFailed);
    } finally {
      if (mounted) setState(() => _savingEdit = false);
    }
  }

  Future<void> _confirmDelete(ChatMessage m) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          context.l10n.chatDeleteConfirm,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text(context.l10n.chatDelete),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    if (_editingId == m.id) _cancelEdit();
    try {
      await _chat?.delete(m.id);
    } on ChatException catch (e) {
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError(context.l10n.chatDeleteFailed);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Placeholder text of a deleted message.
  String _deletedLabel(ChatMessage m) {
    if (m.isUserMessage && m.deletedByRole == 'team') {
      return context.l10n.chatRemovedByTeam;
    }
    if (m.isUserMessage) return context.l10n.chatYouDeleted;
    return context.l10n.chatMessageDeleted;
  }

  String _formatTime(DateTime dt) => context.l10n.time(dt.toLocal());

  String _formatDate(DateTime dt) {
    final l = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(l.year, l.month, l.day);
    if (msgDay == today) return context.l10n.dateToday;
    final yesterday = today.subtract(const Duration(days: 1));
    if (msgDay == yesterday) return context.l10n.dateYesterday;
    return context.l10n.monthDayYear(l);
  }

  bool _showDateSeparator(List<ChatMessage> msgs, int index) {
    if (index == 0) return true;
    return !chatIsSameDay(msgs[index - 1].createdAt, msgs[index].createdAt);
  }

  void _selectTab(int tab) {
    if (tab == _tab) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _tab = tab;
      if (tab == 1) _aiStarted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = _chat;
    final userId = AuthService.instance.userId;
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _buildTeamChat(chat),
                if (!_aiStarted)
                  const SizedBox.shrink()
                else if (userId == null)
                  ChatErrorState(message: context.l10n.chatSignInAi)
                else
                  AiChatView(
                    key: ValueKey('ai-$userId'),
                    userId: userId,
                    active: _tab == 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Menu button, who the patient is talking to, and the Care Team / AI switch.
  /// The ☰ sits where it sits on every other tab: 20 px from the left and from
  /// the top of the safe area (Education, Progress, Profile, Assessments).
  Widget _buildHeader() {
    final isAi = _tab == 1;
    return Container(
      color: AppTheme.surfaceLight,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  const AppMenuButton(),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isAi
                          ? AppTheme.purpleContainer
                          : AppTheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAi
                          ? Icons.smart_toy_outlined
                          : Icons.support_agent_rounded,
                      color: isAi ? AppTheme.purple : AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAi
                              ? context.l10n.chatAiTitle
                              : context.l10n.chatTeamTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          isAi
                              ? context.l10n.chatAiSubtitle
                              : context.l10n.chatTeamSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildTabSwitcher(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    Widget tab(int index, IconData icon, String label) {
      final selected = _tab == index;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _selectTab(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppTheme.surfaceLight : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? AppTheme.textDark : AppTheme.textLight,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: selected
                            ? AppTheme.textDark
                            : AppTheme.textMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariantLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            tab(0, Icons.support_agent_rounded, context.l10n.chatTabTeam),
            tab(1, Icons.smart_toy_outlined, context.l10n.chatAiTitle),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamChat(ChatController? chat) {
    return Column(
      children: [
        if (chat != null) _buildAssistanceBanner(),
        Expanded(
          child: chat == null
              ? ChatErrorState(message: context.l10n.chatSignIn)
              : chat.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : chat.error != null
              ? ChatErrorState(
                  message: chat.error!,
                  onRetry: chat.init,
                  retryLabel: context.l10n.retry,
                )
              : chat.messages.isEmpty
              ? _buildEmptyState()
              : _buildMessageList(chat),
        ),
        ChatInputBar(
          controller: _messageController,
          focusNode: _inputFocus,
          enabled:
              chat != null &&
              !chat.isLoading &&
              chat.error == null &&
              !_savingEdit,
          hintText: context.l10n.chatInputHint,
          sendLabel: context.l10n.chatSend,
          onSend: _sendMessage,
          banner: _editingId == null
              ? null
              : ChatEditBanner(
                  label: context.l10n.chatEditingMessage,
                  cancelLabel: context.l10n.cancel,
                  onCancel: _cancelEdit,
                ),
        ),
      ],
    );
  }

  /// Separate from chat: a request becomes a NEW alert on the staff dashboard
  /// and is tracked until a team member resolves it.
  Widget _buildAssistanceBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_rounded, color: AppTheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.chatNeedHelp,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                GestureDetector(
                  onTap: () => openMyAssistanceRequests(context),
                  child: Text(
                    context.l10n.chatViewRequests,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Its own width (up to ~45% of the screen, wrapping longer labels),
          // so the text keeps the rest of the row on every screen size.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.45,
            ),
            child: ElevatedButton(
              onPressed: () => showAssistanceRequestSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                context.l10n.menuAssistance,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppTheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.chatEmptyTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.chatEmptyBody,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppTheme.textMedium,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(ChatController chat) {
    final msgs = chat.messages;
    return ListView.builder(
      controller: _scrollController,
      // Dragging the messages puts the keyboard away.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      itemCount: msgs.length + (chat.isLoadingOlder ? 1 : 0),
      itemBuilder: (context, rawIndex) {
        if (chat.isLoadingOlder) {
          if (rawIndex == 0) {
            return const Padding(
              padding: EdgeInsets.all(8),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
        }
        final index = chat.isLoadingOlder ? rawIndex - 1 : rawIndex;
        final message = msgs[index];
        return Column(
          key: ValueKey(message.id),
          children: [
            if (_showDateSeparator(msgs, index))
              ChatDateSeparator(label: _formatDate(message.createdAt)),
            _buildMessageBubble(message),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUserMessage;
    final failed = message.sendState == SendState.failed;
    final pending = message.sendState == SendState.pending;
    // Which team member replied, e.g. "Laura · Research Team".
    final staffName = _chat?.staffNameFor(message);
    final senderLabel = staffName == null
        ? context.l10n.chatTeamTitle
        : '$staffName · ${context.l10n.chatTeamTitle}';

    if (message.isDeleted) {
      return ChatBubble(
        isUser: isUser,
        avatar: const ChatAvatar(icon: Icons.support_agent_rounded),
        senderLabel: senderLabel,
        footer: Text(
          _formatTime(message.createdAt),
          style: chatMetaTextStyle(),
        ),
        child: Text(
          _deletedLabel(message),
          style: chatBubbleTextStyle(isUser: isUser).copyWith(
            fontStyle: FontStyle.italic,
            color: isUser
                ? Colors.white.withValues(alpha: 0.8)
                : AppTheme.textLight,
          ),
        ),
      );
    }

    final bubble = _buildSentBubble(
      message,
      isUser,
      failed,
      pending,
      senderLabel,
    );
    if (message.sendState != SendState.sent) return bubble;
    return Builder(
      builder: (bubbleContext) => GestureDetector(
        onLongPress: () => _showMessageActions(bubbleContext, message, bubble),
        child: bubble,
      ),
    );
  }

  Widget _buildSentBubble(
    ChatMessage message,
    bool isUser,
    bool failed,
    bool pending,
    String senderLabel,
  ) {
    return ChatBubble(
      isUser: isUser,
      pending: pending,
      failed: failed,
      avatar: const ChatAvatar(icon: Icons.support_agent_rounded),
      senderLabel: senderLabel,
      footer: failed
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.chatNotSent,
                  style: chatMetaTextStyle(color: AppTheme.errorColor),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _chat?.retry(message.id),
                  child: Text(
                    context.l10n.retry,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _chat?.discard(message.id),
                  child: Text(
                    context.l10n.chatDelete,
                    style: chatMetaTextStyle(),
                  ),
                ),
              ],
            )
          : Text(
              pending
                  ? context.l10n.chatSending
                  : message.isEdited
                  ? '${_formatTime(message.createdAt)} · ${context.l10n.chatEdited}'
                  : _formatTime(message.createdAt),
              style: chatMetaTextStyle(),
            ),
      child: Text(message.content, style: chatBubbleTextStyle(isUser: isUser)),
    );
  }
}
