import 'package:flutter/material.dart';

import '../../../services/app_language.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';

/// Requests a password-reset email.
class ForgotPasswordWidget extends StatefulWidget {
  final String initialEmail;
  final VoidCallback onBack;

  const ForgotPasswordWidget({
    required this.initialEmail,
    required this.onBack,
    super.key,
  });

  @override
  State<ForgotPasswordWidget> createState() => _ForgotPasswordWidgetState();
}

class _ForgotPasswordWidgetState extends State<ForgotPasswordWidget> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _isLoading = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await AuthService.instance.requestPasswordReset(_emailController.text);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.friendlyError(e));
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
            l10n.forgotTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _sent
                ? l10n.forgotSent(_emailController.text.trim())
                : l10n.forgotIntro,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMedium,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          if (!_sent) ...[
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
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
                    : Text(l10n.forgotSend),
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onBack,
            child: Text(l10n.backToSignIn),
          ),
        ],
      ),
    );
  }
}
