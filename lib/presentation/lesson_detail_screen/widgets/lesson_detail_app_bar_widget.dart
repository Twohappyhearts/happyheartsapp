import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class LessonDetailAppBarWidget extends StatelessWidget {
  final bool isBookmarked;
  final VoidCallback onBack;
  final VoidCallback onBookmark;
  final VoidCallback onShare;

  const LessonDetailAppBarWidget({
    required this.isBookmarked,
    required this.onBack,
    required this.onBookmark,
    required this.onShare,
    super.key,
  });

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
          InkWell(
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

          // Centered title
          const Expanded(
            child: Center(
              child: Text(
                'Lesson',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ),

          // Share
          InkWell(
            onTap: onShare,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.ios_share_rounded,
                size: 18,
                color: AppTheme.textDark,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Bookmark
          InkWell(
            onTap: onBookmark,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isBookmarked
                    ? AppTheme.primaryContainer
                    : AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                size: 18,
                color: isBookmarked ? AppTheme.primary : AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
