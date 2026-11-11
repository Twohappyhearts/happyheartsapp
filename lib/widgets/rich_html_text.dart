import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:url_launcher/url_launcher.dart';

import '../services/app_language.dart';
import '../theme/app_theme.dart';

/// Renders the limited rich text produced by the dashboard's script editor
/// (Tiptap): paragraphs, line breaks, bold, italic, underline, strikethrough,
/// text color, bulleted / numbered lists (nested) and links.
///
/// Anything else is shown as plain text — no scripts, images or embedded
/// content are ever executed or loaded. Links only open for https, http,
/// mailto and tel, in the phone's browser / dialer.
class RichHtmlText extends StatefulWidget {
  final String html;
  final TextStyle? baseStyle;

  const RichHtmlText({required this.html, this.baseStyle, super.key});

  @override
  State<RichHtmlText> createState() => _RichHtmlTextState();
}

class _RichHtmlTextState extends State<RichHtmlText> {
  // Link tap recognizers must be disposed; rebuilt on every build.
  final List<TapGestureRecognizer> _recognizers = [];

  static final RegExp _safeLink = RegExp(
    r'^(https?://|mailto:|tel:)',
    caseSensitive: false,
  );

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final base =
        widget.baseStyle ??
        const TextStyle(fontSize: 15, height: 1.6, color: AppTheme.textDark);
    final fragment = html_parser.parseFragment(widget.html);
    final blocks = _blocks(fragment.nodes, base, 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  // ---- Blocks -----------------------------------------------------------------

  List<Widget> _blocks(List<dom.Node> nodes, TextStyle style, int depth) {
    final out = <Widget>[];
    final pendingInline = <dom.Node>[];

    void flushInline() {
      if (pendingInline.isEmpty) return;
      final spans = _inline(List.of(pendingInline), style);
      pendingInline.clear();
      if (_hasVisibleText(spans)) out.add(_paragraph(spans, style));
    }

    for (final node in nodes) {
      if (node is dom.Element) {
        final tag = node.localName;
        switch (tag) {
          case 'p':
          case 'div':
            flushInline();
            final spans = _inline(node.nodes, style);
            out.add(
              _hasVisibleText(spans)
                  ? _paragraph(spans, style)
                  : const SizedBox(height: 8), // empty line
            );
            break;
          case 'ul':
          case 'ol':
            flushInline();
            out.add(_list(node, ordered: tag == 'ol', style: style, depth: depth));
            break;
          case 'li':
            // A stray <li> outside a list: treat like a paragraph.
            flushInline();
            out.addAll(_blocks(node.nodes, style, depth));
            break;
          default:
            pendingInline.add(node);
        }
      } else {
        pendingInline.add(node);
      }
    }
    flushInline();
    return out;
  }

  Widget _paragraph(List<InlineSpan> spans, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(TextSpan(style: style, children: spans)),
    );
  }

