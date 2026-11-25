// How an assistant reply is read for display: its sources, its safety
// situation (911 / 988 replies) and the links it may contain. A port of the
// web chat's logic (happyheartsdash: src/app/ai-chat/components/AiMessageParts.tsx,
// src/lib/agent-sources.ts, src/lib/agent-fixed-replies.ts), so both chats
// show a reply the same way.
import '../../services/agent_messages.dart';
import 'ai_chat_strings.dart';

/// Situations where the reply tells the user to call 911 / 988 (rule 1).
const Set<String> emergencySituations = {'urgent', 'crisis', 'crisis_other'};

bool isEmergencySituation(Object? v) =>
    v is String && emergencySituations.contains(v);
bool isCareteamSituation(Object? v) =>
    v is String && careteamSituations.contains(v);

/// The fixed reply for a situation in a language ("es", "zh-Hant"; else English).
String fixedReply(String situation, String language) =>
    (fixedReplies[matchAppLanguage(language) ?? 'en'] ??
        fixedReplies['en']!)[situation] ??
    fixedReplies['en']![situation] ??
    '';

/// The app language for a tag such as "zh-TW", "es-419" or "en", or null.
String? matchAppLanguage(String? tag) {
  if (tag == null) return null;
  final parts = tag.trim().replaceAll('_', '-').toLowerCase().split('-')
    ..removeWhere((p) => p.isEmpty);
  if (parts.isEmpty) return null;
  final base = parts.first;
  if (base == 'zh') {
    final sub = parts.skip(1).toList();
    if (sub.contains('hant')) return 'zh-Hant';
    if (sub.contains('hans')) return 'zh-Hans';
    if (sub.any((s) => s == 'tw' || s == 'hk' || s == 'mo')) return 'zh-Hant';
    return 'zh-Hans';
  }
  return aiChatLanguages.contains(base) ? base : null;
}

/// Persian and Arabic-Indic digits → ASCII, so "۹۱۱" counts as 911.
String asciiDigits(String t) => t.replaceAllMapped(RegExp('[۰-۹٠-٩]'), (m) {
  final c = m[0]!.codeUnitAt(0);
  return String.fromCharCode(48 + (c >= 0x06F0 ? c - 0x06F0 : c - 0x0660));
});

final RegExp _diacritics = RegExp('[ً-ٰ]');
final RegExp _punctuation = RegExp(r'[\s\p{P}\p{S}​-‏]', unicode: true);

/// Text reduced to letters and digits for comparing.
String _comparable(String text) => asciiDigits(text)
    .toLowerCase()
    .replaceAll(_diacritics, '')
    .replaceAll(RegExp('[يى]'), 'ی')
    .replaceAll('ك', 'ک')
    .replaceAll(RegExp('[آأإ]'), 'ا')
    .replaceAll(_punctuation, '');

List<(String, String)>? _comparableReplies;

/// Which fixed reply (rule 1a / 1b / 2), in any app language, the text
/// contains, if any. Longer replies first.
String? fixedReplySituation(String text) {
  _comparableReplies ??= [
    for (final situation in const [
      'crisis_other',
      'crisis',
      'urgent',
      'personal',
    ])
      for (final lang in aiChatLanguages)
        (situation, _comparable(fixedReplies[lang]![situation]!)),
  ];
  final t = _comparable(text);
  for (final (situation, reply) in _comparableReplies!) {
    if (reply.isNotEmpty && t.contains(reply)) return situation;
  }
  return null;
}

final RegExp _sourcesMarker = RegExp(
  r'[ \t]*\[sources?:\s*([\d\s,]*)\][ \t]*',
  caseSensitive: false,
);

/// The answer without its "[sources: 2, 4]" marker(s), and the refs listed.
(String, List<int>) splitSources(String text) {
  final refs = <int>[];
  final stripped = text.replaceAllMapped(_sourcesMarker, (m) {
    for (final r in (m[1] ?? '').split(',')) {
      final n = int.tryParse(r.trim());
      if (n != null && n > 0 && !refs.contains(n)) refs.add(n);
    }
    return '';
  });
  if (refs.isEmpty) return (text, refs);
  return (stripped.replaceAll(RegExp(r'\n{3,}'), '\n\n').trimRight(), refs);
}

/// "the National Institutes of Health (Eunice Kennedy Shriver …)" → "National Institutes of Health".
String? displaySource(String? source) {
  if (source == null) return null;
  final name = source
      .replaceAll(RegExp(r'\s*\(.*\)\s*$'), '')
      .replaceAll(RegExp(r'^the\s+', caseSensitive: false), '')
      .trim();
  if (name.isEmpty) return null;
  return name[0].toUpperCase() + name.substring(1);
}

