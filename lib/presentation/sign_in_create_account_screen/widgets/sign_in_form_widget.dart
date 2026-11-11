import 'package:flutter/material.dart';

import '../../../services/app_language.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';

class SignInFormWidget extends StatefulWidget {
  final ValueChanged<String> onForgotPassword;
  final ValueChanged<String> onEmailNotConfirmed;

  const SignInFormWidget({
    required this.onForgotPassword,
    required this.onEmailNotConfirmed,
    super.key,
  });

  @override
  State<SignInFormWidget> createState() => _SignInFormWidgetState();
}

class _SignInFormWidgetState extends State<SignInFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // On success the router redirects (AuthService notifies); we do not
      // navigate manually, so an invalid credential can never enter the app.
      await AuthService.instance.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (e) {
      if (!mounted) return;
      if (AuthService.isEmailNotConfirmed(e)) {
        widget.onEmailNotConfirmed(_emailController.text.trim());
        return;
      }
      setState(() => _error = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.signInWelcome,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.signInSubtitle,
            style: const TextStyle(fontSize: 14, color: AppTheme.textMedium),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: l10n.fieldEmail,
              hintText: l10n.fieldEmailHint,
              prefixIcon: const Icon(
                Icons.mail_outline_rounded,
                color: AppTheme.textLight,
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return l10n.validationEmailRequired;
              }
              if (!v.contains('@')) return l10n.validationEmailInvalid;
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            obscureText: !_passwordVisible,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: l10n.fieldPassword,
              hintText: l10n.fieldPasswordHint,
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.textLight,
              ),
              suffixIcon: IconButton(
                tooltip: _passwordVisible
                    ? l10n.hidePassword
                    : l10n.showPassword,
                icon: Icon(
                  _passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textLight,
                ),
                onPressed: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return l10n.validationPasswordRequired;
              }
              return null;
            },
            onFieldSubmitted: (_) => _isLoading ? null : _handleSignIn(),
          ),
          const SizedBox(height: 8),

          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () =>
                  widget.onForgotPassword(_emailController.text.trim()),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.signInForgot,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(fontSize: 13, color: AppTheme.errorColor),
            ),
          ],
          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.authTabSignIn,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