  Widget _list(
    dom.Element list, {
    required bool ordered,
    required TextStyle style,
    required int depth,
  }) {
    final items = list.children.where((e) => e.localName == 'li').toList();
    final start = int.tryParse(list.attributes['start'] ?? '') ?? 1;
    return Padding(
      padding: EdgeInsets.only(bottom: depth == 0 ? 10 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: ordered ? 28 : 20,
                    child: Text(
                      ordered
                          ? '${start + i}.'
                          : (depth.isEven ? '•' : '◦'),
                      style: style.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _trimLastPadding(
                        _blocks(items[i].nodes, style, depth + 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Paragraphs inside a list item shouldn't add a gap after the last line.
  List<Widget> _trimLastPadding(List<Widget> blocks) {
    if (blocks.isEmpty) return blocks;
    final last = blocks.last;
    if (last is Padding && last.child is Text) {
      return [...blocks.sublist(0, blocks.length - 1), last.child!];
    }
    return blocks;
  }

  // ---- Inline -------------------------------------------------------------------

  List<InlineSpan> _inline(List<dom.Node> nodes, TextStyle style) {
    final spans = <InlineSpan>[];
    for (final node in nodes) {
      if (node is dom.Text) {
        final text = node.text.replaceAll(RegExp(r'\s+'), ' ');
        if (text.isNotEmpty) spans.add(TextSpan(text: text, style: style));
      } else if (node is dom.Element) {
        switch (node.localName) {
          case 'br':
            spans.add(TextSpan(text: '\n', style: style));
            break;
          case 'strong':
          case 'b':
            spans.addAll(
              _inline(node.nodes, style.copyWith(fontWeight: FontWeight.w700)),
            );
            break;
          case 'em':
          case 'i':
            spans.addAll(
              _inline(node.nodes, style.copyWith(fontStyle: FontStyle.italic)),
            );
            break;
          case 'u':
            spans.addAll(
              _inline(node.nodes, _addDecoration(style, TextDecoration.underline)),
            );
            break;
          case 's':
          case 'strike':
          case 'del':
            spans.addAll(
              _inline(
                node.nodes,
                _addDecoration(style, TextDecoration.lineThrough),
              ),
            );
            break;
          case 'span':
            final color = _cssColor(node.attributes['style']);
            spans.addAll(
              _inline(
                node.nodes,
                color == null
                    ? style
                    : style.copyWith(color: color, decorationColor: color),
              ),
            );
            break;
          case 'a':
            spans.addAll(_link(node, style));
            break;
          case 'p':
          case 'div':
          case 'li':
            // Block inside inline content: keep its text, on its own line.
            if (spans.isNotEmpty) spans.add(TextSpan(text: '\n', style: style));
            spans.addAll(_inline(node.nodes, style));
            break;
          default:
            // Unknown tag: show its text only.
            spans.addAll(_inline(node.nodes, style));
        }
      }
    }
    return spans;
  }

  List<InlineSpan> _link(dom.Element a, TextStyle style) {
    final href = (a.attributes['href'] ?? '').trim();
    final linkStyle = _addDecoration(
      style.copyWith(color: AppTheme.primary, decorationColor: AppTheme.primary),
      TextDecoration.underline,
    );
    if (!_safeLink.hasMatch(href)) {
      return _inline(a.nodes, style); // not a safe link: plain text
    }
    final recognizer = TapGestureRecognizer()
      ..onTap = () {
        final uri = Uri.tryParse(href);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      };
    _recognizers.add(recognizer);
    // Children are flattened so the whole link text shares one recognizer.
    final text = a.text.replaceAll(RegExp(r'\s+'), ' ');
    return [
      TextSpan(
        text: text.isEmpty ? href : text,
        style: linkStyle,
        recognizer: recognizer,
        semanticsLabel: appL10n.linkSemantic(text.isEmpty ? href : text),
      ),
    ];
  }

  // ---- Helpers --------------------------------------------------------------------

  static TextStyle _addDecoration(TextStyle style, TextDecoration d) {
    final current = style.decoration;
    return style.copyWith(
      decoration: current == null || current == TextDecoration.none
          ? d
          : TextDecoration.combine([current, d]),
    );
  }

  static bool _hasVisibleText(List<InlineSpan> spans) =>
      spans.any((s) => s is TextSpan && (s.text ?? '').trim().isNotEmpty);

  /// Reads `color: #rrggbb`, `#rgb` or `rgb(r, g, b)` from a style attribute.
  static Color? _cssColor(String? style) {
    if (style == null) return null;
    final m = RegExp(r'(?:^|;)\s*color\s*:\s*([^;]+)', caseSensitive: false)
        .firstMatch(style);
    if (m == null) return null;
    final v = m.group(1)!.trim().toLowerCase();
    if (v.startsWith('#')) {
      var hex = v.substring(1);
      if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
      if (hex.length != 6) return null;
      final n = int.tryParse(hex, radix: 16);
      return n == null ? null : Color(0xFF000000 | n);
    }
    final rgb = RegExp(r'rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)').firstMatch(v);
    if (rgb != null) {
      int c(int i) => (int.tryParse(rgb.group(i)!) ?? 0).clamp(0, 255).toInt();
      return Color.fromARGB(255, c(1), c(2), c(3));
    }
    return null;
  }
}
