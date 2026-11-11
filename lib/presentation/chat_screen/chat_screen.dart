import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/auth_service.dart';
import '../../services/chat_controller.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_menu.dart';
import '../assistance/assistance_request_sheet.dart';
import '../assistance/my_assistance_requests_screen.dart';
import 'widgets/ai_assistant_web_stub.dart'
    if (dart.library.html) 'widgets/ai_assistant_web_impl.dart'
    as ai_platform;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatController? _chat;
  int _boundGeneration = -1;
  int _lastCount = 0;

  /// 0 = Care Team (human staff chat), 1 = AI Assistant (our agent, WebView).
  int _tab = 0;

  /// The AI WebView is created shortly after this screen opens (or right away
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
    // Let the Care Team chat render first, then start the AI assistant page.
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
    if (text.isEmpty) return;
    final id = await _chat?.send(text);
    if (id != null) {
      // Draft is cleared only once the message is queued locally; a failure
      // leaves it visible in the list (with retry), never overwriting a newer draft.
      _messageController.clear();
      _scrollToBottom();
    }
  }

  String _formatTime(DateTime dt) {
    final l = dt.toLocal();
    final hour = l.hour.toString().padLeft(2, '0');
    final minute = l.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime dt) {
    final l = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(l.year, l.month, l.day);
    if (msgDay == today) return 'Today';
    final yesterday = today.subtract(const Duration(days: 1));
    if (msgDay == yesterday) return 'Yesterday';
    return '${l.day}/${l.month}/${l.year}';
  }

  bool _showDateSeparator(List<ChatMessage> msgs, int index) {
    if (index == 0) return true;
    final prev = msgs[index - 1].createdAt.toLocal();
    final curr = msgs[index].createdAt.toLocal();
    return prev.day != curr.day ||
        prev.month != curr.month ||
        prev.year != curr.year;
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
    final isAi = _tab == 1;
    final userId = AuthService.instance.userId;
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
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
                isAi ? Icons.smart_toy_outlined : Icons.support_agent_rounded,
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
                    isAi ? 'AI Assistant' : 'Research Team',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    isAi ? 'Automated answers, 24/7' : 'Happy Hearts Study',
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
        bottom: PreferredSize(
          // 52 at the default text size; taller when the phone's text is larger.
          preferredSize: Size.fromHeight(
            32 + MediaQuery.textScalerOf(context).scale(20),
          ),
          child: _buildTabSwitcher(),
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _buildTeamChat(chat),
          if (!_aiStarted)
            const SizedBox.shrink()
          else if (userId == null)
            _buildErrorState('Please sign in to use the AI assistant.', null)
          else
            ai_platform.buildAiAssistantView(userId: userId),
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariantLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            tab(0, Icons.support_agent_rounded, 'Care Team'),
            tab(1, Icons.smart_toy_outlined, 'AI Assistant'),
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
              ? _buildErrorState('Please sign in to use chat.', null)
              : chat.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : chat.error != null
              ? _buildErrorState(chat.error!, chat.init)
              : chat.messages.isEmpty
              ? _buildEmptyState()
              : _buildMessageList(chat),
        ),
        _buildInputBar(
          enabled: chat != null && !chat.isLoading && chat.error == null,
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
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
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
                  'Need help with something?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                GestureDetector(
                  onTap: () => openMyAssistanceRequests(context),
                  child: Text(
                    'View my requests',
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
          Flexible(
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
                'I need assistance',
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
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppTheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start a conversation',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to the Happy Hearts research team. We\'re here to help with any questions about your study.',
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

  Widget _buildErrorState(String message, VoidCallback? onRetry) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppTheme.errorColor,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.textMedium,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(ChatController chat) {
    final msgs = chat.messages;
    return ListView.builder(
      controller: _scrollController,
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
              _buildDateSeparator(message.createdAt),
            _buildMessageBubble(message),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppTheme.borderColor, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatDate(date),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textLight,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppTheme.borderColor, thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUserMessage;
    final failed = message.sendState == SendState.failed;
    final pending = message.sendState == SendState.pending;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent_rounded,
                color: AppTheme.textMedium,
                size: 16,
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      'Research Team',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ),
                Opacity(
                  opacity: pending ? 0.7 : 1,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 70.w),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primary : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: failed
                          ? Border.all(color: AppTheme.errorColor, width: 1.5)
                          : isUser
                          ? null
                          : Border.all(color: AppTheme.borderColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      message.content,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: isUser ? Colors.white : AppTheme.textDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: failed
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Not sent',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: AppTheme.errorColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _chat?.retry(message.id),
                              child: Text(
                                'Retry',
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
                                'Delete',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          pending
                              ? 'Sending...'
                              : _formatTime(message.createdAt),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppTheme.textLight,
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildInputBar({required bool enabled}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.borderColor, width: 1)),
      ),
      padding: EdgeInsets.only(left: 4.w, right: 4.w, top: 10, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderColor, width: 1),
              ),
              child: TextField(
                controller: _messageController,
                enabled: enabled,
                maxLines: 4,
                minLines: 1,
                maxLength: 4000,
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Message the research team...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppTheme.textLight,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: enabled ? AppTheme.primary : AppTheme.textLight,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? _sendMessage : null,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
