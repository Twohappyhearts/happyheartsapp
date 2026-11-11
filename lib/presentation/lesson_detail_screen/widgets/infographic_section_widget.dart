import '../../../core/app_export.dart';
import '../../../services/app_language.dart';
import '../../../widgets/fullscreen_image_viewer.dart';

class InfographicSectionWidget extends StatefulWidget {
  final String infographicUrl;
  final String moduleTitle;

  /// Called when the full-screen view opens (true) or closes (false).
  final ValueChanged<bool>? onFullscreenChanged;

  /// Touches / zooms inside the full-screen viewer (keeps the visit "active").
  final VoidCallback? onInteraction;

  const InfographicSectionWidget({
    required this.infographicUrl,
    required this.moduleTitle,
    this.onFullscreenChanged,
    this.onInteraction,
    super.key,
  });

  @override
  State<InfographicSectionWidget> createState() =>
      _InfographicSectionWidgetState();
}

class _InfographicSectionWidgetState extends State<InfographicSectionWidget> {
  bool _isFullscreen = false;

  /// Opens the full-screen viewer (black background, pinch / double-tap to
  /// zoom, rotation allowed) above the whole app, including the bottom bar.
  Future<void> _openFullscreen() async {
    if (_isFullscreen) return;
    setState(() => _isFullscreen = true);
    widget.onFullscreenChanged?.call(true);
    try {
      await showFullscreenImage(
        context,
        imageUrl: widget.infographicUrl,
        title: widget.moduleTitle,
        onInteraction: widget.onInteraction,
      );
    } finally {
      if (mounted) setState(() => _isFullscreen = false);
      widget.onFullscreenChanged?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                size: 20,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                context.l10n.infoTitle,
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

        // Infographic card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    CustomImageWidget(
                      imageUrl: widget.infographicUrl,
                      width: double.infinity,
                      height: 320,
                      fit: BoxFit.fitWidth,
                      onTap: _openFullscreen,
                      semanticLabel: context.l10n.infoSemantic(
                        widget.moduleTitle,
                      ),
                    ),
                    // Fullscreen toggle
                    PositionedDirectional(
                      bottom: 8,
                      end: 8,
                      child: Semantics(
                        button: true,
                        label: context.l10n.imageOpenFullscreen,
                        child: GestureDetector(
                          onTap: _openFullscreen,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(153),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Label below image
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.image_rounded,
                      size: 16,
                      color: AppTheme.textLight,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.infoCardTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            context.l10n.infoCardSubtitle(widget.moduleTitle),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMedium,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.infoTapHint,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
