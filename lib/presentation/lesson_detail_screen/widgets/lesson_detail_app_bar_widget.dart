import 'package:flutter/material.dart';
import '../../../services/app_language.dart';
import '../../../theme/app_theme.dart';

class LessonDetailAppBarWidget extends StatelessWidget {
  final VoidCallback onBack;

  const LessonDetailAppBarWidget({required this.onBack, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          // Back button
          Semantics(
            button: true,
            label: context.l10n.back,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ),

          // Centered title
          Expanded(
            child: Center(
              child: Text(
                context.l10n.lessonHeader,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ),

          // Keeps the title centred (same width as the back button).
          // Share and bookmark were removed: neither did anything (11-14 test).
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
