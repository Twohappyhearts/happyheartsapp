import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum BadgeStatus {
  available,
  inProgress,
  completed,
  weekly,
  monthly,
  daily,
  asNeeded,
}

class StatusBadgeWidget extends StatelessWidget {
  final BadgeStatus status;
  final String? customLabel;

  const StatusBadgeWidget({required this.status, this.customLabel, super.key});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData? icon;

    switch (status) {
      case BadgeStatus.available:
        bg = AppTheme.secondaryContainer;
        fg = const Color(0xFF14532D);
        label = customLabel ?? 'Available';
        icon = Icons.circle;
        break;
      case BadgeStatus.inProgress:
        bg = AppTheme.primaryContainer;
        fg = AppTheme.primaryDark;
        label = customLabel ?? 'In Progress';
        icon = Icons.circle;
        break;
      case BadgeStatus.completed:
        bg = AppTheme.secondaryContainer;
        fg = const Color(0xFF14532D);
        label = customLabel ?? 'Completed';
        icon = Icons.check_circle;
        break;
      case BadgeStatus.weekly:
        bg = AppTheme.primaryContainer;
        fg = AppTheme.primaryDark;
        label = customLabel ?? 'Weekly';
        break;
      case BadgeStatus.monthly:
        bg = AppTheme.purpleContainer;
        fg = AppTheme.purple;
        label = customLabel ?? 'Monthly';
        break;
      case BadgeStatus.daily:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        label = customLabel ?? 'Daily';
        break;
      case BadgeStatus.asNeeded:
        bg = const Color(0xFFF1F5F9);
        fg = AppTheme.textMedium;
        label = customLabel ?? 'As Needed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 8, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
