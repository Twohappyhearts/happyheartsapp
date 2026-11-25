import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../agent_reply.dart';

/// The Markdown the assistant writes (paragraphs, line breaks, **bold**,
/// *italic*, `code`, headings, bullet and numbered lists, links), rendered
/// as Flutter text. Same rules as the web chat (markdown-it there):
///   - phone numbers become tap-to-call links (US numbers, 911, 988, 211,
///     also in Persian / Arabic-Indic digits);
///   - web links stay tappable only when they point to a host from this
///     answer's own search results ([linkableHosts]); others show as text;
///   - nothing is ever rendered as HTML.
class AiMarkdown extends StatefulWidget {
  final String text;
  final List<String> linkableHosts;
  final TextStyle style;
  final void Function(Uri uri) onOpenLink;

  const AiMarkdown({
    required this.text,
    required this.linkableHosts,
    required this.style,
    required this.onOpenLink,
    super.key,
  });

  @override
  State<AiMarkdown> createState() => _AiMarkdownState();
}

class _AiMarkdownState extends State<AiMarkdown> {
  List<_Block> _blocks = const [];
  List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  void didUpdateWidget(AiMarkdown old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text ||
        old.linkableHosts.join(',') != widget.linkableHosts.join(',')) {
      _parse();
    }
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  void _parse() => _blocks = _parseBlocks(widget.text);

  @override
  Widget build(BuildContext context) {
    // Links get new tap recognizers on every build; the previous ones are
    // disposed once the new text is on screen.
    final old = _recognizers;
    _recognizers = [];
    if (old.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final r in old) {
          r.dispose();
        }
      });
    }
    final children = <Widget>[];
    for (final block in _blocks) {
      if (children.isNotEmpty) {
        children.add(SizedBox(height: block.kind == _Kind.item ? 3 : 6));
      }
      children.add(_buildBlock(block));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildBlock(_Block block) {
    final base = widget.style;
    switch (block.kind) {
      case _Kind.rule:
        return const Divider(height: 8, color: AppTheme.borderColor);
      case _Kind.heading:
        return _rich(
          block.text,
          base.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: (base.fontSize ?? 14) + (block.level <= 2 ? 2 : 1),
          ),
        );
      case _Kind.paragraph:
        return _rich(block.text, base);
      case _Kind.item:
        return Padding(
          padding: EdgeInsetsDirectional.only(start: 4.0 + 14.0 * block.level),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: block.number != null ? 22 : 14,
                child: Text(
                  block.number != null ? '${block.number}.' : '•',
                  style: base,
                ),
              ),
              Expanded(child: _rich(block.text, base)),
            ],
          ),
        );
    }
  }

  Widget _rich(String text, TextStyle style) {
    return Text.rich(
      TextSpan(style: style, children: _inline(text, style)),
      textDirection: _directionOf(text),
    );
  }

  /// The text's own direction (e.g. a Farsi answer while the app is in English).
  TextDirection? _directionOf(String text) {
    for (final rune in text.runes) {
      if (_isRtl(rune)) return TextDirection.rtl;
      if (_isStrongLtr(rune)) return TextDirection.ltr;
    }
    return null;
  }

  static bool _isRtl(int c) =>
      (c >= 0x0590 && c <= 0x08FF) ||
      (c >= 0xFB1D && c <= 0xFDFF) ||
      (c >= 0xFE70 && c <= 0xFEFF);

  static bool _isStrongLtr(int c) =>
      (c >= 0x41 && c <= 0x5A) ||
      (c >= 0x61 && c <= 0x7A) ||
      (c >= 0xC0 && c < 0x0590) ||
      c >= 0x1100;

  // ---------------------------------------------------------------- inline

  List<InlineSpan> _inline(String text, TextStyle style) {
    final spans = <InlineSpan>[];
    for (final seg in _InlineParser(text).parse()) {
      var s = style;
      if (seg.bold) s = s.copyWith(fontWeight: FontWeight.w700);
      if (seg.italic) s = s.copyWith(fontStyle: FontStyle.italic);
      if (seg.code) {
        s = s.copyWith(
          fontFamily: 'monospace',
          backgroundColor: AppTheme.surfaceVariantLight,
        );
      }
      if (seg.href != null) {
        _addLink(spans, seg.text, seg.href!, s);
      } else if (seg.code) {
        spans.add(TextSpan(text: seg.text, style: s));
      } else {
        _addAutoLinks(spans, seg.text, s);
      }
    }
    return spans;
  }

  /// A link written as [text](url): tappable when allowed, else its text.
  void _addLink(
    List<InlineSpan> spans,
    String text,
    String href,
    TextStyle style,
  ) {
    final uri = Uri.tryParse(href.trim());
    final scheme = uri?.scheme.toLowerCase() ?? '';
    final allowed =
        uri != null &&
        ((scheme == 'http' || scheme == 'https')
            ? hostAllowed(href, widget.linkableHosts)
            : (scheme == 'tel' || scheme == 'mailto'));
    if (!allowed) {
      _addAutoLinks(spans, text, style);
      return;
    }
    spans.add(_linkSpan(text, uri, style));
  }

  TextSpan _linkSpan(String text, Uri uri, TextStyle style) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () => widget.onOpenLink(uri);
    _recognizers.add(recognizer);
    final tel = uri.scheme == 'tel';
    return TextSpan(
      text: text,
      recognizer: recognizer,
      style: style.copyWith(
        color: style.color == Colors.white
            ? Colors.white
            : (tel ? null : AppTheme.primary),
        fontWeight: tel ? FontWeight.w700 : null,
        decoration: TextDecoration.underline,
        decorationColor: style.color == Colors.white
            ? Colors.white
            : (tel ? style.color : AppTheme.primary),
      ),
    );
  }

  /// Plain text: bare web addresses (when allowed) and phone numbers become links.
  void _addAutoLinks(List<InlineSpan> spans, String text, TextStyle style) {
    final found = <(int, int, Uri)>[];
    for (final m in _bareUrl.allMatches(text)) {
      var raw = m[0]!;
      raw = raw.replaceAll(RegExp(r'[.,;:!?)\]]+$'), '');
      final href = raw.toLowerCase().startsWith('www.') ? 'https://$raw' : raw;
      if (!hostAllowed(href, widget.linkableHosts)) continue;
      final uri = Uri.tryParse(href);
      if (uri != null) found.add((m.start, m.start + raw.length, uri));
    }
    for (final m in _phone.allMatches(text)) {
      final start = m.start + m[1]!.length;
      final raw = m[2]!;
      final end = start + raw.length;
      if (found.any((f) => start < f.$2 && end > f.$1)) {
        continue; // inside a web link
      }
      final href = _telHref(raw);
      if (href != null) found.add((start, end, Uri.parse(href)));
    }
    found.sort((a, b) => a.$1.compareTo(b.$1));
    var last = 0;
    for (final (start, end, uri) in found) {
      if (start < last) continue;
      if (start > last) {
        spans.add(TextSpan(text: text.substring(last, start), style: style));
      }
      spans.add(_linkSpan(text.substring(start, end), uri, style));
      last = end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: style));
    }
  }

  /// tel: link of a matched number; null for a 3-digit number that is not 911 / 988 / 211.
  static String? _telHref(String raw) {
    final digits = asciiDigits(raw).replaceAll(RegExp('[^0-9]'), '');
    if (digits.length == 3) {
      return const {'911', '988', '211'}.contains(digits)
          ? 'tel:$digits'
          : null;
    }
    if (digits.length < 10) return null;
    return 'tel:+1${digits.substring(digits.length - 10)}';
  }
}

