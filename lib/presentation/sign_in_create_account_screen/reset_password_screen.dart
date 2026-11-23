import 'package:flutter/material.dart';

import '../../services/app_language.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// Shown when the app receives a password-recovery deep link (recovery session).
/// The router forces this screen while AuthStatus.passwordRecovery is active.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _visible = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // On success AuthService flips to signedIn and the router leaves this screen.
      await AuthService.instance.updatePassword(_passwordController.text);
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.resetTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.passwordMinShort,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      // Tapping anywhere outside the field closes the keyboard.
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      controller: _passwordController,
                      obscureText: !_visible,
                      decoration: InputDecoration(
                        labelText: l10n.fieldNewPassword,
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppTheme.textLight,
                        ),
                        suffixIcon: IconButton(
                          tooltip: _visible
                              ? l10n.hidePassword
                              : l10n.showPassword,
                          icon: Icon(
                            _visible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppTheme.textLight,
                          ),
                          onPressed: () => setState(() => _visible = !_visible),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return l10n.validationNewPasswordRequired;
                        }
                        if (v.length < 8) {
                          return l10n.validationPasswordMin8;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      // Tapping anywhere outside the field closes the keyboard.
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      controller: _confirmController,
                      obscureText: !_visible,
                      decoration: InputDecoration(
                        labelText: l10n.fieldConfirmNewPassword,
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppTheme.textLight,
                        ),
                      ),
                      validator: (v) => v != _passwordController.text
                          ? l10n.validationPasswordsMismatch
                          : null,
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
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.resetButton),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => AuthService.instance.signOut(),
                      child: Text(l10n.cancel),
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
