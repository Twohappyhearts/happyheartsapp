/// Botpress Webchat (third-party AI assistant) configuration.
///
/// These values come from Botpress Studio > Webchat > Deploy Settings > Embed
/// code. They are public identifiers (the config script contains botId and
/// clientId), not secrets. Override them in env.json if the bot changes:
///   "BOTPRESS_INJECT_URL": "...", "BOTPRESS_CONFIG_URL": "..."
class BotpressConfig {
  static const String injectUrl = String.fromEnvironment(
    'BOTPRESS_INJECT_URL',
    defaultValue: 'https://cdn.botpress.cloud/webchat/v5.0/inject.js',
  );

  static const String configUrl = String.fromEnvironment(
    'BOTPRESS_CONFIG_URL',
    defaultValue:
        'https://files.bpcontent.cloud/2026/10/12/22/20261012222731-KUZXBDV4.js',
  );

  /// Webchat client id (also inside the config script). Botpress Webchat v5
  /// stores {conversationId, user:{userId,userToken}} in localStorage under
  /// `bp-webchat-<clientId>-client` (verified 2026-10-20).
  static const String clientId = String.fromEnvironment(
    'BOTPRESS_CLIENT_ID',
    defaultValue: '478a0bc8-c5a7-42a3-9372-c104ebc5779e',
  );

  static String get storageKey => 'bp-webchat-$clientId-client';

  /// Origin the inline HTML runs under (same as Botpress' React Native guide),
  /// so the webchat can use localStorage to keep the conversation.
  static const String baseUrl = 'https://cdn.botpress.cloud/';

  static bool get isConfigured =>
      injectUrl.startsWith('https://') && configUrl.startsWith('https://');

  static Set<String> get allowedHosts => {
    Uri.parse(baseUrl).host,
    Uri.parse(injectUrl).host,
    Uri.parse(configUrl).host,
  };
}
