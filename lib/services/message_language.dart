/// Guesses which language a patient's message to the research team is in, so
/// the app can warn when it is not one the team reads
/// (app_settings.message_languages, set on the dashboard's Settings page).
///
/// Pure functions, no I/O. Rules (plan 4.3.4.7), by writing system:
/// * Chinese characters -> zh; Hangul -> ko;
/// * Arabic script: Farsi letters (پ چ ژ گ, and Farsi ی ک) -> fa, else ar;
/// * Latin: Vietnamese-only letters -> vi; ñ ¿ ¡, or more common Spanish
///   words than English ones -> es; otherwise en;
/// * any other writing system -> [unknownLanguage] (never accepted).
/// Messages with fewer than [minLetters] letters are not checked.
library;

/// At least this many letters before a message is checked.
const int minLetters = 4;

/// Detected writing system the app has no language for (e.g. Cyrillic).
const String unknownLanguage = 'und';

final RegExp _letter = RegExp(r'\p{L}', unicode: true);
final RegExp _han = RegExp(r'\p{Script=Han}', unicode: true);
final RegExp _hangul = RegExp(r'\p{Script=Hangul}', unicode: true);
final RegExp _arabic = RegExp(r'\p{Script=Arabic}', unicode: true);
final RegExp _latin = RegExp(r'\p{Script=Latin}', unicode: true);

/// Letters only Farsi uses among the Arabic-script languages here:
/// پ چ ژ گ, Farsi yeh ی (U+06CC) and keheh ک (U+06A9).
final RegExp _farsiLetters = RegExp('[پچژگیک]');

/// Vietnamese letters (ă đ ơ ư and the tone-marked vowels of the Latin
/// Extended Additional block, U+1EA0–U+1EF9).
final RegExp _vietnamese = RegExp('[ăĂđĐơƠưƯẠ-ỹ]');

final RegExp _spanishMarks = RegExp('[ñÑ¿¡]');
final RegExp _word = RegExp(r"[\p{L}']+", unicode: true);

/// Short, frequent words that are Spanish and not English.
const Set<String> _spanishWords = {
  'que',
  'qué',
  'de',
  'la',
  'el',
  'los',
  'las',
  'por',
  'para',
  'una',
  'uno',
  'es',
  'está',
  'estoy',
  'están',
  'tengo',
  'tiene',
  'tienen',
  'mi',
  'mis',
  'como',
  'cómo',
  'porque',
  'pero',
  'muy',
  'con',
  'del',
  'al',
  'gracias',
  'hola',
  'necesito',
  'ayuda',
  'puedo',
  'quiero',
  'cuando',
  'cuándo',
  'donde',
  'dónde',
  'también',
  'bebé',
  'embarazo',
  'dolor',
  'hoy',
  'ayer',
  'mañana',
  'sí',
  'y',
  'o',
  'pregunta',
  'tomar',
  'medicina',
  'presión',
  'cabeza',
  'siento',
  'estaba',
  'hay',
  'esto',
  'eso',
  'mucho',
  'poco',
  'favor',
  'buenos',
  'buenas',
  'días',
  'noches',
  'usted',
  'ustedes',
};

/// Short, frequent words that are English and not Spanish.
const Set<String> _englishWords = {
  'the',
  'and',
  'is',
  'my',
  'i',
  "i'm",
  'you',
  'to',
  'have',
  'has',
  'what',
  'how',
  'can',
  'this',
  'that',
  'it',
  'of',
  'for',
  'with',
  'not',
  'are',
  'do',
  'does',
  'was',
  'will',
  'be',
  'baby',
  'help',
  'question',
  'pain',
  'need',
  'feel',
  'when',
  'where',
  'should',
  'please',
  'thank',
  'thanks',
  'hello',
  'hi',
  'am',
  'been',
  'took',
  'take',
  'today',
  'yesterday',
  'pressure',
  'blood',
  'headache',
  'about',
  'video',
  'lesson',
  'from',
  'they',
  'we',
};

/// The language family of [text]: en, es, vi, ko, zh, fa, ar, or
/// [unknownLanguage]. Null when the text has fewer than [minLetters] letters.
String? detectMessageLanguage(String text) {
  final letters = _letter.allMatches(text).length;
  if (letters < minLetters) return null;

  final han = _han.allMatches(text).length;
  final hangul = _hangul.allMatches(text).length;
  final arabic = _arabic.allMatches(text).length;
  final latin = _latin.allMatches(text).length;
  final other = letters - han - hangul - arabic - latin;

  // The writing system with the most letters decides.
  final counts = {
    'zh': han,
    'ko': hangul,
    'arabic': arabic,
    'latin': latin,
    unknownLanguage: other,
  };
  final script = counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;

  switch (script) {
    case 'arabic':
      return _farsiLetters.hasMatch(text) ? 'fa' : 'ar';
    case 'latin':
      return _latinLanguage(text);
    default:
      return script;
  }
}

String _latinLanguage(String text) {
  if (_vietnamese.hasMatch(text)) return 'vi';
  if (_spanishMarks.hasMatch(text)) return 'es';
  var es = 0, en = 0;
  for (final m in _word.allMatches(text.toLowerCase())) {
    final w = m.group(0)!;
    if (_spanishWords.contains(w)) es++;
    if (_englishWords.contains(w)) en++;
  }
  return es > en ? 'es' : 'en';
}

/// The family part of an app language code (zh-Hans -> zh).
String languageFamily(String code) => code.split('-').first.toLowerCase();

/// Whether the research team reads [detected] (from [detectMessageLanguage]).
/// [accepted] holds app language codes; zh-Hans and zh-Hant both accept any
/// Chinese text.
bool isMessageLanguageAccepted(String detected, Iterable<String> accepted) {
  if (detected == unknownLanguage) return false;
  return accepted.any((code) => languageFamily(code) == detected);
}

/// The languages to name in the notice: [accepted] codes the app knows, in
/// the order staff set them, without duplicates.
List<String> normalizeAcceptedLanguages(
  Object? value, {
  required Set<String> known,
}) {
  if (value is! List) return const [];
  final out = <String>[];
  for (final v in value) {
    if (v is String && known.contains(v) && !out.contains(v)) out.add(v);
  }
  return out;
}
