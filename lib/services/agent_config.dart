import 'package:flutter/foundation.dart';

/// Where the HappyHearts AI assistant API is served from (the Next.js
/// dashboard app: /api/agent/*), and the public legal pages (/legal/*).
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

  /// Public page that redirects to the current Terms of Use / Privacy Policy
  /// PDF uploaded on the dashboard (or the built-in sample until one is).
  static Uri legalUri(LegalDocument document) =>
      Uri.parse('$baseUrl/legal/${document.path}');

  /// The AI chat API: /api/agent/...
  static Uri apiUri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl/api/agent/$path').replace(queryParameters: query);
}

enum LegalDocument {
  terms('terms'),
  privacy('privacy');

  const LegalDocument(this.path);
  final String path;
}
