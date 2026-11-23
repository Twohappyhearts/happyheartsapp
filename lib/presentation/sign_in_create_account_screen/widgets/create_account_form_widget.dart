import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/agent_config.dart';
import '../../../services/app_language.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/legal_links.dart';

class CreateAccountFormWidget extends StatefulWidget {
  /// Called when registration succeeded but no session exists yet because
  /// email confirmation is enabled in Supabase.
  final ValueChanged<String> onConfirmationRequired;

  const CreateAccountFormWidget({
    required this.onConfirmationRequired,
    super.key,
  });

  @override
  State<CreateAccountFormWidget> createState() =>
      _CreateAccountFormWidgetState();
}

class _CreateAccountFormWidgetState extends State<CreateAccountFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  String? _error;
  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => openLegalDocument(context, LegalDocument.terms);
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => openLegalDocument(context, LegalDocument.privacy);

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.createAgreeRequired)));
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final email = _emailController.text.trim();
      final outcome = await AuthService.instance.signUp(
        fullName: _nameController.text,
        username: _usernameController.text,
        phone: _phoneController.text,
        email: email,
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (outcome == SignUpOutcome.confirmationRequired) {
        widget.onConfirmationRequired(email);
      }
      // SignUpOutcome.signedIn: router redirect enters the app.
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// "I agree to the Terms of Use and Privacy Policy", where the two document
  /// names open the documents. The sentence comes from the translations with
  /// markers in place of the names, so word order can differ per language.
  List<InlineSpan> _agreeSpans(AppLocalizations l10n) {
    const termsMark = '\u0001', privacyMark = '\u0002';
    const linkStyle = TextStyle(
      color: AppTheme.primary,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
      decorationColor: AppTheme.primary,
    );
    final spans = <InlineSpan>[];
    final sentence = l10n.createAgree(termsMark, privacyMark);
    final buffer = StringBuffer();
    void flush() {
      if (buffer.isEmpty) return;
      spans.add(TextSpan(text: buffer.toString()));
      buffer.clear();
    }

    for (final ch in sentence.split('')) {
      if (ch == termsMark || ch == privacyMark) {
        flush();
        final terms = ch == termsMark;
        spans.add(
          TextSpan(
            text: terms ? l10n.legalTerms : l10n.legalPrivacy,
            style: linkStyle,
            recognizer: terms ? _termsTap : _privacyTap,
            semanticsLabel: terms ? l10n.legalTerms : l10n.legalPrivacy,
          ),
        );
      } else {
        buffer.write(ch);
      }
    }
    flush();
    return spans;
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
            l10n.createTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.createSubtitle,
            style: const TextStyle(fontSize: 14, color: AppTheme.textMedium),
          ),
          const SizedBox(height: 24),

          TextFormField(
            // Tapping anywhere outside the field closes the keyboard.
            onTapOutside: (_) =>
                FocusManager.instance.primaryFocus?.unfocus(),
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.fieldFullName,
              hintText: l10n.fieldFullNameHint,
              prefixIcon: const Icon(
                Icons.person_outline_rounded,
                color: AppTheme.textLight,
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return l10n.validationNameRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            // Tapping anywhere outside the field closes the keyboard.
            onTapOutside: (_) =>
                FocusManager.instance.primaryFocus?.unfocus(),
            controller: _usernameController,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 20,
            decoration: InputDecoration(
              labelText: l10n.fieldUsername,
              hintText: l10n.fieldUsernameHint,
              helperText: l10n.fieldUsernameHelper,
              helperMaxLines: 4,
              counterText: '',
              prefixIcon: const Icon(
                Icons.badge_outlined,
                color: AppTheme.textLight,
              ),
            ),
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return l10n.validationUsernameRequired;
              if (!RegExp(r'^[A-Za-z0-9]{3,20}$').hasMatch(t)) {
                return l10n.validationUsernameFormat;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            // Tapping anywhere outside the field closes the keyboard.
            onTapOutside: (_) =>
                FocusManager.instance.primaryFocus?.unfocus(),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: InputDecoration(
              labelText: l10n.fieldPhone,
              hintText: l10n.fieldPhoneHint,
              prefixIcon: const Icon(
                Icons.phone_outlined,
                color: AppTheme.textLight,
              ),
            ),
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return l10n.validationPhoneRequired;
              final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
              if (!RegExp(r'^\+?[0-9 ().-]+$').hasMatch(t) ||
                  digits.length < 7 ||
                  digits.length > 15) {
                return l10n.validationPhoneInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            // Tapping anywhere outside the field closes the keyboard.
            onTapOutside: (_) =>
                FocusManager.instance.primaryFocus?.unfocus(),
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
          const SizedBox(height: 16),

          TextFormField(
            // Tapping anywhere outside the field closes the keyboard.
            onTapOutside: (_) =>
                FocusManager.instance.primaryFocus?.unfocus(),
            controller: _passwordController,
            obscureText: !_passwordVisible,
            decoration: InputDecoration(
              labelText: l10n.fieldPassword,
              hintText: l10n.fieldCreatePasswordHint,
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
                return l10n.validationNewPasswordRequired;
              }
              if (v.length < 8) return l10n.validationPasswordMin8;
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            // Tapping anywhere outside the field closes the keyboard.
            onTapOutside: (_) =>
                FocusManager.instance.primaryFocus?.unfocus(),
            controller: _confirmController,
            obscureText: !_confirmVisible,
            decoration: InputDecoration(
              labelText: l10n.fieldConfirmPassword,
              hintText: l10n.fieldConfirmPasswordHint,
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.textLight,
              ),
              suffixIcon: IconButton(
                tooltip: _confirmVisible
                    ? l10n.hidePassword
                    : l10n.showPassword,
                icon: Icon(
                  _confirmVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textLight,
                ),
                onPressed: () =>
                    setState(() => _confirmVisible = !_confirmVisible),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.validationConfirmRequired;
              if (v != _passwordController.text) {
                return l10n.validationPasswordsMismatch;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _agreeToTerms,
                  onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
                  activeColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMedium,
                      height: 1.4,
                    ),
                    children: _agreeSpans(l10n),
                  ),
                ),
              ),
            ],
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
              onPressed: _isLoading ? null : _handleCreateAccount,
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
                      l10n.authTabCreateAccount,
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
