import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/rich_html_text.dart';

/// The lesson's written script, edited in the dashboard's rich text editor.
/// Long scripts start collapsed with a "Read more" toggle.
class ScriptSectionWidget extends StatefulWidget {
  final String scriptHtml;

  const ScriptSectionWidget({required this.scriptHtml, super.key});

  @override
  State<ScriptSectionWidget> createState() => _ScriptSectionWidgetState();
}

class _ScriptSectionWidgetState extends State<ScriptSectionWidget> {
  static const double _collapsedHeight = 360;
  bool _expanded = false;

  /// Rough length check so short scripts are never collapsed.
  bool get _isLong =>
      widget.scriptHtml.replaceAll(RegExp(r'<[^>]*>'), '').length > 700;

  @override
  Widget build(BuildContext context) {
    final content = RichHtmlText(html: widget.scriptHtml);
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
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 20,
                color: Color(0xFF15803D),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Lesson Notes',
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLong && !_expanded)
                // Fade the bottom of the collapsed text.
                SizedBox(
                  height: _collapsedHeight,
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.white, Colors.transparent],
                      stops: [0, 0.8, 1],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: content,
                    ),
                  ),
                )
              else
                content,
              if (_isLong)
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    icon: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                    ),
                    label: Text(_expanded ? 'Show less' : 'Read more'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
