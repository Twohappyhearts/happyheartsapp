import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/education_hub_screen/education_hub_screen.dart';
import '../presentation/lesson_detail_screen/lesson_detail_screen.dart';
import '../presentation/assessments_screen/assessments_screen.dart';
import '../presentation/progress_screen/progress_screen.dart';
import '../presentation/chat_screen/chat_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/sign_in_create_account_screen/sign_in_create_account_screen.dart';
import '../presentation/sign_in_create_account_screen/reset_password_screen.dart';
import '../services/auth_service.dart';
import '../widgets/app_scaffold.dart';

class AppRoutes {
  static const String initial = '/';
  static const String signInCreateAccount = '/sign-in-create-account-screen';
  static const String resetPassword = '/reset-password-screen';
  static const String loginCallback = '/login-callback';
  static const String educationHub = '/education-hub-screen';
  static const String lessonDetail = '/lesson-detail-screen';
  static const String assessments = '/assessments-screen';
  static const String progress = '/progress-screen';
  static const String chat = '/chat-screen';
  static const String profile = '/profile-screen';
}

/// Auth-aware redirect. Authenticated screens require a valid session.
String? _authRedirect(BuildContext context, GoRouterState state) {
  final auth = AuthService.instance;
  final loc = state.matchedLocation;

  // Still restoring the session: stay on the entry route (shows a loader).
  if (auth.status == AuthStatus.unknown) {
    return loc == AppRoutes.initial ? null : AppRoutes.initial;
  }

  final isPublic =
      loc == AppRoutes.initial ||
      loc == AppRoutes.signInCreateAccount ||
      loc == AppRoutes.loginCallback;

  switch (auth.status) {
    case AuthStatus.passwordRecovery:
      return loc == AppRoutes.resetPassword ? null : AppRoutes.resetPassword;
    case AuthStatus.signedOut:
      return (loc == AppRoutes.signInCreateAccount)
          ? null
          : AppRoutes.signInCreateAccount;
    case AuthStatus.signedIn:
      if (isPublic || loc == AppRoutes.resetPassword) {
        return AppRoutes.educationHub;
      }
      return null;
    case AuthStatus.unknown:
      return null;
  }
}

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );

CustomTransitionPage<void> _slide(
  GoRouterState state,
  Widget child,
) => CustomTransitionPage(
  key: state.pageKey,
  child: child,
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.04, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: FadeTransition(opacity: animation, child: child),
    );
  },
  transitionDuration: const Duration(milliseconds: 280),
);

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  refreshListenable: AuthService.instance,
  redirect: _authRedirect,
  routes: [
    GoRoute(
      path: AppRoutes.initial,
      pageBuilder: (context, state) => _fade(state, const _SplashScreen()),
    ),
    // Target of the mobile deep link (io.happyhearts.app://login-callback).
    // The Supabase SDK consumes the link; this route just resolves via redirect.
    GoRoute(
      path: AppRoutes.loginCallback,
      pageBuilder: (context, state) => _fade(state, const _SplashScreen()),
    ),
    GoRoute(
      path: AppRoutes.signInCreateAccount,
      pageBuilder: (context, state) =>
          _fade(state, const SignInCreateAccountScreen()),
    ),
    GoRoute(
      path: AppRoutes.resetPassword,
      pageBuilder: (context, state) =>
          _fade(state, const ResetPasswordScreen()),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppScaffold(navigationShell: navigationShell),
      branches: [
        // Branch 0: Education
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.educationHub,
              pageBuilder: (context, state) =>
                  _slide(state, const EducationHubScreen()),
            ),
          ],
        ),
        // Branch 1: Lessons
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.lessonDetail,
              pageBuilder: (context, state) => _slide(
                state,
                LessonDetailScreen(
                  moduleData: state.extra as Map<String, dynamic>?,
                ),
              ),
            ),
          ],
        ),
        // Branch 2: Assessments
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.assessments,
              pageBuilder: (context, state) =>
                  _slide(state, const AssessmentsScreen()),
            ),
          ],
        ),
        // Branch 3: Progress
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.progress,
              pageBuilder: (context, state) =>
                  _slide(state, const ProgressScreen()),
            ),
          ],
        ),
        // Branch 4: Chat
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.chat,
              pageBuilder: (context, state) =>
                  _slide(state, const ChatScreen()),
            ),
          ],
        ),
        // Branch 5: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              pageBuilder: (context, state) =>
                  _slide(state, const ProfileScreen()),
            ),
          ],
        ),
      ],
    ),
  ],
);
