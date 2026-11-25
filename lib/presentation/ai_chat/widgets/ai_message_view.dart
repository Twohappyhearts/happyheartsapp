import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/agent_messages.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/chat/chat_widgets.dart';
import '../agent_reply.dart';
import '../ai_chat_strings.dart';
import '../ai_tool_strings.dart';
import 'ai_markdown.dart';

/// The content of one assistant reply: each search the assistant runs (the
/// HappyHearts library or trusted websites, live while it runs, tap to see
/// what it found), the answer with its sources, a status line while it is on
/// its way, and 911 / 988 replies in a red box with call buttons. The model's
/// reasoning is not shown to patients.
class AiMessageView extends StatelessWidget {
  final AgentMessage message;

  /// This reply is still streaming.
  final bool streaming;
  final AiChatStrings strings;
  final AiToolStrings toolStrings;
  final void Function(Uri uri) onOpenLink;

  /// Opens the original file of a knowledge-base source without a web page.
  final Future<void> Function(String documentId) onOpenDocument;

  const AiMessageView({
    required this.message,
    required this.streaming,
    required this.strings,
    required this.toolStrings,
    required this.onOpenLink,
    required this.onOpenDocument,
    super.key,
  });

  static final TextStyle _textStyle = chatBubbleTextStyle(isUser: false);

  @override
  Widget build(BuildContext context) {
    final hosts = linkableHosts(message);
    final emergency = emergencyOf(message);
    // Care-team offers of older replies (kOldCareteamTool): not shown.
    final careteamParts = message.parts
        .where((p) => p.isTool && p.toolName == kOldCareteamTool)
        .toList();
    final searches = message.parts
        .where(
          (p) =>
              p.isTool &&
              (p.toolName == kSearchTool || p.toolName == kWebSearchTool),
        )
        .toList();

    final children = <Widget>[];

    // ---- Emergency (rule 1): the reply in a red box with call buttons.
    if (emergency != null) {
      final body = replyText(message);
      // Once the turn ended, make sure the 911 / 988 reply is there whatever
      // the model wrote; add the fixed reply if not.
      final complete = careteamParts.isNotEmpty || !streaming;
      final crisis = emergency.situation != 'urgent';
      final missing =
          complete &&
          (!mentionsNumber(body, '911') ||
              (crisis && !mentionsNumber(body, '988')));
      final text = missing
          ? [
              body,
              fixedReply(emergency.situation, emergency.language),
            ].where((t) => t.isNotEmpty).join('\n\n')
          : body;
      if (text.isNotEmpty) {
        children.add(
          _EmergencyReply(
            text: text,
            crisis: crisis,
            hosts: hosts,
            strings: strings,
            onOpenLink: onOpenLink,
          ),
        );
      }
      return _column(children);
    }

    var hasText = false;
    final results = collectSearchResults(message);
    for (final p in message.parts) {
      // Each search where it happened in the reply, usually before the answer.
      if (p.isTool &&
          (p.toolName == kSearchTool || p.toolName == kWebSearchTool)) {
        children.add(
          _ToolActivity(
            key: ValueKey('tool-${p.toolCallId}'),
            part: p,
            strings: toolStrings,
            onOpenLink: onOpenLink,
          ),
        );
        continue;
      }
      if (!p.isText || p.text.trim().isEmpty) continue;
      hasText = true;
      final (text, refs) = splitSources(p.text);
      if (text.trim().isNotEmpty) {
        children.add(
          AiMarkdown(
            text: text,
            linkableHosts: hosts,
            style: _textStyle,
            onOpenLink: onOpenLink,
          ),
        );
      }
      if (refs.isNotEmpty) {
        children.add(
          _SourceChips(
            refs: refs,
            results: results,
            strings: strings,
            onOpenLink: onOpenLink,
            onOpenDocument: onOpenDocument,
          ),
        );
      }
    }

    // An older reply that was only a care-team offer, with no text: show its
    // fixed reply (the referral) so the message is not empty.
    if (!hasText && !streaming && careteamParts.isNotEmpty) {
      final input = careteamParts.first.inputMap;
      final situation = input['situation'];
      if (isCareteamSituation(situation)) {
        final language = input['language'] is String
            ? input['language'] as String
            : 'en';
        children.add(
          AiMarkdown(
            text: fixedReply(situation as String, language),
            linkableHosts: hosts,
            style: _textStyle,
            onOpenLink: onOpenLink,
          ),
        );
      }
    }

    // While nothing is searching and no text has come yet: "Thinking…" before
    // any search, "Writing your answer…" after them. (A running search shows
    // its own row above.)
    final searching = searches.any((p) => p.isRunning);
    final waiting = streaming && !hasText;
    if (waiting && !searching) {
      children.add(
        AiWaitingStatus(
          key: const ValueKey('waiting'),
          label: searches.isNotEmpty ? strings.writingAnswer : strings.thinking,
          hint: strings.waitHint,
        ),
      );
    }
    return _column(children);
  }

