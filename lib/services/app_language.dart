import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import './auth_service.dart';
import './supabase_service.dart';

/// One of the app's languages: Orange County's Medi-Cal threshold languages
/// plus English, with Chinese in both scripts. Same codes as the database
/// (valid_language_code, migration 20261111000200) and the dashboard
/// (src/lib/languages.ts).
class AppLanguage {
  /// en, es, vi, ko, zh-Hans, zh-Hant, fa or ar.
  final String code;

  /// The language's own name, shown in the language pickers.
  final String nativeName;
  final bool rtl;

  const AppLanguage(this.code, this.nativeName, {this.rtl = false});

  /// The Flutter locale for this language (zh-Hant -> zh, script Hant).
  Locale get locale {
    final parts = code.split('-');
    return parts.length == 2
        ? Locale.fromSubtags(languageCode: parts[0], scriptCode: parts[1])
        : Locale(code);
  }
}

const List<AppLanguage> appLanguages = [
  AppLanguage('en', 'English'),
  AppLanguage('es', 'Español'),
  AppLanguage('vi', 'Tiếng Việt'),
  AppLanguage('ko', '한국어'),
  AppLanguage('zh-Hans', '简体中文'),
  AppLanguage('zh-Hant', '繁體中文'),
  AppLanguage('fa', 'فارسی', rtl: true),
  AppLanguage('ar', 'العربية', rtl: true),
];

/// The app language for a phone locale, or null if the app doesn't have it.
/// Chinese: script Hant or region TW / HK / MO -> zh-Hant, otherwise zh-Hans.
String? appLanguageCodeForLocale(Locale l) {
  final lang = l.languageCode.toLowerCase();
  if (lang == 'zh') {
    final script = l.scriptCode?.toLowerCase();
    final region = l.countryCode?.toUpperCase();
    final traditional =
        script == 'hant' ||
        (script == null && const {'TW', 'HK', 'MO'}.contains(region));
    return traditional ? 'zh-Hant' : 'zh-Hans';
  }
  return appLanguageFor(lang)?.code;
}

AppLanguage? appLanguageFor(String? code) {
  for (final l in appLanguages) {
    if (l.code == code) return l;
  }
  return null;
}

/// The app's display language.
///
/// * By default it follows the phone's language; if the phone's language is
///   not one of [appLanguages], English.
/// * A language picked in the app (sign-in screen or Profile) is kept on the
///   phone, and saved to `profiles.preferred_language` once signed in. Saving
///   is best effort: a failure never blocks the app.
/// * After sign-in, a language stored in the profile wins, unless the patient
///   picked one on the sign-in screen just before: that newer choice is saved
///   to the profile instead.
class AppLanguageController extends ChangeNotifier with WidgetsBindingObserver {
  AppLanguageController._();
  static final AppLanguageController instance = AppLanguageController._();

  static const String _prefsKey = 'app_language';

  /// The language picked in the app, or null to follow the phone.
  String? _chosen;

  /// Picked while signed out, not yet compared with the profile.
  bool _chosenWhileSignedOut = false;

  String _phone = _resolve(PlatformDispatcher.instance.locales);
  int _syncedGeneration = -1;
  bool _started = false;

  /// Language code in use (en, es, vi, ko, zh-Hans, zh-Hant, fa, ar).
  String get code => _chosen ?? _phone;
  AppLanguage get language => appLanguageFor(code) ?? appLanguages.first;
  Locale get locale => language.locale;

  /// The patient's own pick, or null when the app follows the phone.
  String? get chosen => _chosen;

  /// The phone's language as the app would use it.
  String get phoneLanguage => _phone;

  static String _resolve(List<Locale> phoneLocales) {
    for (final l in phoneLocales) {
      final match = appLanguageCodeForLocale(l);
      if (match != null) return match;
    }
    return 'en';
  }

