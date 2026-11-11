import 'package:flutter/services.dart';

import 'core/app_export.dart';
import 'l10n/app_localizations.dart';
import 'widgets/custom_error_widget.dart';
import './services/app_language.dart';
import './services/auth_service.dart';
import './services/supabase_service.dart';
import './services/tracking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase. Failures are recorded as an actionable configuration
  // error (shown on the sign-in screen) instead of faking an authenticated state.
  await SupabaseService.initialize();
  AuthService.instance.start();
  // App language: the phone's, a saved choice, or the profile's (after sign-in).
  await AppLanguageController.instance.start();
  // Lesson engagement outbox (restores unsent events, flushes every 15s).
  TrackingService.instance.start();

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]).then((value) {
    GoRouter.optionURLReflectsImperativeAPIs = true;
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final language = AppLanguageController.instance;
    return ListenableBuilder(
      listenable: language,
      builder: (context, _) => Sizer(
        builder: (context, orientation, screenType) {
          return MaterialApp.router(
            title: 'HappyHearts',
            // 8 languages (lib/l10n). The controller already picked the right
            // one, including the English fallback, so use it as is.
            locale: language.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            localeResolutionCallback: (_, __) => language.locale,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            // Follow the phone's text size, from 100% up to 140%. Larger sizes
            // would break the fixed-height cards; smaller ones hurt legibility.
            builder: (context, child) => MediaQuery.withClampedTextScaling(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.4,
              child: child!,
            ),
            debugShowCheckedModeBanner: false,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