/// One search result an answer can cite (searchKnowledge / webSearch output).
class SearchResult {
  final int? ref;
  final String title;
  final String? source;
  final String? url;
  final bool web;
  final String? documentId;

  /// The community resource directory: used for the answer, not listed as a source.
  final bool hideAsSource;

  const SearchResult({
    required this.ref,
    required this.title,
    this.source,
    this.url,
    this.web = false,
    this.documentId,
    this.hideAsSource = false,
  });

  factory SearchResult.fromJson(Map<String, dynamic> j) => SearchResult(
    ref: j['ref'] is num ? (j['ref'] as num).toInt() : null,
    title: (j['title'] as String?) ?? '',
    source: j['source'] as String?,
    url: (j['url'] as String?)?.trim().isEmpty ?? true
        ? null
        : j['url'] as String,
    web: j['kind'] == 'web',
    documentId: j['documentId'] as String?,
    hideAsSource: j['hideAsSource'] == true,
  );
}

bool _isSearchTool(AgentPart p) =>
    p.toolName == kSearchTool || p.toolName == kWebSearchTool;

/// ref → search result, over every search in this reply (refs are shared).
Map<int, SearchResult> collectSearchResults(AgentMessage message) {
  final byRef = <int, SearchResult>{};
  for (final p in message.parts) {
    if (!p.isTool || !_isSearchTool(p) || p.state != 'output-available') {
      continue;
    }
    for (final r in (p.outputMap['results'] as List? ?? const [])) {
      if (r is! Map) continue;
      final result = SearchResult.fromJson(Map<String, dynamic>.from(r));
      if (result.ref != null) byRef[result.ref!] = result;
    }
  }
  return byRef;
}

final RegExp _urlInText = RegExp(
  r'''https?://[^\s<>()\[\]{}"'`]+''',
  caseSensitive: false,
);

/// Hosts the answer's web links may point to: the page of each webSearch
/// result, and any web address written in a searchKnowledge result. Other web
/// links show as plain text. "www." is dropped.
List<String> linkableHosts(AgentMessage message) {
  final hosts = <String>{};
  void add(String? url) {
    if (url == null) return;
    final uri = Uri.tryParse(url.replaceAll(RegExp(r'[.,;:!?]+$'), ''));
    final host = uri?.host.toLowerCase();
    if (host != null && host.isNotEmpty) {
      hosts.add(host.replaceFirst(RegExp(r'^www\.'), ''));
    }
  }

  for (final p in message.parts) {
    if (!p.isTool || p.state != 'output-available') continue;
    final results = p.outputMap['results'] as List? ?? const [];
    for (final r in results.whereType<Map>()) {
      if (p.toolName == kWebSearchTool) {
        add(r['url'] as String?);
      } else if (p.toolName == kSearchTool) {
        for (final m in _urlInText.allMatches('${r['content'] ?? ''}')) {
          add(m[0]);
        }
      }
    }
  }
  return hosts.toList();
}

/// The host of [url] is one of [hosts], or a subdomain of one.
bool hostAllowed(String url, List<String> hosts) {
  final host = Uri.tryParse(url)?.host.toLowerCase();
  if (host == null || host.isEmpty) return false;
  return hosts.any((h) => host == h || host.endsWith('.$h'));
}

/// The reply's text without "[sources: …]" markers.
String replyText(AgentMessage message) => message.parts
    .where((p) => p.isText)
    .map((p) => splitSources(p.text).$1)
    .join('\n\n')
    .trim();

const Map<String, int> _emergencyRank = {
  'personal': 0,
  'urgent': 1,
  'crisis': 2,
  'crisis_other': 2,
};

/// The emergency (rule 1) a reply is about, from its care-team offer or from
/// the fixed reply in its text, and the language of the reply.
({String situation, String language})? emergencyOf(AgentMessage message) {
  String? situation;
  var language = 'en';
  for (final p in message.parts) {
    if (!p.isTool || p.toolName != kOldCareteamTool) continue;
    final s = p.inputMap['situation'];
    if (isEmergencySituation(s) &&
        (situation == null ||
            _emergencyRank[s]! > _emergencyRank[situation]!)) {
      situation = s as String;
      final l = p.inputMap['language'];
      if (l is String) language = l;
    }
  }
  final fromText = fixedReplySituation(replyText(message));
  if (isEmergencySituation(fromText) &&
      (situation == null ||
          _emergencyRank[fromText]! > _emergencyRank[situation]!)) {
    situation = fromText;
  }
  return situation == null ? null : (situation: situation, language: language);
}

/// "911" (or "۹۱۱") appears as a number of its own.
bool mentionsNumber(String text, String number) =>
    RegExp('(^|\\D)$number(\\D|\$)').hasMatch(asciiDigits(text));
