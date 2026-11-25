import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

/// One action in the long-press menu of a message.
class MessageMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const MessageMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// The long-press menu of a message, as in Claude: the screen blurs, the
/// message stays sharp where it is ([preview] drawn over [anchor]), and a
/// card with the actions opens under it (above it when there is no room).
Future<void> showMessageMenu(
  BuildContext context, {
  required Rect anchor,
  required Widget preview,
  required List<MessageMenuItem> items,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, _, _) =>
        _MessageMenu(anchor: anchor, preview: preview, items: items),
    transitionBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

class _MessageMenu extends StatelessWidget {
  final Rect anchor;
  final Widget preview;
  final List<MessageMenuItem> items;

  const _MessageMenu({
    required this.anchor,
    required this.preview,
    required this.items,
  });

  static const double _width = 230;
  static const double _rowHeight = 52;
  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final menuHeight = items.length * _rowHeight + 12;
    final top = media.padding.top + 8;
    final bottom = screen.height - media.padding.bottom - 8;

    // Under the message if it fits, else above it; always on screen.
    var menuTop = anchor.bottom + _gap;
    if (menuTop + menuHeight > bottom) menuTop = anchor.top - _gap - menuHeight;
    menuTop = menuTop.clamp(top, math.max(top, bottom - menuHeight)).toDouble();
    final menuLeft = (anchor.right - _width)
        .clamp(16.0, math.max(16.0, screen.width - _width - 16))
        .toDouble();

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withValues(alpha: 0.08)),
            ),
          ),
        ),
        Positioned(
          left: anchor.left,
          top: anchor.top,
          width: anchor.width,
          // The dialog route has no Material of its own, and the bubble
          // may hold ink buttons (the version switcher) and plain Text.
          child: IgnorePointer(
            child: Material(type: MaterialType.transparency, child: preview),
          ),
        ),
        Positioned(
          left: menuLeft,
          top: menuTop,
          width: _width,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(
                parent: ModalRoute.of(context)!.animation!,
                curve: Curves.easeOutBack,
              ),
            ),
            alignment: Alignment.topRight,
            child: Material(
              color: AppTheme.surfaceLight.withValues(alpha: 0.96),
              elevation: 0,
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final item in items)
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          item.onTap();
                        },
                        child: SizedBox(
                          height: _rowHeight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 21,
                                  color: AppTheme.textDark,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
