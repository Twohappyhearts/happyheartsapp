// Renders the sign-in screens and the main home / lesson widgets in every app
// language at the largest text size the app allows (140%) on a small phone,
// and fails on any layout overflow. Right-to-left languages (fa, ar) are
// included. Screens that need Supabase or Google Fonts are not covered here.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happyhearts/l10n/app_localizations.dart';
import 'package:happyhearts/presentation/education_hub_screen/widgets/category_filter_widget.dart';
import 'package:happyhearts/presentation/education_hub_screen/widgets/home_app_bar_widget.dart';
import 'package:happyhearts/presentation/education_hub_screen/widgets/module_card_widget.dart';
import 'package:happyhearts/presentation/education_hub_screen/widgets/progress_card_widget.dart';
import 'package:happyhearts/presentation/lesson_detail_screen/widgets/audio_section_widget.dart';
import 'package:happyhearts/presentation/lesson_detail_screen/widgets/kahoot_section_widget.dart';
import 'package:happyhearts/presentation/lesson_detail_screen/widgets/lesson_detail_app_bar_widget.dart';
import 'package:happyhearts/presentation/lesson_detail_screen/widgets/materials_section_widget.dart';
import 'package:happyhearts/presentation/lesson_detail_screen/widgets/references_section_widget.dart';
import 'package:happyhearts/presentation/lesson_detail_screen/widgets/script_section_widget.dart';
import 'package:happyhearts/presentation/profile_screen/profile_screen.dart';
import 'package:happyhearts/presentation/progress_screen/progress_screen.dart';
import 'package:happyhearts/presentation/sign_in_create_account_screen/sign_in_create_account_screen.dart';
import 'package:happyhearts/services/app_language.dart';
import 'package:happyhearts/services/content_service.dart';

const _maxTextScale = 1.4;

Future<void> _pump(WidgetTester tester, Locale locale, Widget home) async {
  // iPhone SE-sized screen (320 x 568 points).
  tester.view.physicalSize = const Size(640, 1136);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: (_, __) => locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(_maxTextScale)),
        child: child!,
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

/// Fails with the full error (which widget overflowed) instead of just its
/// one-line summary.
void _expectNoException(WidgetTester tester) {
  final error = tester.takeException();
  if (error == null) return;
  fail(error is FlutterError ? error.toStringDeep() : '$error');
}

Map<String, dynamic> _module(String status) => {
  'id': 'm1',
  'title':
      'How to talk to your healthcare provider about blood pressure after birth',
  'category': 'Emotional Support & Resources',
  'description': 'A short lesson.',
  'durationMinutes': 12,
  'status': status,
  'imageUrl': '',
  'semanticLabel': 'Lesson',
};

/// The test font draws every glyph as a full square, which makes Latin text
/// far wider than on a phone. Use Roboto from the Flutter SDK when available
/// so widths are realistic (other scripts still fall back to squares, which
/// is close for Chinese / Korean and wider than real for Arabic / Farsi).
Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  final loader = FontLoader('Roboto');
  var any = false;
  for (final f in ['Regular', 'Medium', 'Bold']) {
    final file = File('$dir/Roboto-$f.ttf');
    if (!file.existsSync()) continue;
    final bytes = file.readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    any = true;
  }
  if (any) await loader.load();
}

