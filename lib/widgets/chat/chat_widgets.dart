import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../theme/app_theme.dart';

/// Building blocks shared by the two chats on the Chat tab: the Care Team chat
/// (ChatScreen) and the AI assistant (AiChatView). Both look the same: these
/// were the Care Team chat's own widgets, moved here unchanged.

/// Small round icon next to a message from the other side.
class ChatAvatar extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;

  const ChatAvatar({
    required this.icon,
    this.color = AppTheme.textMedium,
    this.background = AppTheme.surfaceVariantLight,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsetsDirectional.only(end: 8, bottom: 2),
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 16),
    );
  }
}

/// Text style of a message bubble.
TextStyle chatBubbleTextStyle({required bool isUser}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: isUser ? Colors.white : AppTheme.textDark,
      height: 1.4,
    );

/// Style of the small line under a bubble (time, "Sending…").
TextStyle chatMetaTextStyle({Color color = AppTheme.textLight}) =>
    GoogleFonts.plusJakartaSans(fontSize: 10, color: color);

/// One message: the patient's on the end side in the primary color, the other
/// side's on the start side in white, with an avatar and the sender's name.
class ChatBubble extends StatelessWidget {
  final bool isUser;

  /// The message itself (usually a Text with [chatBubbleTextStyle]).
  final Widget child;

  /// Shown above a message from the other side.
  final String? senderLabel;

  /// Shown before a message from the other side.
  final Widget? avatar;

  /// Under the bubble: the time, "Sending…", or retry actions.
  final Widget? footer;
  final bool pending;
  final bool failed;

  /// Widest a bubble may be (default: 70% of the screen).
  final double? maxWidth;

  /// Padding inside the bubble.
  final EdgeInsetsGeometry padding;

  const ChatBubble({
    required this.isUser,
    required this.child,
    this.senderLabel,
    this.avatar,
    this.footer,
    this.pending = false,
    this.failed = false,
    this.maxWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser && avatar != null) avatar!,
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isUser && senderLabel != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 4,
                      bottom: 3,
                    ),
                    child: Text(
                      senderLabel!,
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
                    constraints: BoxConstraints(maxWidth: maxWidth ?? 70.w),
                    padding: padding,
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primary : AppTheme.surfaceLight,
                      // The small corner points at the sender's side (mirrored
                      // in right-to-left languages).
                      borderRadius: BorderRadiusDirectional.only(
                        topStart: const Radius.circular(16),
                        topEnd: const Radius.circular(16),
                        bottomStart: Radius.circular(isUser ? 16 : 4),
                        bottomEnd: Radius.circular(isUser ? 4 : 16),
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
                    child: child,
                  ),
                ),
                if (footer != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                    child: footer,
                  ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// "Today" / "Yesterday" / a date between two lines.
class ChatDateSeparator extends StatelessWidget {
  final String label;

  const ChatDateSeparator({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: AppTheme.borderColor, thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textLight,
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: AppTheme.borderColor, thickness: 1),
          ),
        ],
      ),
    );
  }
}

/// The message box and the round send button at the bottom of a chat.
/// While [busy], the button becomes a stop button (when [onStop] is set).
/// Bar above the input while a sent message is being edited: "✎ Editing
/// message ✕" (✕ stops editing).
class ChatEditBanner extends StatelessWidget {
  final String label;
  final String cancelLabel;
  final VoidCallback onCancel;

  const ChatEditBanner({
    required this.label,
    required this.cancelLabel,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsetsDirectional.only(start: 14, end: 4),
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_outlined, size: 19, color: AppTheme.textDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.textDark,
              ),
            ),
          ),
          IconButton(
            onPressed: onCancel,
            tooltip: cancelLabel,
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final String hintText;
  final String sendLabel;
  final VoidCallback onSend;
  final int maxLength;

  /// A reply is being written: show a stop button instead of send.
  final bool busy;
  final VoidCallback? onStop;
  final String? stopLabel;

  /// Color of the send button (the Care Team chat uses the primary color).
  final Color sendColor;

  /// Shown above the text box (e.g. the AI chat's "Editing message" bar).
  final Widget? banner;

  const ChatInputBar({
    required this.controller,
    required this.enabled,
    required this.hintText,
    required this.sendLabel,
    required this.onSend,
    this.focusNode,
    this.maxLength = 4000,
    this.busy = false,
    this.onStop,
    this.stopLabel,
    this.sendColor = AppTheme.primary,
    this.banner,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final showStop = busy && onStop != null;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.borderColor, width: 1)),
      ),
      padding: EdgeInsets.only(left: 4.w, right: 4.w, top: 10, bottom: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?banner,
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.borderColor, width: 1),
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    maxLines: 4,
                    minLines: 1,
                    maxLength: maxLength,
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                    textCapitalization: TextCapitalization.sentences,
                    // Tapping anywhere outside the box puts the keyboard away.
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppTheme.textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppTheme.textLight,
                      ),
                      // The rounded box around it is the background; the
                      // theme's square fill would show over its corners.
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (showStop)
                Material(
                  color: AppTheme.surfaceLight,
                  shape: const CircleBorder(
                    side: BorderSide(color: AppTheme.borderColor),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onStop,
                    child: Tooltip(
                      message: stopLabel ?? '',
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.stop_rounded,
                          color: AppTheme.textDark,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                )
              else
                // Part of the text field for tap-outside purposes, so sending
                // keeps the keyboard open for the next message.
                TextFieldTapRegion(
                  child: Material(
                    color: enabled ? sendColor : AppTheme.textLight,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: enabled ? onSend : null,
                      child: Tooltip(
                        message: sendLabel,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A full-area message with an icon, e.g. an error with a Retry button.
class ChatErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final IconData icon;
  final Color iconColor;

  const ChatErrorState({
    required this.message,
    this.onRetry,
    this.retryLabel,
    this.icon = Icons.error_outline_rounded,
    this.iconColor = AppTheme.errorColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 48),
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
              ElevatedButton(onPressed: onRetry, child: Text(retryLabel ?? '')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Both times fall on the same calendar day on this phone (for date separators).
bool chatIsSameDay(DateTime a, DateTime b) {
  final x = a.toLocal();
  final y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day;
}
