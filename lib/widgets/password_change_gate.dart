import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/app_language.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Accounts created (or reset) by staff in the dashboard start with a
/// temporary password (account_roles.must_change_password). Until the patient
/// chooses their own, this covers the whole app with a "Set a new password"
/// screen. The app underneath stays mounted.
class PasswordChangeGate extends StatefulWidget {
  final Widget child;
  const PasswordChangeGate({required this.child, super.key});

  @override
  State<PasswordChangeGate> createState() => _PasswordChangeGateState();
}

class _PasswordChangeGateState extends State<PasswordChangeGate> {
  final AuthService _auth = AuthService.instance;
  bool _mustChange = false;
  int _checkedGeneration = -1;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_check);
    _check();
  }

  @override
  void dispose() {
    _auth.removeListener(_check);
    super.dispose();
  }

  Future<void> _check() async {
    final gen = _auth.generation;
    final uid = _auth.userId;
    if (!_auth.isSignedIn || uid == null) {
      if (_mustChange && mounted) setState(() => _mustChange = false);
      return;
    }
    if (gen == _checkedGeneration) return;
    _checkedGeneration = gen;
    try {
      final row = await Supabase.instance.client
          .from('account_roles')
          .select('must_change_password')
          .eq('user_id', uid)
          .maybeSingle();
      if (!mounted || _auth.generation != gen) return;
      setState(() => _mustChange = row?['must_change_password'] == true);
    } catch (_) {
      // Offline: check again on the next identity change / app start.
      _checkedGeneration = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_mustChange)
          Positioned.fill(
            child: _ChangePasswordScreen(
              onDone: () => setState(() => _mustChange = false),
            ),
          ),
      ],
    );
  }
}

class _ChangePasswordScreen extends StatefulWidget {
  final VoidCallback onDone;
  const _ChangePasswordScreen({required this.onDone});

  @override
  State<_ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<_ChangePasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _problem(String pw) {
    final l10n = context.l10n;
    if (pw.length < 8) return l10n.passwordMinShort;
    if (!RegExp(r'[a-z]').hasMatch(pw) ||
        !RegExp(r'[A-Z]').hasMatch(pw) ||
        !RegExp(r'[0-9]').hasMatch(pw)) {
      return l10n.gateErrorMix;
    }
    return null;
  }

  Future<void> _save() async {
    final pw = _password.text;
    final problem = _problem(pw);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    if (_confirm.text != pw) {
      setState(() => _error = context.l10n.validationPasswordsMismatch);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;
      await client.auth.updateUser(UserAttributes(password: pw));
      await client.rpc('complete_password_change');
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(context.l10n.gateSuccess),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onDone();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message.toLowerCase().contains('different')
            ? context.l10n.gateErrorSame
            : AuthService.friendlyError(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = context.l10n.gateErrorFailed;
      });
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    prefixIcon: const Icon(Icons.lock_outline_rounded),
    suffixIcon: IconButton(
      tooltip: _obscure ? context.l10n.showPassword : context.l10n.hidePassword,
      icon: Icon(
        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: () => setState(() => _obscure = !_obscure),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      child: Material(
        color: AppTheme.backgroundLight,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.key_rounded,
                        color: AppTheme.primary,
                        size: 28,
                      ),
                    ),
                    Text(
                      l10n.gateTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.gateBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMedium,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      // Tapping anywhere outside the field closes the keyboard.
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: _decoration(l10n.fieldNewPassword),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      // Tapping anywhere outside the field closes the keyboard.
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      controller: _confirm,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.newPassword],
                      onSubmitted: (_) => _save(),
                      decoration: _decoration(l10n.fieldConfirmNewPassword),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.gateRule,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n.gateSave,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => AuthService.instance.signOut(),
                      child: Text(l10n.signOut),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