  /// Restores the saved choice. Call once at start-up, before runApp.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    try {
      final prefs = await SharedPreferences.getInstance();
      _chosen = appLanguageFor(prefs.getString(_prefsKey))?.code;
    } catch (e) {
      debugPrint('AppLanguage: could not read the saved language: $e');
    }
    AuthService.instance.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    final next = _resolve(locales ?? PlatformDispatcher.instance.locales);
    if (next == _phone) return;
    _phone = next;
    if (_chosen == null) notifyListeners();
  }

  /// Picks a language ([code] null = follow the phone again).
  Future<void> choose(String? code) async {
    final next = appLanguageFor(code)?.code;
    final changed = next != _chosen;
    _chosen = next;
    if (changed) notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (next == null) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, next);
      }
    } catch (e) {
      debugPrint('AppLanguage: could not save the language on the phone: $e');
    }
    if (AuthService.instance.isSignedIn) {
      _chosenWhileSignedOut = false;
      await _saveToProfile(next);
    } else {
      _chosenWhileSignedOut = true;
    }
  }

  void _onAuthChanged() {
    final auth = AuthService.instance;
    if (!auth.isSignedIn || auth.generation == _syncedGeneration) return;
    _syncedGeneration = auth.generation;
    unawaited(_syncWithProfile(auth.generation));
  }

  Future<void> _syncWithProfile(int generation) async {
    final uid = AuthService.instance.userId;
    if (uid == null || !SupabaseService.isConfigured) return;
    if (_chosenWhileSignedOut) {
      _chosenWhileSignedOut = false;
      await _saveToProfile(_chosen);
      return;
    }
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('preferred_language')
          .eq('id', uid)
          .maybeSingle();
      if (AuthService.instance.generation != generation) return;
      final saved = appLanguageFor(row?['preferred_language'] as String?);
      if (saved != null) {
        if (saved.code != _chosen) {
          _chosen = saved.code;
          notifyListeners();
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_prefsKey, saved.code);
          } catch (_) {}
        }
      } else if (_chosen != null) {
        await _saveToProfile(_chosen);
      }
    } catch (e) {
      // Older database without the column, offline, ...: keep the phone's choice.
      debugPrint('AppLanguage: could not read profiles.preferred_language: $e');
    }
  }

  Future<void> _saveToProfile(String? code) async {
    final uid = AuthService.instance.userId;
    if (uid == null || !SupabaseService.isConfigured) return;
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'preferred_language': code})
          .eq('id', uid);
    } catch (e) {
      debugPrint('AppLanguage: could not save profiles.preferred_language: $e');
    }
  }
}

/// App texts in the current language, for code without a BuildContext
/// (services, error messages). Widgets use `context.l10n`.
AppLocalizations get appL10n =>
    lookupAppLocalizations(AppLanguageController.instance.locale);

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Dates and times in the app's language (month names, AM/PM or 24-hour,
/// word order). Needs the Material localizations loaded (any widget below
/// MaterialApp).
extension AppDateFormats on AppLocalizations {
  /// 3:05 PM
  String time(DateTime t) => DateFormat.jm(localeName).format(t);

  /// Nov 9
  String monthDay(DateTime t) => DateFormat.MMMd(localeName).format(t);

  /// Nov 9, 2026
  String monthDayYear(DateTime t) => DateFormat.yMMMd(localeName).format(t);

  /// November 2026
  String monthYear(DateTime t) => DateFormat.yMMMM(localeName).format(t);

  /// November 9
  String monthDayLong(DateTime t) => DateFormat.MMMMd(localeName).format(t);

  /// 11/9/2026
  String numericDate(DateTime t) => DateFormat.yMd(localeName).format(t);

  /// "Today, 3:05 PM", "Yesterday, 3:05 PM", "Nov 9, 3:05 PM", or with the
  /// year when it is not this year.
  String relativeDateTime(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final clock = time(t);
    if (day == today) return dateTodayAt(clock);
    if (day == today.subtract(const Duration(days: 1))) {
      return dateYesterdayAt(clock);
    }
    return dateAt(t.year == now.year ? monthDay(t) : monthDayYear(t), clock);
  }
}
