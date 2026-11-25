import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_language.dart';
import '../../services/inbox_service.dart';
import '../../theme/app_theme.dart';
import 'inbox_strings.dart';

/// Opens the broadcast inbox.
Future<void> openInbox(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const InboxScreen()));
}

/// Broadcast messages from the research team. Opening it marks them as read;
/// the ones that were unread keep a "NEW" mark until the screen is closed.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _inbox = InboxService.instance;
  List<InboxItem>? _items;
  bool _failed = false;
  bool _loading = false;
  int _seenVersion = -1;

  /// Unread when they were first shown.
  final Set<String> _fresh = {};

  @override
  void initState() {
    super.initState();
    _seenVersion = _inbox.version;
    _inbox.addListener(_onInbox);
    _load();
  }

  @override
  void dispose() {
    _inbox.removeListener(_onInbox);
    super.dispose();
  }

  void _onInbox() {
    // A broadcast arrived (or the app came back): show it.
    if (_inbox.version != _seenVersion) {
      _seenVersion = _inbox.version;
      _load();
    }
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final items = await _inbox.fetch();
      if (!mounted) return;
      final unread = [
        for (final m in items)
          if (m.unread) m.id,
      ];
      setState(() {
        _items = items;
        _failed = false;
        _fresh.addAll(unread);
      });
      if (unread.isNotEmpty) await _inbox.markReadUntil(items.first.createdAt);
    } on InboxException {
      if (!mounted) return;
      setState(() => _failed = true);
      if (_items != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(_strings.loadFailed),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InboxStrings get _strings =>
      InboxStrings.of(AppLanguageController.instance.code);

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          _strings.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: items == null
            ? _buildPlaceholder()
            : items.isEmpty
            ? _buildEmpty()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _MessageCard(
                  item: items[i],
                  isNew: _fresh.contains(items[i].id),
                  newBadge: _strings.newBadge,
                ),
              ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    // Scrollable so pull-to-refresh works in every state.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 360,
          child: Center(
            child: !_failed
                ? const CircularProgressIndicator(color: AppTheme.primary)
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppTheme.errorColor,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _strings.loadFailed,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          child: Text(context.l10n.retry),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        const SizedBox(height: 96),
        const Icon(Icons.inbox_outlined, color: AppTheme.textLight, size: 48),
        const SizedBox(height: 12),
        Text(
          _strings.emptyTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _strings.emptyBody,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.45,
            color: AppTheme.textMedium,
          ),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  final InboxItem item;
  final bool isNew;
  final String newBadge;

  const _MessageCard({
    required this.item,
    required this.isNew,
    required this.newBadge,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final team = l10n.chatTeamTitle;
    final sender = item.senderName == null
        ? team
        : '${item.senderName} · $team';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFFEFF6FF) : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNew ? const Color(0xFFBFDBFE) : AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.campaign_outlined,
                  size: 18,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sender,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      l10n.relativeDateTime(item.createdAt),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (isNew)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    newBadge,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            item.content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              height: 1.5,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
