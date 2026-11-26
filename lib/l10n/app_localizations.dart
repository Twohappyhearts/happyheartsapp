import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('ko'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  ///
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  ///
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  ///
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  ///
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  ///
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  ///
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  ///
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  ///
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  ///
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Check your connection and try again.'**
  String get errorConnection;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your connection and try again.'**
  String get errorServerUnreachable;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not open this link.'**
  String get couldNotOpenLink;

  ///
  ///
  /// In en, this message translates to:
  /// **'Request sent. A team member will follow up with you.'**
  String get requestSent;

  ///
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  ///
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  ///
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get statusAvailable;

  ///
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get statusNotStarted;

  ///
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  ///
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  ///
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String dateTodayAt(String time);

  ///
  ///
  /// In en, this message translates to:
  /// **'Yesterday, {time}'**
  String dateYesterdayAt(String time);

  ///
  ///
  /// In en, this message translates to:
  /// **'{date}, {time}'**
  String dateAt(String date, String time);

  /// Estimated length of a lesson.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(int minutes);

  /// Time spent, under an hour (short).
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String timeMinutes(int minutes);

  /// Time spent, an hour or more (short).
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String timeHoursMinutes(int hours, int minutes);

  /// Screen reader label of a link.
  ///
  /// In en, this message translates to:
  /// **'Link: {text}'**
  String linkSemantic(String text);

  ///
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// Picker option: follow the phone language.
  ///
  /// In en, this message translates to:
  /// **'Phone language'**
  String get languagePhone;

  ///
  ///
  /// In en, this message translates to:
  /// **'Same as your phone ({language})'**
  String languagePhoneDetail(String language);

  ///
  ///
  /// In en, this message translates to:
  /// **'Choose a language'**
  String get languagePickerTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Language: {language}. Tap to change.'**
  String languageButtonSemantic(String language);

  ///
  ///
  /// In en, this message translates to:
  /// **'Your personal health education companion'**
  String get authTagline;

  ///
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authTabSignIn;

  ///
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authTabCreateAccount;

  ///
  ///
  /// In en, this message translates to:
  /// **'Welcome back 👋'**
  String get signInWelcome;

  ///
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your health journey'**
  String get signInSubtitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get fieldEmail;

  ///
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get fieldEmailHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get validationEmailRequired;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get validationEmailInvalid;

  ///
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  ///
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get fieldPasswordHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get validationPasswordRequired;

  ///
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  ///
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  ///
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get signInForgot;

  ///
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Start your health education journey today'**
  String get createSubtitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fieldFullName;

  ///
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fieldFullNameHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get validationNameRequired;

  ///
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get fieldUsername;

  ///
  ///
  /// In en, this message translates to:
  /// **'The username your study team gave you'**
  String get fieldUsernameHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'Use the username your study team gave you. It links your surveys to your account and can’t be changed later.'**
  String get fieldUsernameHelper;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please enter your username'**
  String get validationUsernameRequired;

  ///
  ///
  /// In en, this message translates to:
  /// **'Use 3–20 letters or numbers (no spaces or symbols)'**
  String get validationUsernameFormat;

  ///
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get fieldPhone;

  ///
  ///
  /// In en, this message translates to:
  /// **'e.g. (949) 555-0100'**
  String get fieldPhoneHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get validationPhoneRequired;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get validationPhoneInvalid;

  ///
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get fieldCreatePasswordHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get validationNewPasswordRequired;

  ///
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get validationPasswordMin8;

  ///
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get fieldConfirmPassword;

  ///
  ///
  /// In en, this message translates to:
  /// **'Type your password again'**
  String get fieldConfirmPasswordHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get validationConfirmRequired;

  ///
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordsMismatch;

  ///
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get legalTerms;

  ///
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalPrivacy;

  /// Sign-up check box. {terms} and {privacy} are the links legalTerms and legalPrivacy.
  ///
  /// In en, this message translates to:
  /// **'I agree to the {terms} and {privacy}'**
  String createAgree(String terms, String privacy);

  ///
  ///
  /// In en, this message translates to:
  /// **'Please agree to the Terms of Use and Privacy Policy'**
  String get createAgreeRequired;

  ///
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get authErrorCredentials;

  ///
  ///
  /// In en, this message translates to:
  /// **'That username is already taken or not allowed. Please choose another.'**
  String get authErrorUsernameRejected;

  ///
  ///
  /// In en, this message translates to:
  /// **'That username is already taken. Use the username your study team gave you, or contact the care team if it is already registered.'**
  String get authErrorUsernameTaken;

  ///
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled. Please contact your care team.'**
  String get authErrorDisabled;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email before signing in.'**
  String get authErrorEmailNotConfirmed;

  ///
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Try signing in.'**
  String get authErrorEmailExists;

  ///
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a minute and try again.'**
  String get authErrorRateLimited;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please choose a different password.'**
  String get authErrorPassword;

  ///
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkEmailTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'We sent a confirmation link to\n{email}\nOpen it on this device to finish creating your account.'**
  String checkEmailBody(String email);

  ///
  ///
  /// In en, this message translates to:
  /// **'Confirmation email sent again.'**
  String get checkEmailResent;

  ///
  ///
  /// In en, this message translates to:
  /// **'Resend confirmation email'**
  String get checkEmailResend;

  ///
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  ///
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send you a reset link.'**
  String get forgotIntro;

  ///
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, a reset link is on its way. Open it on this device.'**
  String forgotSent(String email);

  ///
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get forgotSend;

  ///
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get resetTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get passwordMinShort;

  ///
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get fieldNewPassword;

  ///
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get fieldConfirmNewPassword;

  ///
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get resetButton;

  ///
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get gateTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Your care team created this account with a temporary password. Please choose your own to continue.'**
  String get gateBody;

  ///
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters with an uppercase letter, a lowercase letter, and a number.'**
  String get gateRule;

  ///
  ///
  /// In en, this message translates to:
  /// **'Include an uppercase letter, a lowercase letter, and a number.'**
  String get gateErrorMix;

  ///
  ///
  /// In en, this message translates to:
  /// **'Password updated. Welcome!'**
  String get gateSuccess;

  ///
  ///
  /// In en, this message translates to:
  /// **'Choose a password different from the temporary one.'**
  String get gateErrorSame;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not update your password. Check your connection.'**
  String get gateErrorFailed;

  ///
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get gateSave;

  ///
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get menuOpen;

  ///
  ///
  /// In en, this message translates to:
  /// **'Holistic Assessments'**
  String get menuAssessments;

  ///
  ///
  /// In en, this message translates to:
  /// **'Questionnaires from your care team'**
  String get menuAssessmentsSubtitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'I need assistance'**
  String get menuAssistance;

  ///
  ///
  /// In en, this message translates to:
  /// **'Ask your care team for help'**
  String get menuAssistanceSubtitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'My help requests'**
  String get menuMyRequests;

  ///
  ///
  /// In en, this message translates to:
  /// **'See the status of what you sent'**
  String get menuMyRequestsSubtitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'In an emergency, call 911.'**
  String get menuEmergency;

  ///
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get navEducation;

  ///
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get navResources;

  ///
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  ///
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  ///
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  ///
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get crashTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please restart the app. If this keeps happening, contact the research team.'**
  String get crashBody;

  ///
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGoodMorning;

  ///
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGoodAfternoon;

  ///
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGoodEvening;

  ///
  ///
  /// In en, this message translates to:
  /// **'Hi 👋'**
  String get homeHi;

  ///
  ///
  /// In en, this message translates to:
  /// **'Hi, {name} 👋'**
  String homeHiName(String name);

  ///
  ///
  /// In en, this message translates to:
  /// **'Your Health\nEducation Hub'**
  String get homeTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Search lessons, topics...'**
  String get homeSearchHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get homeCategoryAll;

  ///
  ///
  /// In en, this message translates to:
  /// **'No lessons are available yet. Check back soon.'**
  String get homeNoLessons;

  ///
  ///
  /// In en, this message translates to:
  /// **'No lessons match your search.'**
  String get homeNoMatches;

  ///
  ///
  /// In en, this message translates to:
  /// **'Your progress'**
  String get progressCardTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} lessons'**
  String progressCardLessons(int completed, int total);

  ///
  ///
  /// In en, this message translates to:
  /// **'Let\'s get started!'**
  String get progressCardStart;

  ///
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete — you\'re doing great!'**
  String progressCardGreat(int percent);

  ///
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete — keep going!'**
  String progressCardKeepGoing(int percent);

  ///
  ///
  /// In en, this message translates to:
  /// **'100% complete — amazing work!'**
  String get progressCardDone;

  ///
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get lessonHeader;

  ///
  ///
  /// In en, this message translates to:
  /// **'No lessons are available yet.'**
  String get lessonNoLessonsShort;

  ///
  ///
  /// In en, this message translates to:
  /// **'No lesson selected.'**
  String get lessonNoneSelected;

  ///
  ///
  /// In en, this message translates to:
  /// **'Lesson marked as completed. Great job!'**
  String get lessonMarked;

  ///
  ///
  /// In en, this message translates to:
  /// **'Lesson completed'**
  String get lessonCompletedTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Finished this lesson?'**
  String get lessonFinishPrompt;

  ///
  ///
  /// In en, this message translates to:
  /// **'Great job! You can come back and review it any time.'**
  String get lessonCompletedBody;

  ///
  ///
  /// In en, this message translates to:
  /// **'Mark it as completed to keep track of your progress.'**
  String get lessonFinishBody;

  ///
  ///
  /// In en, this message translates to:
  /// **'Mark as completed'**
  String get lessonMarkButton;

  /// How many parts the lesson has (video, notes, quiz, ...).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 section} other{{count} sections}}'**
  String lessonSections(int count);

  ///
  ///
  /// In en, this message translates to:
  /// **'References'**
  String get refTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Lesson video'**
  String get refLessonVideo;

  ///
  ///
  /// In en, this message translates to:
  /// **'Lesson audio'**
  String get refLessonAudio;

  ///
  ///
  /// In en, this message translates to:
  /// **'Lesson notes'**
  String get scriptTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get scriptReadMore;

  ///
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get scriptShowLess;

  ///
  ///
  /// In en, this message translates to:
  /// **'Infographic'**
  String get infoTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Lesson infographic'**
  String get infoCardTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Visual summary of {title}'**
  String infoCardSubtitle(String title);

  ///
  ///
  /// In en, this message translates to:
  /// **'Infographic for {title}'**
  String infoSemantic(String title);

  ///
  ///
  /// In en, this message translates to:
  /// **'Tap the image to view full screen and zoom'**
  String get infoTapHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'View full screen'**
  String get imageOpenFullscreen;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not load the image.'**
  String get imageLoadFailed;

  ///
  ///
  /// In en, this message translates to:
  /// **'Close full screen view'**
  String get imageCloseFullscreen;

  ///
  ///
  /// In en, this message translates to:
  /// **'Pinch or double-tap to zoom'**
  String get imageZoomHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'Video lesson'**
  String get videoTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Playing video'**
  String get videoPlaying;

  ///
  ///
  /// In en, this message translates to:
  /// **'Tap to play video'**
  String get videoTapToPlay;

  ///
  ///
  /// In en, this message translates to:
  /// **'YouTube video'**
  String get videoYouTube;

  ///
  ///
  /// In en, this message translates to:
  /// **'Audio lesson'**
  String get audioTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Open audio'**
  String get audioOpen;

  ///
  ///
  /// In en, this message translates to:
  /// **'Listen to this lesson'**
  String get audioListen;

  ///
  ///
  /// In en, this message translates to:
  /// **'Knowledge game'**
  String get kahootTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Nice work! Quiz marked as finished.'**
  String get kahootMarked;

  ///
  ///
  /// In en, this message translates to:
  /// **'Username copied.'**
  String get kahootCopied;

  ///
  ///
  /// In en, this message translates to:
  /// **'Copy username'**
  String get kahootCopyTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Your Kahoot username'**
  String get kahootUsernameLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Use this username when the Kahoot game asks for a nickname'**
  String get kahootUsernameHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'Test what you\'ve learned with an interactive Kahoot! game'**
  String get kahootIntro;

  ///
  ///
  /// In en, this message translates to:
  /// **'⏱ ~5 min'**
  String get kahootBadgeTime;

  ///
  ///
  /// In en, this message translates to:
  /// **'✨ Interactive'**
  String get kahootBadgeInteractive;

  ///
  ///
  /// In en, this message translates to:
  /// **'🎉 Fun!'**
  String get kahootBadgeFun;

  ///
  ///
  /// In en, this message translates to:
  /// **'Start Kahoot! game'**
  String get kahootStart;

  ///
  ///
  /// In en, this message translates to:
  /// **'The game opens below when you tap the button above'**
  String get kahootEmbedHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'Quiz finished'**
  String get kahootFinished;

  ///
  ///
  /// In en, this message translates to:
  /// **'I finished the quiz'**
  String get kahootIFinished;

  ///
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get chatAiTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Automated answers, 24/7'**
  String get chatAiSubtitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Research Team'**
  String get chatTeamTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Happy Hearts Study'**
  String get chatTeamSubtitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Care Team'**
  String get chatTabTeam;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please sign in to use the AI assistant.'**
  String get chatSignInAi;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please sign in to use chat.'**
  String get chatSignIn;

  ///
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get chatNeedHelp;

  ///
  ///
  /// In en, this message translates to:
  /// **'View my requests'**
  String get chatViewRequests;

  ///
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get chatEmptyTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Send a message to the Happy Hearts research team. We\'re here to help with any questions about your study.'**
  String get chatEmptyBody;

  ///
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get chatNotSent;

  ///
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatDelete;

  ///
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get chatEdit;

  ///
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatCopy;

  ///
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get chatEdited;

  ///
  ///
  /// In en, this message translates to:
  /// **'Editing message'**
  String get chatEditingMessage;

  ///
  ///
  /// In en, this message translates to:
  /// **'Delete this message?'**
  String get chatDeleteConfirm;

  ///
  ///
  /// In en, this message translates to:
  /// **'You deleted this message'**
  String get chatYouDeleted;

  ///
  ///
  /// In en, this message translates to:
  /// **'This message was deleted'**
  String get chatMessageDeleted;

  ///
  ///
  /// In en, this message translates to:
  /// **'Removed by the research team'**
  String get chatRemovedByTeam;

  ///
  ///
  /// In en, this message translates to:
  /// **'Messages can only be edited within 15 minutes.'**
  String get chatEditTooLate;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not edit the message.'**
  String get chatEditFailed;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not delete the message.'**
  String get chatDeleteFailed;

  ///
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get chatSending;

  ///
  ///
  /// In en, this message translates to:
  /// **'Message the research team...'**
  String get chatInputHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  ///
  ///
  /// In en, this message translates to:
  /// **'This account cannot use patient chat. Please sign in with a patient account.'**
  String get chatErrorWrongAccount;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not open your conversation. Please try again.'**
  String get chatErrorOpen;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not load messages. Check your connection and try again.'**
  String get chatErrorLoad;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Your message was kept. Tap Retry.'**
  String get chatErrorKept;

  ///
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to send messages in this conversation.'**
  String get chatErrorNoPermission;

  ///
  ///
  /// In en, this message translates to:
  /// **'Messages must be 1–4000 characters.'**
  String get chatErrorLength;

  ///
  ///
  /// In en, this message translates to:
  /// **'Message not sent. Please try again.'**
  String get chatErrorNotSent;

  ///
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading your conversation.'**
  String get chatErrorGeneric;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not load the AI assistant. Check your connection.'**
  String get aiErrorConnection;

  ///
  ///
  /// In en, this message translates to:
  /// **'The AI assistant is unavailable right now.'**
  String get aiErrorUnavailable;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not start the AI assistant.'**
  String get aiErrorStart;

  ///
  ///
  /// In en, this message translates to:
  /// **'The AI assistant is taking too long to load.'**
  String get aiErrorTimeout;

  ///
  ///
  /// In en, this message translates to:
  /// **'The AI assistant is available in the HappyHearts iOS and Android app.'**
  String get aiWebOnly;

  ///
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get assistMyRequests;

  ///
  ///
  /// In en, this message translates to:
  /// **'Tell the research team what you need help with. A team member will follow up, usually by message in Care Team chat.'**
  String get assistIntro;

  ///
  ///
  /// In en, this message translates to:
  /// **'This is not monitored around the clock. If this is an emergency, call 911.'**
  String get assistEmergency;

  ///
  ///
  /// In en, this message translates to:
  /// **'For example: \"I have a question about my medication\" or \"The video in Session 3 won\'t play.\"'**
  String get assistHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get assistSend;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please describe what you need help with.'**
  String get assistErrorEmpty;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please keep your message under {max} characters.'**
  String assistErrorTooLong(int max);

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Your message was kept — please try again.'**
  String get assistErrorOffline;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not load your requests. Check your connection and try again.'**
  String get assistErrorLoad;

  ///
  ///
  /// In en, this message translates to:
  /// **'Only participant accounts can send assistance requests.'**
  String get assistErrorNotParticipant;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please write a message between 1 and {max} characters.'**
  String assistErrorLength(int max);

  ///
  ///
  /// In en, this message translates to:
  /// **'You have sent several requests recently. The team will get back to you soon. If it is urgent, call your care team. In an emergency, call 911.'**
  String get assistErrorRateLimited;

  ///
  ///
  /// In en, this message translates to:
  /// **'Your request was not sent. Your message was kept — please try again.'**
  String get assistErrorNotSent;

  ///
  ///
  /// In en, this message translates to:
  /// **'My assistance requests'**
  String get requestsTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get requestsNew;

  ///
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get requestsEmptyTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'When you need help from the research team, send a request and you can follow its status here.'**
  String get requestsEmptyBody;

  ///
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get requestStatusSent;

  ///
  ///
  /// In en, this message translates to:
  /// **'Seen by the team'**
  String get requestStatusSeen;

  ///
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get requestStatusResolved;

  ///
  ///
  /// In en, this message translates to:
  /// **'Waiting for a team member to review it.'**
  String get requestWaiting;

  ///
  ///
  /// In en, this message translates to:
  /// **'A team member is following up.'**
  String get requestFollowing;

  ///
  ///
  /// In en, this message translates to:
  /// **'A team member is following up ({time}).'**
  String requestFollowingSince(String time);

  ///
  ///
  /// In en, this message translates to:
  /// **'Marked resolved.'**
  String get requestResolved;

  ///
  ///
  /// In en, this message translates to:
  /// **'Marked resolved ({time}).'**
  String requestResolvedSince(String time);

  ///
  ///
  /// In en, this message translates to:
  /// **'Questionnaires from your care team.'**
  String get assessSubtitleSurvey;

  ///
  ///
  /// In en, this message translates to:
  /// **'Track your mental and physical health with these validated screening tools.'**
  String get assessSubtitleResources;

  ///
  ///
  /// In en, this message translates to:
  /// **'No holistic assessments right now. Your care team will add them here.'**
  String get assessEmptySurvey;

  ///
  ///
  /// In en, this message translates to:
  /// **'No resources right now. Your care team will add them here.'**
  String get assessEmptyResources;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not load your username. Please try again.'**
  String get assessUsernameError;

  ///
  ///
  /// In en, this message translates to:
  /// **'Last completed {date}'**
  String assessLastCompleted(String date);

  ///
  ///
  /// In en, this message translates to:
  /// **'Start assessment'**
  String get assessStart;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not load surveys. Check your connection and try again.'**
  String get surveyErrorLoad;

  ///
  ///
  /// In en, this message translates to:
  /// **'Your answers were submitted, but the app could not mark the survey as completed.'**
  String get surveyRecordFailed;

  ///
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get surveyThanks;

  ///
  ///
  /// In en, this message translates to:
  /// **'Your responses were submitted. You can see this survey in your Progress calendar.'**
  String get surveyThanksBody;

  ///
  ///
  /// In en, this message translates to:
  /// **'Loading survey...'**
  String get surveyLoading;

  ///
  ///
  /// In en, this message translates to:
  /// **'Unable to load survey'**
  String get surveyLoadFailedTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get surveyLoadFailedBody;

  ///
  ///
  /// In en, this message translates to:
  /// **'Track your learning journey and celebrate milestones.'**
  String get progressSubtitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Activity calendar'**
  String get progressCalendar;

  ///
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get progressBreakdown;

  ///
  ///
  /// In en, this message translates to:
  /// **'Completed: {title}'**
  String activityCompleted(String title);

  ///
  ///
  /// In en, this message translates to:
  /// **'Finished quiz: {title}'**
  String activityQuizFinished(String title);

  ///
  ///
  /// In en, this message translates to:
  /// **'Survey ({code})'**
  String activitySurveyFallback(String code);

  ///
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calPrevMonth;

  ///
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calNextMonth;

  ///
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get legendLesson;

  ///
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get legendQuiz;

  ///
  ///
  /// In en, this message translates to:
  /// **'Survey'**
  String get legendSurvey;

  /// Screen reader text for a calendar day.
  ///
  /// In en, this message translates to:
  /// **'lesson completed'**
  String get calLessonDone;

  /// Screen reader text for a calendar day.
  ///
  /// In en, this message translates to:
  /// **'quiz finished'**
  String get calQuizDone;

  /// Screen reader text for a calendar day.
  ///
  /// In en, this message translates to:
  /// **'survey completed'**
  String get calSurveyDone;

  ///
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get activityRecent;

  ///
  ///
  /// In en, this message translates to:
  /// **'Activity on {date}'**
  String activityOnDay(String date);

  ///
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get activityShowAll;

  ///
  ///
  /// In en, this message translates to:
  /// **'Complete a lesson, quiz, or survey and it will show up here.'**
  String get activityEmpty;

  ///
  ///
  /// In en, this message translates to:
  /// **'Nothing completed on this day.'**
  String get activityEmptyDay;

  ///
  ///
  /// In en, this message translates to:
  /// **'Overall completion'**
  String get overallTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} lessons'**
  String overallCount(int completed, int total);

  ///
  ///
  /// In en, this message translates to:
  /// **'🎉 All lessons complete!'**
  String get overallAllDone;

  ///
  ///
  /// In en, this message translates to:
  /// **'Keep going — you\'re making great progress!'**
  String get overallKeepGoing;

  ///
  ///
  /// In en, this message translates to:
  /// **'Start your first lesson to begin.'**
  String get overallStart;

  ///
  ///
  /// In en, this message translates to:
  /// **'Time spent'**
  String get statTimeSpent;

  ///
  ///
  /// In en, this message translates to:
  /// **'{time} spent'**
  String timeSpentSuffix(String time);

  ///
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get profileSignOutConfirm;

  ///
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to {email}'**
  String profileResetSent(String email);

  ///
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccount;

  ///
  ///
  /// In en, this message translates to:
  /// **'Change password (send reset email)'**
  String get profileChangePassword;

  ///
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profilePreferences;

  ///
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileAbout;

  ///
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get profileVersion;

  ///
  ///
  /// In en, this message translates to:
  /// **'Your profile is not available.'**
  String get profileNotAvailable;

  ///
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get profileEditName;

  ///
  ///
  /// In en, this message translates to:
  /// **'Learning summary'**
  String get profileLearningSummary;

  ///
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get profileStatComplete;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not load your progress. Tap to retry.'**
  String get profileProgressFailed;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please sign in.'**
  String get profileErrorSignIn;

  ///
  ///
  /// In en, this message translates to:
  /// **'Session changed. Please try again.'**
  String get profileErrorSessionChanged;

  ///
  ///
  /// In en, this message translates to:
  /// **'Your profile could not be found. Pull down to retry; if this keeps happening, contact the research team.'**
  String get profileErrorMissing;

  ///
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view this profile.'**
  String get profileErrorPermission;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile. Check your connection and try again.'**
  String get profileErrorLoad;

  ///
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty.'**
  String get profileErrorNameEmpty;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not save your name. Check your connection and try again.'**
  String get profileErrorSaveName;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not load lessons. Check your connection and try again.'**
  String get contentErrorLessons;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not load your progress. Check your connection and try again.'**
  String get contentErrorProgress;

  /// Lesson section with images and PDF files uploaded by the study team.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get materialsTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'PDF document'**
  String get materialsPdf;

  ///
  ///
  /// In en, this message translates to:
  /// **'PDF · {size}'**
  String materialsPdfSize(String size);

  ///
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String fileSizeMb(String size);

  ///
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String fileSizeKb(String size);

  /// Screen reader label of an image thumbnail.
  ///
  /// In en, this message translates to:
  /// **'Open image: {name}'**
  String materialsOpenImage(String name);

  /// Screen reader label of a PDF row.
  ///
  /// In en, this message translates to:
  /// **'Open PDF: {name}'**
  String materialsOpenPdf(String name);

  /// Between items of a list, e.g. language names.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  ///
  ///
  /// In en, this message translates to:
  /// **'Check the language of your message'**
  String get msgLangTitle;

  /// {languages}: the accepted language names, each in its own language, e.g. "English, Español".
  ///
  /// In en, this message translates to:
  /// **'The research team only reads these languages: {languages}. They may not be able to understand your message.'**
  String msgLangBody(String languages);

  ///
  ///
  /// In en, this message translates to:
  /// **'Send anyway'**
  String get msgLangSendAnyway;

  ///
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get msgLangEdit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'en',
    'es',
    'fa',
    'ko',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fa':
      return AppLocalizationsFa();
    case 'ko':
      return AppLocalizationsKo();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