final RegExp _bareUrl = RegExp(
  r'''(?:https?://|www\.)[^\s<>"'`]+''',
  caseSensitive: false,
);

// Phone numbers, as in the web chat: US numbers (714-479-8868, (714) 479-8868,
// 714.479.8868, 714 479 8868, optionally after "1-" or "+1") and the short
// numbers 911, 988 and 211. Not blood pressure (162/112), dates, ranges, ZIP
// codes, years, or a street number such as "211 W Chestnut Ave".
const String _digit = '0-9۰-۹٠-٩';
const String _d = '[$_digit]';
const String _d29 = '[2-9۲-۹٢-٩]';
const String _one = '[1۱١]';
const String _usNumber =
    '(?:\\+?$_one(?:[-. ]|(?=\\()))?(?:\\($_d29$_d{2}\\) ?|$_d29$_d{2}[-. ])$_d29$_d{2}[-. ]$_d{4}'
    '(?![$_digit\\w]|[-.][$_digit])';
const String _street =
    '\\s+(?:[NSEW]\\.?\\s|[A-Z][a-z]+\\s+(?:St|Ave|Blvd|Rd|Dr|Way|Ln)\\b)';
const String _shortNumber = '$_d{3}(?![$_digit\\w]|[-/.,:][$_digit]|$_street)';
final RegExp _phone = RegExp(
  '(^|[^$_digit\\w#+\\-./,:])($_usNumber|$_shortNumber)',
);

// ---------------------------------------------------------------- blocks

enum _Kind { paragraph, heading, item, rule }

class _Block {
  final _Kind kind;
  String text;
  final int level;
  final int? number;
  _Block(this.kind, this.text, {this.level = 0, this.number});
}

final RegExp _headingRe = RegExp(r'^\s{0,3}(#{1,6})\s+(.*?)\s*#*\s*$');
final RegExp _bulletRe = RegExp(r'^(\s*)[-*+]\s+(.*)$');
final RegExp _orderedRe = RegExp(r'^(\s*)(\d{1,3})[.)]\s+(.*)$');
final RegExp _ruleRe = RegExp(r'^\s{0,3}([-*_])(\s*\1){2,}\s*$');
final RegExp _quoteRe = RegExp(r'^\s{0,3}>\s?(.*)$');

