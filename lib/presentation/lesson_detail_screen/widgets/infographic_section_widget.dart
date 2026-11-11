import 'package:flutter/services.dart';

import '../../../core/app_export.dart';

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

  /// Opens a real full-screen viewer (black background, pinch / double-tap to
  /// zoom, rotation allowed) above the whole app, including the bottom bar.
  Future<void> _openFullscreen() async {
    if (_isFullscreen) return;
    setState(() => _isFullscreen = true);
    widget.onFullscreenChanged?.call(true);
    // The app is portrait-only; let wide infographics use landscape here.
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    try {
      // A dialog route is not opaque, so the lesson page underneath stays
      // "current" for the visit tracker while the viewer is open.
      await showGeneralDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (ctx, _, __) => _InfographicViewer(
          imageUrl: widget.infographicUrl,
          title: widget.moduleTitle,
          onInteraction: widget.onInteraction,
        ),
        transitionBuilder: (ctx, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      );
    } finally {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
                'Infographic',
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
                      semanticLabel:
                          'Educational infographic for ${widget.moduleTitle} showing visual health information and key facts',
                    ),
                    // Fullscreen toggle
                    Positioned(
                      bottom: 8,
                      right: 8,
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
                          const SizedBox(height: 2),
                          const Text(
                            'Tap the image to view full screen and zoom',
                            style: TextStyle(
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

/// Full-screen infographic: fit to screen, pinch to zoom (up to 5x), drag to
/// pan, double-tap to zoom in / reset.
class _InfographicViewer extends StatefulWidget {
  final String imageUrl;
  final String title;
  final VoidCallback? onInteraction;

  const _InfographicViewer({
    required this.imageUrl,
    required this.title,
    this.onInteraction,
  });

  @override
  State<_InfographicViewer> createState() => _InfographicViewerState();
}

class _InfographicViewerState extends State<_InfographicViewer>
    with SingleTickerProviderStateMixin {
  static const double _maxScale = 5;
  static const double _doubleTapScale = 2.5;

  final TransformationController _transform = TransformationController();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(() {
      final a = _zoomAnimation;
      if (a != null) _transform.value = a.value;
    });
  Animation<Matrix4>? _zoomAnimation;
  Offset _doubleTapPosition = Offset.zero;

  @override
  void dispose() {
    _anim.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _animateTo(Matrix4 target) {
    _zoomAnimation = Matrix4Tween(begin: _transform.value, end: target)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward(from: 0);
  }

  void _onDoubleTap() {
    widget.onInteraction?.call();
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed) {
      _animateTo(Matrix4.identity());
    } else {
      // Zoom in around the tapped point.
      final p = _doubleTapPosition;
      _animateTo(
        Matrix4.diagonal3Values(_doubleTapScale, _doubleTapScale, 1)
          ..setTranslationRaw(
            -p.dx * (_doubleTapScale - 1),
            -p.dy * (_doubleTapScale - 1),
            0,
          ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => widget.onInteraction?.call(),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onDoubleTapDown: (d) => _doubleTapPosition = d.localPosition,
                onDoubleTap: _onDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transform,
                  minScale: 1,
                  maxScale: _maxScale,
                  clipBehavior: Clip.none,
                  child: SizedBox.expand(
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (_, __, ___) => const Center(
                        child: Text(
                          'Could not load the infographic.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Top bar: title + close
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'Close full screen infographic',
                      button: true,
                      child: Material(
                        color: Colors.black.withAlpha(140),
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Hint
            const Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: SafeArea(
                top: false,
                child: Center(
                  child: Text(
                    'Pinch or double-tap to zoom',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