  Widget _column(List<Widget> children) {
    final spaced = <Widget>[];
    for (final c in children) {
      if (spaced.isNotEmpty) spaced.add(const SizedBox(height: 8));
      spaced.add(c);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: spaced,
    );
  }
}

/// "Searching trusted sources…" with a spinner. After 8 s without text it
/// also says how long checking sources can take.
class AiWaitingStatus extends StatefulWidget {
  final String label;
  final String hint;
  const AiWaitingStatus({required this.label, required this.hint, super.key});

  @override
  State<AiWaitingStatus> createState() => _AiWaitingStatusState();
}

class _AiWaitingStatusState extends State<AiWaitingStatus> {
  bool _slow = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans(
      fontSize: 13,
      color: AppTheme.textMedium,
    );
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: AppTheme.purple,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: style),
                if (_slow)
                  Text(
                    widget.hint,
                    style: style.copyWith(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rule 1 replies: hard to miss, with buttons that call 911 (and 988 for
/// thoughts of self-harm).
class _EmergencyReply extends StatelessWidget {
  final String text;
  final bool crisis;
  final List<String> hosts;
  final AiChatStrings strings;
  final void Function(Uri uri) onOpenLink;

  const _EmergencyReply({
    required this.text,
    required this.crisis,
    required this.hosts,
    required this.strings,
    required this.onOpenLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.warning_rounded,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AiMarkdown(
                  text: text,
                  linkableHosts: hosts,
                  style: chatBubbleTextStyle(
                    isUser: false,
                  ).copyWith(fontWeight: FontWeight.w500),
                  onOpenLink: onOpenLink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CallButton(
                number: '911',
                label: strings.call('911'),
                primary: true,
                onOpenLink: onOpenLink,
              ),
              if (crisis)
                CallButton(
                  number: '988',
                  label: strings.call('988'),
                  primary: false,
                  onOpenLink: onOpenLink,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A button that calls 911 / 988 (the phone's dialer).
class CallButton extends StatelessWidget {
  final String number;
  final String label;
  final bool primary;
  final void Function(Uri uri) onOpenLink;

  const CallButton({
    required this.number,
    required this.label,
    required this.primary,
    required this.onOpenLink,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w700,
    );
    void onTap() => onOpenLink(Uri(scheme: 'tel', path: number));
    final icon = const Icon(Icons.phone_rounded, size: 18);
    return primary
        ? ElevatedButton.icon(
            onPressed: onTap,
            icon: icon,
            label: Text(label, style: style),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        : OutlinedButton.icon(
            onPressed: onTap,
            icon: icon,
            label: Text(label, style: style),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              backgroundColor: AppTheme.surfaceLight,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              side: const BorderSide(color: AppTheme.errorColor, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
  }
}

/// The documents an answer cited, folded into one "n sources" pill that
/// opens the list. Web pages open in the browser; a library document without
/// a web page opens its original file.
class _SourceChips extends StatefulWidget {
  final List<int> refs;
  final Map<int, SearchResult> results;
  final AiChatStrings strings;
  final void Function(Uri uri) onOpenLink;
  final Future<void> Function(String documentId) onOpenDocument;

  const _SourceChips({
    required this.refs,
    required this.results,
    required this.strings,
    required this.onOpenLink,
    required this.onOpenDocument,
  });

  @override
  State<_SourceChips> createState() => _SourceChipsState();
}

class _SourceChipsState extends State<_SourceChips> {
  bool _open = false;
  String? _opening;
  String? _failed;

  Future<void> _openDocument(String key, String documentId) async {
    if (_opening != null) return;
    setState(() {
      _opening = key;
      _failed = null;
    });
    try {
      await widget.onOpenDocument(documentId);
    } catch (_) {
      if (mounted) setState(() => _failed = key);
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = <String, SearchResult>{};
    for (final ref in widget.refs) {
      final r = widget.results[ref];
      if (r == null || r.hideAsSource) continue;
      final key = r.web && r.url != null ? r.url! : r.title;
      docs.putIfAbsent(key, () => r);
    }
    if (docs.isEmpty) return const SizedBox.shrink();

    final small = GoogleFonts.plusJakartaSans(
      fontSize: 13,
      color: AppTheme.textDark,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: const Color(0xFFEFF6FF),
          shape: const StadiumBorder(
            side: BorderSide(color: Color(0xFFBFDBFE)),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.strings.sources(docs.length),
                    style: small.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_open)
          for (final entry in docs.entries) ...[
            const SizedBox(height: 6),
            _sourceRow(entry.key, entry.value, small),
            if (_failed == entry.key)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4, top: 2),
                child: Text(
                  widget.strings.openSourceError,
                  style: small.copyWith(
                    fontSize: 12,
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
          ],
      ],
    );
  }

  Widget _sourceRow(String key, SearchResult d, TextStyle style) {
    final label = [
      displaySource(d.source),
      d.title,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');
    final url = d.url != null ? Uri.tryParse(d.url!) : null;
    final VoidCallback? onTap = url != null
        ? () => widget.onOpenLink(url)
        : d.documentId != null
        ? () => _openDocument(key, d.documentId!)
        : null;
    final opening = _opening == key;
    return Material(
      color: AppTheme.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: opening
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.6),
                      )
                    : Icon(
                        d.web
                            ? Icons.public_rounded
                            : Icons.description_outlined,
                        size: 14,
                        color: AppTheme.primary,
                      ),
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: style)),
            ],
          ),
        ),
      ),
    );
  }
}

/// One search the assistant ran: a spinner while it runs, then what it
/// searched and how many results came back. Tap to see the results.
class _ToolActivity extends StatefulWidget {
  final AgentPart part;
  final AiToolStrings strings;
  final void Function(Uri uri) onOpenLink;

  const _ToolActivity({
    required this.part,
    required this.strings,
    required this.onOpenLink,
    super.key,
  });

  @override
  State<_ToolActivity> createState() => _ToolActivityState();
}

class _ToolActivityState extends State<_ToolActivity> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.part;
    final t = widget.strings;
    final web = p.toolName == kWebSearchTool;
    final running = p.isRunning;
    final failed = p.state == 'output-error';
    final results = p.state == 'output-available'
        ? (p.outputMap['results'] as List? ?? const [])
              .whereType<Map>()
              .map((r) => Map<String, dynamic>.from(r))
              .toList()
        : const <Map<String, dynamic>>[];
    final label = failed
        ? t.searchFailed
        : running
        ? (web ? t.searchingWeb : t.searchingLibrary)
        : (web ? t.searchedWeb : t.searchedLibrary);
    // Shown after the query, as on the dashboard: "Searched … · “query” · 8 results".
    final count = !failed && !running ? ' · ${t.results(results.length)}' : '';
    final style = GoogleFonts.plusJakartaSans(
      fontSize: 12.5,
      color: AppTheme.textMedium,
    );
    final canOpen = results.isNotEmpty;
    final input = p.input;
    final query = input is Map ? (input['query'] as String?)?.trim() ?? '' : '';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: canOpen ? () => setState(() => _open = !_open) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 15,
                    height: 15,
                    child: running
                        ? const CircularProgressIndicator(
                            strokeWidth: 1.8,
                            color: AppTheme.purple,
                          )
                        : Icon(
                            failed
                                ? Icons.error_outline_rounded
                                : web
                                ? Icons.public_rounded
                                : Icons.menu_book_outlined,
                            size: 15,
                            color: failed
                                ? AppTheme.errorColor
                                : AppTheme.purple,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: label,
                        children: [
                          if (query.isNotEmpty)
                            TextSpan(
                              text: ' · “$query”',
                              style: TextStyle(color: AppTheme.textLight),
                            ),
                          if (count.isNotEmpty) TextSpan(text: count),
                        ],
                      ),
                      style: style,
                    ),
                  ),
                  if (canOpen)
                    Icon(
                      _open
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: AppTheme.textLight,
                    ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(33, 0, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final r in results) _resultRow(r, style)],
              ),
            ),
        ],
      ),
    );
  }

  /// One search result as the dashboard shows it: title · section, then the
  /// retrieved text (first 4 lines). Only website results open a page.
  Widget _resultRow(Map<String, dynamic> r, TextStyle style) {
    final web = widget.part.toolName == kWebSearchTool;
    final title = (r['title'] as String?)?.trim() ?? '';
    final section = (r['section'] as String?)?.trim() ?? '';
    final content = (r['content'] as String?)?.trim() ?? '';
    final url = web && r['url'] is String
        ? Uri.tryParse(r['url'] as String)
        : null;
    final heading = Text.rich(
      TextSpan(
        text: title.isEmpty ? '—' : title,
        style: url != null
            ? TextStyle(
                color: AppTheme.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.primary,
              )
            : null,
        children: [
          if (section.isNotEmpty && section != title)
            TextSpan(
              text: ' · $section',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: AppTheme.textLight,
                decoration: TextDecoration.none,
              ),
            ),
        ],
      ),
      style: style.copyWith(
        color: AppTheme.textDark,
        fontWeight: FontWeight.w600,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          url == null
              ? heading
              : GestureDetector(
                  onTap: () => widget.onOpenLink(url),
                  child: heading,
                ),
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: style.copyWith(
                  fontSize: 12,
                  height: 1.4,
                  color: AppTheme.textMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