void main() {
  setUpAll(_loadRoboto);

  for (final language in appLanguages) {
    final locale = language.locale;

    group('${language.code} at ${_maxTextScale}x text', () {
      testWidgets('sign in and create account', (tester) async {
        await _pump(tester, locale, const SignInCreateAccountScreen());
        _expectNoException(tester);
        expect(
          Directionality.of(tester.element(find.byType(Scaffold).first)),
          language.rtl ? TextDirection.rtl : TextDirection.ltr,
        );

        final l10n = lookupAppLocalizations(locale);
        await tester.tap(find.text(l10n.authTabCreateAccount).first);
        await tester.pumpAndSettle();
        _expectNoException(tester);
        expect(find.text(l10n.fieldUsernameHint), findsOneWidget);
      });

      testWidgets('home widgets and references', (tester) async {
        await _pump(
          tester,
          locale,
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeAppBarWidget(
                    userName: 'Maria',
                    initial: 'M',
                    onAvatarTap: () {},
                  ),
                  const SizedBox(height: 16),
                  const ProgressCardWidget(completed: 2, total: 5),
                  const SizedBox(height: 16),
                  CategoryFilterWidget(
                    categories: const ['Heart Health', 'Sleep Health'],
                    selectedCategory: 'All',
                    onCategoryChanged: (_) {},
                  ),
                  const SizedBox(height: 16),
                  for (final status in [
                    'completed',
                    'in_progress',
                    'available',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ModuleCardWidget(
                        module: _module(status),
                        animationIndex: 0,
                        onTap: () {},
                      ),
                    ),
                  const ReferencesSectionWidget(
                    references: [
                      {
                        'title': '',
                        'url': 'https://www.youtube.com/watch?v=abc123',
                        'kind': 'video',
                      },
                      {
                        'title': 'High blood pressure during pregnancy',
                        'url': 'https://www.cdc.gov/high-blood-pressure/',
                        'kind': 'link',
                      },
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        _expectNoException(tester);
      });

      testWidgets('lesson sections', (tester) async {
        await _pump(
          tester,
          locale,
          Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  LessonDetailAppBarWidget(onBack: () {}),
                  const Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          ScriptSectionWidget(
                            scriptHtml:
                                '<p>Blood pressure is the force of blood '
                                'against the walls of your arteries.</p>'
                                '<ul><li>Check it often</li></ul>',
                          ),
                          SizedBox(height: 24),
                          AudioSectionWidget(
                            audioUrl: 'https://example.org/lesson.mp3',
                            duration: '4:30',
                          ),
                          SizedBox(height: 24),
                          // PDFs only: image thumbnails need the cache
                          // plugin, which tests don't have.
                          MaterialsSectionWidget(
                            attachments: [
                              LessonAttachment(
                                name:
                                    'Blood pressure log for the first six '
                                    'weeks after birth',
                                url: 'https://example.org/log.pdf',
                                kind: 'pdf',
                                sizeBytes: 2400000,
                              ),
                              LessonAttachment(
                                name: 'Handout',
                                url: 'https://example.org/handout.pdf',
                                kind: 'pdf',
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          KahootSectionWidget(
                            kahootUrl: 'https://kahoot.it/challenge/123',
                            username: 'maria2026',
                            quizCompleted: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        _expectNoException(tester);
      });

      // Signed out in tests: both pages show their "could not load" states,
      // which still exercises headers, tiles and the language setting.
      testWidgets('profile and progress pages', (tester) async {
        await _pump(tester, locale, const ProfileScreen());
        _expectNoException(tester);
        final l10n = lookupAppLocalizations(locale);
        expect(find.text(l10n.languageTitle), findsOneWidget);

        await _pump(tester, locale, const ProgressScreen());
        _expectNoException(tester);
      });
    });
  }

  test('phone locales map to the app languages', () {
    String? code(Locale l) => appLanguageCodeForLocale(l);
    expect(code(const Locale('es', 'MX')), 'es');
    expect(code(const Locale('fr')), isNull);
    expect(
      code(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')),
      'zh-Hant',
    );
    expect(code(const Locale('zh', 'TW')), 'zh-Hant');
    expect(code(const Locale('zh', 'HK')), 'zh-Hant');
    expect(code(const Locale('zh', 'MO')), 'zh-Hant');
    expect(code(const Locale('zh', 'CN')), 'zh-Hans');
    expect(code(const Locale('zh')), 'zh-Hans');
    expect(
      code(
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'SG',
        ),
      ),
      'zh-Hans',
    );
  });

  test('Simplified and Traditional Chinese use different texts', () {
    final hans = lookupAppLocalizations(appLanguageFor('zh-Hans')!.locale);
    final hant = lookupAppLocalizations(appLanguageFor('zh-Hant')!.locale);
    expect(hans.authTabSignIn, '登录');
    expect(hant.authTabSignIn, '登入');
  });
}
