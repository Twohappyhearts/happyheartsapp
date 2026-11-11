import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';

/// The lesson's sources, at the end of the lesson: its video and audio, the
/// links in the lesson notes, and the links staff added in the dashboard
/// (built by ContentService). Each one opens in the phone's browser.
class ReferencesSectionWidget extends StatelessWidget {
  /// `{title, url}`; the title may be empty (the site name is shown instead).
  final List<Map<String, String>> references;

  const ReferencesSectionWidget({required this.references, super.key});

  static String _host(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  static IconData _icon(String title) => switch (title) {
    'Lesson video' => Icons.play_circle_outline_rounded,
    'Lesson audio' => Icons.headphones_rounded,
    _ => Icons.link_rounded,
  };

  Future<void> _open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    var opened = false;
    if (uri != null && uri.scheme == 'https') {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not open this link.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header (same style as the other lesson sections)
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.library_books_rounded,
                size: 20,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'References',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < references.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppTheme.borderColor,
                    ),
                  _row(context, references[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, Map<String, String> reference) {
    final url = reference['url'] ?? '';
    final host = _host(url);
    final rawTitle = (reference['title'] ?? '').trim();
    final title = rawTitle.isEmpty ? (host.isEmpty ? url : host) : rawTitle;
    return Semantics(
      link: true,
      child: InkWell(
        onTap: () => _open(context, url),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(_icon(rawTitle), size: 22, color: AppTheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                        height: 1.3,
                      ),
                    ),
                    if (host.isNotEmpty && host != title) ...[
                      const SizedBox(height: 2),
                      Text(
                        host,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: AppTheme.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
