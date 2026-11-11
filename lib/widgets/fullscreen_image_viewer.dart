import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_language.dart';

/// Shows [imageUrl] full screen above the whole app (including the bottom
/// bar). The app is portrait-only; landscape is allowed while it is open so
/// wide images can use it. Returns when the viewer closes.
///
/// A dialog route is not opaque, so the lesson page underneath stays
/// "current" for the visit tracker while the viewer is open.
Future<void> showFullscreenImage(
  BuildContext context, {
  required String imageUrl,
  required String title,
  VoidCallback? onInteraction,
}) async {
  SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  try {
    await showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, __) => FullscreenImageViewer(
        imageUrl: imageUrl,
        title: title,
        onInteraction: onInteraction,
      ),
      transitionBuilder: (ctx, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  } finally {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
}

/// Full-screen image (infographics, lesson materials): fit to screen, pinch to zoom (up to 5x), drag to
/// pan, double-tap to zoom in / reset.
class FullscreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String title;
  final VoidCallback? onInteraction;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.title,
    this.onInteraction,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer>
    with SingleTickerProviderStateMixin {
  static const double _maxScale = 5;
  static const double _doubleTapScale = 2.5;

  final TransformationController _transform = TransformationController();
  late final AnimationController _anim =
      AnimationController(
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
    _zoomAnimation = Matrix4Tween(
      begin: _transform.value,
      end: target,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
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
                      errorWidget: (_, __, ___) => Center(
                        child: Text(
                          context.l10n.imageLoadFailed,
                          style: const TextStyle(color: Colors.white70),
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
                padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 0),
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
                      label: context.l10n.imageCloseFullscreen,
                      button: true,
                      child: Material(
                        color: Colors.black.withAlpha(140),
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Hint
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: SafeArea(
                top: false,
                child: Center(
                  child: Text(
                    context.l10n.imageZoomHint,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
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
