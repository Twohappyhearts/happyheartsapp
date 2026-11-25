import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../services/agent_messages.dart';
import '../../../services/app_language.dart';
import '../../../theme/app_theme.dart';
import '../ai_chat_controller.dart';
import '../ai_chat_strings.dart';

/// The patient's past AI conversations: open one, start a new one, delete.
class AiConversationList extends StatelessWidget {
  final AiChatController controller;
  final AiChatStrings strings;

  const AiConversationList({
    required this.controller,
    required this.strings,
    super.key,
  });

  String _titleOf(AgentConversation c) {
    final t = c.title?.trim();
    return t == null || t.isEmpty ? strings.newConversation : t;
  }

  String? _problemText(AiListProblem? p) => switch (p) {
    AiListProblem.listError => strings.listError,
    AiListProblem.openError => strings.openError,
    AiListProblem.deleteError => strings.deleteError,
    AiListProblem.signInAgain => strings.signInAgain,
    null => null,
  };

  /// The hour today, "Yesterday", the weekday this week, else the date.
  String _when(BuildContext context, AgentConversation c) {
    final d = (c.lastMessageAt ?? c.createdAt).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final l10n = context.l10n;
    if (day == today) return l10n.time(d);
    if (day == today.subtract(const Duration(days: 1))) {
      return strings.yesterday;
    }
    if (today.difference(day).inDays < 7) {
      return DateFormat.E(l10n.localeName).format(d);
    }
    return d.year == now.year ? l10n.monthDay(d) : l10n.monthDayYear(d);
  }

  Future<void> _confirmDelete(BuildContext context, AgentConversation c) async {
    final title = _titleOf(c);
    await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _DeleteSheet(
        strings: strings,
        title: title,
        onDelete: () => controller.delete(c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final problem = _problemText(c.listProblem);
    final titleStyle = GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppTheme.textDark,
    );
    return Column(
      children: [
        // Header: back to the chat, title, New.
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceLight,
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: strings.backToChat,
                onPressed: c.showChat,
                icon: const BackButtonIcon(),
                color: AppTheme.textDark,
              ),
              Expanded(
                child: Text(strings.yourConversations, style: titleStyle),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: ElevatedButton.icon(
                  onPressed: c.startNew,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    strings.newChat,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (problem != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    problem,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => c.loadList(),
                  child: Text(
                    strings.retry,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: c.listLoading && c.conversations.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.purple),
                )
              : c.conversations.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      strings.noConversations,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.purple,
                  onRefresh: () => c.loadList(silent: true),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: c.conversations.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppTheme.borderColor),
                    itemBuilder: (context, i) {
                      final conv = c.conversations[i];
                      final active = conv.id == c.conversationId;
                      return Material(
                        color: active
                            ? AppTheme.purpleContainer.withValues(alpha: 0.5)
                            : AppTheme.backgroundLight,
                        child: InkWell(
                          onTap: () => c.open(conv.id),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              16,
                              12,
                              4,
                              12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _titleOf(conv),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: titleStyle,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _when(context, conv),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: AppTheme.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: strings.deleteConversation(
                                    _titleOf(conv),
                                  ),
                                  onPressed: () =>
                                      _confirmDelete(context, conv),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                  color: AppTheme.textLight,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _DeleteSheet extends StatefulWidget {
  final AiChatStrings strings;
  final String title;
  final Future<bool> Function() onDelete;

  const _DeleteSheet({
    required this.strings,
    required this.title,
    required this.onDelete,
  });

  @override
  State<_DeleteSheet> createState() => _DeleteSheetState();
}

class _DeleteSheetState extends State<_DeleteSheet> {
  bool _deleting = false;

  Future<void> _delete() async {
    setState(() => _deleting = true);
    final ok = await widget.onDelete();
    if (mounted) Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.strings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.deleteTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.deleteBody(widget.title),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _deleting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    t.cancel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _deleting ? null : _delete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _deleting ? t.deleting : t.delete,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
