import 'package:flutter/foundation.dart';

/// Where the HappyHearts AI assistant page is served from (the Next.js
/// dashboard app, page /m/assistant).
///
/// Set AGENT_WEB_URL in env.json, e.g.
///   local, phone on the same Wi-Fi:  "http://192.168.1.20:4028"
///   production:                      "https://happyheartsdash-production.up.railway.app"
/// Without it, local defaults are used: the Android emulator reaches the
/// computer as 10.0.2.2, the iOS simulator as localhost.
class AgentConfig {
  static const String _configured = String.fromEnvironment('AGENT_WEB_URL');

  static String get baseUrl {
    final v = _configured.trim();
    if (v.isNotEmpty) return v.replaceAll(RegExp(r'/+$'), '');
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:4028'
        : 'http://localhost:4028';
  }

  static Uri get pageUri => Uri.parse('$baseUrl/m/assistant');

  static String get host => Uri.parse(baseUrl).host;
}
