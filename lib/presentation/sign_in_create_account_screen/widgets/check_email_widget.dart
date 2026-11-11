import 'package:flutter/material.dart';

import '../../../services/app_language.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';

/// Shown after registration (or an unconfirmed sign-in) when no session exists.
class CheckEmailWidget extends StatefulWidget {
  final String email;
  final VoidCallback onBackToSignIn;

  const CheckEmailWidget({
    required this.email,
    required this.onBackToSignIn,
    super.key,
  });

  @override
  State<CheckEmailWidget> createState() => _CheckEmailWidgetState();
}

class _CheckEmailWidgetState extends State<CheckEmailWidget> {
  bool _isSending = false;
  String? _message;
  bool _isError = false;

  Future<void> _resend() async {
    setState(() {
      _isSending = true;
      _message = null;
    });
    try {
      await AuthService.instance.resendConfirmation(widget.email);
      if (!mounted) return;
      setState(() {
        _isError = false;
        _message = context.l10n.checkEmailResent;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _message = AuthService.friendlyError(e);
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppTheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_unread_outlined,
              color: AppTheme.primary,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.checkEmailTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.checkEmailBody(widget.email),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textMedium,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        if (_message != null) ...[
          Text(
            _message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _isError ? AppTheme.errorColor : AppTheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: _isSending ? null : _resend,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.checkEmailResend),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: widget.onBackToSignIn,
          child: Text(l10n.backToSignIn),
        ),
      ],
    );
  }
}
