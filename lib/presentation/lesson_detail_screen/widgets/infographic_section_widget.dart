
import '../../../core/app_export.dart';

class InfographicSectionWidget extends StatefulWidget {
  final String infographicUrl;
  final String moduleTitle;

  const InfographicSectionWidget({
    required this.infographicUrl,
    required this.moduleTitle,
    super.key,
  });

  @override
  State<InfographicSectionWidget> createState() =>
      _InfographicSectionWidgetState();
}

class _InfographicSectionWidgetState extends State<InfographicSectionWidget> {
  bool _isFullscreen = false;

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
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
            const Text(
              'Infographic',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
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
                      height: _isFullscreen ? null : 320,
                      fit: BoxFit.fitWidth,
                      semanticLabel:
                          'Educational infographic for ${widget.moduleTitle} showing visual health information and key facts',
                    ),
                    // Fullscreen toggle
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _toggleFullscreen,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(153),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _isFullscreen
                                ? Icons.fullscreen_exit_rounded
                                : Icons.fullscreen_rounded,
                            color: Colors.white,
                            size: 20,
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
                          const Text(
                            'Lesson Infographic',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            'Visual summary of ${widget.moduleTitle}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMedium,
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
