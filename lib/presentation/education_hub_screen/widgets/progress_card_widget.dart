import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/app_language.dart';
import '../../../theme/app_theme.dart';

class ProgressCardWidget extends StatelessWidget {
  final int completed;
  final int total;

  /// Opens the Progress tab.
  final VoidCallback? onTap;

  const ProgressCardWidget({
    required this.completed,
    required this.total,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? completed / total : 0.0;
    final percentInt = (percent * 100).round();

    final l10n = context.l10n;
    String motivationalText;
    String emoji;
    if (percentInt == 0) {
      motivationalText = l10n.progressCardStart;
      emoji = '🚀';
    } else if (percentInt < 50) {
      motivationalText = l10n.progressCardGreat(percentInt);
      emoji = '💪';
    } else if (percentInt < 100) {
      motivationalText = l10n.progressCardKeepGoing(percentInt);
      emoji = '🎯';
    } else {
      motivationalText = l10n.progressCardDone;
      emoji = '🏆';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: _buildCard(l10n, percent, motivationalText, emoji),
      ),
    );
  }

  Widget _buildCard(
    AppLocalizations l10n,
    double percent,
    String motivationalText,
    String emoji,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(77),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.progressCardTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.progressCardLessons(completed, total),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.white.withAlpha(64),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        motivationalText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(emoji, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}
