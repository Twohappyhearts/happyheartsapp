import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/app_language.dart';
import '../../../services/content_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/fullscreen_image_viewer.dart';

/// Files staff uploaded for the lesson on the dashboard: images as
/// thumbnails (tap for full screen with zoom), PDFs as rows that open in an
/// in-app browser. The lesson page leaves this out when there are none.
class MaterialsSectionWidget extends StatelessWidget {
  final List<LessonAttachment> attachments;

  /// Touches in the full-screen viewer (keeps the lesson visit "active").
  final VoidCallback? onInteraction;

  const MaterialsSectionWidget({
    required this.attachments,
    this.onInteraction,
    super.key,
  });

  static String fileSize(AppLocalizations l10n, int bytes) {
    final number = NumberFormat.decimalPatternDigits(
      locale: l10n.localeName,
      decimalDigits: 1,
    );
    if (bytes >= 1024 * 1024) {
      return l10n.fileSizeMb(number.format(bytes / (1024 * 1024)));
    }
    return l10n.fileSizeKb(
      NumberFormat.decimalPattern(
        l10n.localeName,
      ).format((bytes / 1024).ceil()),
    );
  }

  Future<void> _openPdf(BuildContext context, LessonAttachment pdf) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.couldNotOpenLink;
    final uri = Uri.tryParse(pdf.url);
    var opened = false;
    if (uri != null && uri.scheme == 'https') {
      for (final mode in [
        LaunchMode.inAppBrowserView,
        LaunchMode.externalApplication,
      ]) {
        try {
          opened = await launchUrl(uri, mode: mode);
        } catch (_) {
          opened = false;
        }
        if (opened) break;
      }
    }
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(content: Text(failed), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final images = attachments.where((a) => a.isImage).toList();
    final pdfs = attachments.where((a) => a.isPdf).toList();
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
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 20,
                color: Color(0xFF0369A1),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                l10n.materialsTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (images.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final width = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final image in images)
                    SizedBox(
                      width: width,
                      child: _ImageTile(
                        image: image,
                        onTap: () => showFullscreenImage(
                          context,
                          imageUrl: image.url,
                          title: image.name,
                          onInteraction: onInteraction,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        if (images.isNotEmpty && pdfs.isNotEmpty) const SizedBox(height: 12),
        if (pdfs.isNotEmpty)
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
                  for (var i = 0; i < pdfs.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppTheme.borderColor,
                      ),
                    _pdfRow(context, l10n, pdfs[i]),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _pdfRow(
    BuildContext context,
    AppLocalizations l10n,
    LessonAttachment pdf,
  ) {
    final size = pdf.sizeBytes;
    return Semantics(
      button: true,
      label: l10n.materialsOpenPdf(pdf.name),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => _openPdf(context, pdf),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.picture_as_pdf_rounded,
                size: 24,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdf.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      size == null || size <= 0
                          ? l10n.materialsPdf
                          : l10n.materialsPdfSize(fileSize(l10n, size)),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textMedium,
                      ),
                    ),
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

class _ImageTile extends StatelessWidget {
  final LessonAttachment image;
  final VoidCallback onTap;

  const _ImageTile({required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.materialsOpenImage(image.name),
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    IgnorePointer(
                      child: CustomImageWidget(
                        imageUrl: image.url,
                        fit: BoxFit.cover,
                        semanticLabel: image.name,
                      ),
                    ),
                    PositionedDirectional(
                      bottom: 6,
                      end: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(140),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.fullscreen_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Text(
                  image.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
