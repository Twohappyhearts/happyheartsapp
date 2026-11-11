import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';
import './tracking_service.dart';

enum AuthStatus { unknown, signedOut, signedIn, passwordRecovery }

/// Outcome of a registration attempt.
enum SignUpOutcome { signedIn, confirmationRequired }

/// Registration stopped before contacting Supabase Auth: the username is
/// already used by another account.
class UsernameTakenException implements Exception {
  const UsernameTakenException();
}

/// Single source of truth for the authentication state. Drives router redirects.
/// `generation` increments on every identity change so async work started for a
/// previous account can detect that it is stale and drop its results.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  StreamSubscription<AuthState>? _sub;
  AuthStatus _status = AuthStatus.unknown;
  String? _userId;
  int _generation = 0;
  bool _started = false;

  AuthStatus get status => _status;
  String? get userId => _userId;
  int get generation => _generation;
  bool get isSignedIn => _status == AuthStatus.signedIn;

  SupabaseClient get _client => Supabase.instance.client;

  /// User email comes from the authenticated account (auth.users), never profiles.
  String? get email =>
      SupabaseService.isConfigured ? _client.auth.currentUser?.email : null;

  void start() {
    if (_started) return;
    _started = true;

    if (!SupabaseService.isConfigured) {
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }

    // Session restoration: Supabase persists the session; read it synchronously.
    final session = _client.auth.currentSession;
    _applySession(session, recovery: false);

    _sub = _client.auth.onAuthStateChange.listen((data) {
      switch (data.event) {
        case AuthChangeEvent.passwordRecovery:
          _applySession(data.session, recovery: true);
          break;
        case AuthChangeEvent.signedOut:
          _applySession(null, recovery: false);
          break;
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userUpdated:
          // Keep recovery mode until the user finishes resetting the password.
          if (_status == AuthStatus.passwordRecovery &&
              data.session?.user.id == _userId) {
            return;
          }
          _applySession(data.session, recovery: false);
          break;
        default:
          break;
      }
    });
  }

  void _applySession(Session? session, {required bool recovery}) {
    final newId = session?.user.id;
    final newStatus = session == null
        ? AuthStatus.signedOut
        : (recovery ? AuthStatus.passwordRecovery : AuthStatus.signedIn);

    final identityChanged = newId != _userId;
    if (identityChanged) _generation++;

    if (identityChanged || newStatus != _status) {
      _userId = newId;
      _status = newStatus;
      notifyListeners();
    }
  }

  // ---- Actions ---------------------------------------------------------------

  Future<void> signIn({required String email, required String password}) async {
    _requireConfigured();
    final res = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (res.session == null) {
      throw const AuthException('Sign-in did not create a session.');
    }
    _applySession(res.session, recovery: false);
  }

  /// True if [username] is valid and not used by another account.
  Future<bool> isUsernameAvailable(String username) async {
    _requireConfigured();
    final res = await _client.rpc(
      'username_available',
      params: {'p_username': username.trim()},
    );
    return res == true;
  }

  Future<SignUpOutcome> signUp({
    required String fullName,
    required String username,
    required String phone,
    required String email,
    required String password,
  }) async {
    _requireConfigured();
    if (!await isUsernameAvailable(username)) {
      throw const UsernameTakenException();
    }
    final res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: SupabaseService.emailRedirectTo,
      // Profile data only (applied by the handle_new_auth_user trigger).
      // Roles are never taken from client metadata.
      data: {
        'full_name': fullName.trim(),
        'username': username.trim(),
        'phone_number': phone.trim(),
      },
    );
    if (res.session != null) {
      _applySession(res.session, recovery: false);
      return SignUpOutcome.signedIn;
    }
    return SignUpOutcome.confirmationRequired;
  }

  Future<void> resendConfirmation(String email) async {
    _requireConfigured();
    await _client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: SupabaseService.emailRedirectTo,
    );
  }

  Future<void> requestPasswordReset(String email) async {
    _requireConfigured();
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: SupabaseService.emailRedirectTo,
    );
  }

  /// Completes recovery (or changes the password for a signed-in user).
  Future<void> updatePassword(String newPassword) async {
    _requireConfigured();
    await _client.auth.updateUser(UserAttributes(password: newPassword));
    if (_status == AuthStatus.passwordRecovery) {
      _status = AuthStatus.signedIn;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (!SupabaseService.isConfigured) return;
    // Best effort: send queued lesson analytics while the session is still
    // valid. Anything left stays queued for this account's next sign-in.
    try {
      await TrackingService.instance.flush().timeout(const Duration(seconds: 3));
    } catch (_) {}
    try {
      await _client.auth.signOut();
    } finally {
      _applySession(null, recovery: false);
    }
  }

  void _requireConfigured() {
    if (!SupabaseService.isConfigured) {
      throw AuthException(SupabaseService.configurationError!);
    }
  }

  /// True when sign-in failed only because the email is not confirmed yet.
  static bool isEmailNotConfirmed(Object e) =>
      e is AuthException &&
      e.message.toLowerCase().contains('email not confirmed');

  /// A plain-language message for an auth error. The server's own wording is
  /// logged, never shown.
  static String friendlyError(Object e) {
    if (e is UsernameTakenException) {
      return 'That username is already taken. Use the username your study '
          'team gave you, or contact the care team if it is already '
          'registered.';
    }
    if (e is AuthException) {
      final m = e.message.toLowerCase();
      if (m.contains('invalid login credentials')) {
        return 'Incorrect email or password.';
      }
      if (m.contains('database error saving new user')) {
        // The sign-up trigger rejected the username (taken or invalid).
        return 'That username is already taken or not allowed. Please choose another.';
      }
      if (m.contains('banned')) {
        return 'This account has been disabled. Please contact your care team.';
      }
      if (m.contains('email not confirmed')) {
        return 'Please confirm your email before signing in.';
      }
      debugPrint('Auth error: ${e.message} (${e.statusCode})');
      if (m.contains('already registered') || m.contains('already exists')) {
        return 'An account with this email already exists. Try signing in.';
      }
      if (m.contains('rate limit') ||
          m.contains('too many') ||
          m.contains('security purposes') ||
          e.statusCode == '429') {
        return 'Too many attempts. Please wait a minute and try again.';
      }
      if (m.contains('password')) {
        return 'Please choose a different password.';
      }
      return 'Something went wrong. Please try again.';
    }
    debugPrint('Auth error: $e');
    return 'Something went wrong. Check your connection and try again.';
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
