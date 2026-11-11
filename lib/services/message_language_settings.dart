import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './app_language.dart';
import './message_language.dart';
import './supabase_service.dart';

/// The languages the research team reads in patients' messages
/// (app_settings.message_languages, set on the dashboard's Settings page).
///
/// Read at most every [_maxAge]; when it can't be read (offline, older
/// database, invalid value) the last value read on this phone is used, or
/// ["en", "es"]. The fallback is cached too, so a send is never held up by
/// repeated slow lookups.
class MessageLanguageSettings {
  MessageLanguageSettings._();
  static final MessageLanguageSettings instance = MessageLanguageSettings._();

  static const List<String> defaultLanguages = ['en', 'es'];
  static const String _prefsKey = 'message_languages';
  static const Duration _maxAge = Duration(minutes: 10);
  static const Duration _timeout = Duration(seconds: 4);

  List<String>? _cached;
  DateTime? _cachedAt;
  Future<List<String>>? _inFlight;

  static final Set<String> _known = {for (final l in appLanguages) l.code};

  /// Starts a lookup in the background (e.g. when the chat opens).
  void prefetch() => unawaited(acceptedLanguages());

  Future<List<String>> acceptedLanguages() {
    final cached = _cached;
    final at = _cachedAt;
    if (cached != null &&
        at != null &&
        DateTime.now().difference(at) < _maxAge) {
      return Future.value(cached);
    }
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  Future<List<String>> _load() async {
    List<String> result;
    try {
      if (!SupabaseService.isConfigured) throw StateError('not configured');
      final row = await Supabase.instance.client
          .from('app_settings')
          .select('value')
          .eq('key', 'message_languages')
          .maybeSingle()
          .timeout(_timeout);
      final list = normalizeAcceptedLanguages(row?['value'], known: _known);
      if (list.isEmpty) throw const FormatException('no valid languages');
      result = list;
      unawaited(_remember(list));
    } catch (e) {
      debugPrint('message_languages not read ($e); using the last known value');
      result = await _lastKnown() ?? defaultLanguages;
    }
    _cached = result;
    _cachedAt = DateTime.now();
    return result;
  }

  Future<void> _remember(List<String> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(list));
    } catch (_) {}
  }

  Future<List<String>?> _lastKnown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return null;
      final list = normalizeAcceptedLanguages(jsonDecode(raw), known: _known);
      return list.isEmpty ? null : list;
    } catch (_) {
      return null;
    }
  }
}
