import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Deep link used for email confirmation and password recovery on mobile.
  /// Must be added to Supabase Auth > URL Configuration > Redirect URLs.
  static const String mobileRedirectUrl = 'io.happyhearts.app://login-callback';

  /// Non-null when Supabase could not be initialised. The UI surfaces this as an
  /// actionable configuration error instead of silently continuing.
  static String? configurationError;

  static bool get isConfigured => configurationError == null;

  /// Redirect target used for auth emails (web uses the current origin).
  static String? get emailRedirectTo => kIsWeb ? null : mobileRedirectUrl;

  // Initialize Supabase - call this in main()
  static Future<void> initialize() async {
    if (supabaseUrl.trim().isEmpty || supabaseAnonKey.trim().isEmpty) {
      configurationError =
          'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY '
          'in env.json (passed with --dart-define-from-file) and restart the app.';
      return;
    }
    final uri = Uri.tryParse(supabaseUrl.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      configurationError =
          'SUPABASE_URL is not a valid URL. Check the value in env.json.';
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl.trim(),
        anonKey: supabaseAnonKey.trim(),
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      configurationError = null;
    } catch (e) {
      configurationError = 'Could not initialise Supabase: $e';
    }
  }

  // Get Supabase client
  SupabaseClient get client => Supabase.instance.client;
}
