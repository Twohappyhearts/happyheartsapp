import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

enum AuthStatus { unknown, signedOut, signedIn, passwordRecovery }

/// Outcome of a registration attempt.
enum SignUpOutcome { signedIn, confirmationRequired }

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

  Future<SignUpOutcome> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _requireConfigured();
    final res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: SupabaseService.emailRedirectTo,
      // Only display data. Roles are never taken from client metadata.
      data: {'full_name': fullName.trim()},
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

  static String friendlyError(Object e) {
    if (e is AuthException) {
      final m = e.message;
      if (m.toLowerCase().contains('invalid login credentials')) {
        return 'Incorrect email or password.';
      }
      if (m.toLowerCase().contains('email not confirmed')) {
        return 'Please confirm your email before signing in.';
      }
      return m;
    }
    return 'Something went wrong. Check your connection and try again.';
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