List<_Block> _parseBlocks(String source) {
  final blocks = <_Block>[];
  _Block? open; // paragraph or list item that following lines continue
  for (final raw in source.replaceAll('\r\n', '\n').split('\n')) {
    final line = raw.trimRight();
    if (line.trim().isEmpty) {
      open = null;
      continue;
    }
    if (_ruleRe.hasMatch(line)) {
      blocks.add(_Block(_Kind.rule, ''));
      open = null;
      continue;
    }
    final h = _headingRe.firstMatch(line);
    if (h != null) {
      blocks.add(_Block(_Kind.heading, h[2]!, level: h[1]!.length));
      open = null;
      continue;
    }
    final b = _bulletRe.firstMatch(line);
    final o = b == null ? _orderedRe.firstMatch(line) : null;
    if (b != null || o != null) {
      final indent = (b ?? o)![1]!.replaceAll('\t', '    ').length;
      final item = _Block(
        _Kind.item,
        b != null ? b[2]! : o![3]!,
        level: (indent / 2).floor().clamp(0, 3),
        number: o != null ? int.tryParse(o[2]!) : null,
      );
      blocks.add(item);
      open = item;
      continue;
    }
    final q = _quoteRe.firstMatch(line);
    final text = q != null ? q[1]! : line.trim();
    if (open != null) {
      // breaks: true (as in the web chat): a single newline is a line break.
      open.text = '${open.text}\n$text';
    } else {
      open = _Block(_Kind.paragraph, text);
      blocks.add(open);
    }
  }
  return blocks;
}

// ---------------------------------------------------------------- inline

class _Seg {
  final String text;
  final bool bold;
  final bool italic;
  final bool code;
  final String? href;
  const _Seg(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.code = false,
    this.href,
  });
}

final RegExp _linkRe = RegExp(
  r'\[([^\]\n]+)\]\(\s*<?([^)\s>]+)>?(?:\s+"[^"]*")?\s*\)',
);

/// **bold**, __bold__, *italic*, _italic_, `code` and [text](url).
class _InlineParser {
  final String src;
  _InlineParser(this.src);

  List<_Seg> parse() => _parse(src, bold: false, italic: false);

  List<_Seg> _parse(String s, {required bool bold, required bool italic}) {
    final out = <_Seg>[];
    final buf = StringBuffer();
    void flush() {
      if (buf.isNotEmpty) {
        out.add(_Seg(buf.toString(), bold: bold, italic: italic));
        buf.clear();
      }
    }

    var i = 0;
    while (i < s.length) {
      // `code`
      if (s[i] == '`') {
        final end = s.indexOf('`', i + 1);
        if (end > i + 1) {
          flush();
          out.add(
            _Seg(
              s.substring(i + 1, end),
              bold: bold,
              italic: italic,
              code: true,
            ),
          );
          i = end + 1;
          continue;
        }
      }
      // [text](url)
      if (s[i] == '[') {
        final m = _linkRe.matchAsPrefix(s, i);
        if (m != null) {
          flush();
          for (final inner in _parse(m[1]!, bold: bold, italic: italic)) {
            out.add(
              _Seg(
                inner.text,
                bold: inner.bold,
                italic: inner.italic,
                href: m[2],
              ),
            );
          }
          i += m[0]!.length;
          continue;
        }
      }
      // **bold** / __bold__
      if (s.startsWith('**', i) || s.startsWith('__', i)) {
        final marker = s.substring(i, i + 2);
        final end = s.indexOf(marker, i + 2);
        if (end > i + 2 && s[i + 2] != ' ') {
          flush();
          out.addAll(
            _parse(s.substring(i + 2, end), bold: true, italic: italic),
          );
          i = end + 2;
          continue;
        }
      }
      // *italic* / _italic_ (not inside a word for "_", not around spaces)
      if ((s[i] == '*' || s[i] == '_') &&
          i + 1 < s.length &&
          s[i + 1] != ' ' &&
          s[i + 1] != s[i] &&
          (s[i] == '*' || i == 0 || !_isWordChar(s[i - 1]))) {
        final marker = s[i];
        var end = s.indexOf(marker, i + 1);
        while (end > 0 &&
            end + 1 < s.length &&
            marker == '_' &&
            _isWordChar(s[end + 1])) {
          end = s.indexOf(marker, end + 1);
        }
        if (end > i + 1 &&
            s[end - 1] != ' ' &&
            !s.substring(i + 1, end).contains('\n')) {
          flush();
          out.addAll(_parse(s.substring(i + 1, end), bold: bold, italic: true));
          i = end + 1;
          continue;
        }
      }
      // A backslash escapes the next punctuation character.
      if (s[i] == '\\' &&
          i + 1 < s.length &&
          r'\`*_[]()#+-.!>'.contains(s[i + 1])) {
        buf.write(s[i + 1]);
        i += 2;
        continue;
      }
      buf.write(s[i]);
      i++;
    }
    flush();
    return out;
  }

  static final RegExp _word = RegExp(r'[A-Za-z0-9]');
  static bool _isWordChar(String c) => _word.hasMatch(c);
}
