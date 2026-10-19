import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import './widgets/auth_tab_toggle_widget.dart';
import './widgets/check_email_widget.dart';
import './widgets/create_account_form_widget.dart';
import './widgets/forgot_password_widget.dart';
import './widgets/sign_in_form_widget.dart';

enum _AuthView { form, checkEmail, forgotPassword }

class SignInCreateAccountScreen extends StatefulWidget {
  const SignInCreateAccountScreen({super.key});

  @override
  State<SignInCreateAccountScreen> createState() =>
      _SignInCreateAccountScreenState();
}

class _SignInCreateAccountScreenState extends State<SignInCreateAccountScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0 = Sign In, 1 = Create Account
  _AuthView _view = _AuthView.form;
  String _pendingEmail = '';
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));
    _logoController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  void _showCheckEmail(String email) {
    setState(() {
      _pendingEmail = email;
      _view = _AuthView.checkEmail;
    });
  }

  void _backToForm({int? tab}) {
    setState(() {
      if (tab != null) _selectedTab = tab;
      _view = _AuthView.form;
    });
  }

  Widget _buildBody() {
    switch (_view) {
      case _AuthView.checkEmail:
        return CheckEmailWidget(
          key: const ValueKey('check_email'),
          email: _pendingEmail,
          onBackToSignIn: () => _backToForm(tab: 0),
        );
      case _AuthView.forgotPassword:
        return ForgotPasswordWidget(
          key: const ValueKey('forgot'),
          initialEmail: _pendingEmail,
          onBack: () => _backToForm(tab: 0),
        );
      case _AuthView.form:
        return Column(
          key: const ValueKey('form'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTabToggleWidget(
              selectedIndex: _selectedTab,
              onTabChanged: (index) => setState(() => _selectedTab = index),
            ),
            const SizedBox(height: 24),
            _selectedTab == 0
                ? SignInFormWidget(
                    key: const ValueKey('sign_in'),
                    onForgotPassword: (email) => setState(() {
                      _pendingEmail = email;
                      _view = _AuthView.forgotPassword;
                    }),
                    onEmailNotConfirmed: _showCheckEmail,
                  )
                : CreateAccountFormWidget(
                    key: const ValueKey('create_account'),
                    onConfirmationRequired: _showCheckEmail,
                  ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 0 : 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 480 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) => FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(scale: _logoScale, child: child),
                    ),
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, Color(0xFF60A5FA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withAlpha(77),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'HappyHearts',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Your personal health education companion',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (!SupabaseService.isConfigured) ...[
                    _ConfigErrorBanner(
                      message: SupabaseService.configurationError!,
                    ),
                    const SizedBox(height: 16),
                  ],

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: _buildBody(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigErrorBanner extends StatelessWidget {
  final String message;
  const _ConfigErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.errorColor.withAlpha(90)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.errorColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
