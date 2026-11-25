// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get view => 'View';

  @override
  String get signOut => 'Sign out';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorConnection =>
      'Something went wrong. Check your connection and try again.';

  @override
  String get errorServerUnreachable =>
      'Could not reach the server. Check your connection and try again.';

  @override
  String get couldNotOpenLink => 'Could not open this link.';

  @override
  String get requestSent =>
      'Request sent. A team member will follow up with you.';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusAvailable => 'Available';

  @override
  String get statusNotStarted => 'Not started';

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String dateTodayAt(String time) {
    return 'Today, $time';
  }

  @override
  String dateYesterdayAt(String time) {
    return 'Yesterday, $time';
  }

  @override
  String dateAt(String date, String time) {
    return '$date, $time';
  }

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String timeMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String timeHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String linkSemantic(String text) {
    return 'Link: $text';
  }

  @override
  String get languageTitle => 'Language';

  @override
  String get languagePhone => 'Phone language';

  @override
  String languagePhoneDetail(String language) {
    return 'Same as your phone ($language)';
  }

  @override
  String get languagePickerTitle => 'Choose a language';

  @override
  String languageButtonSemantic(String language) {
    return 'Language: $language. Tap to change.';
  }

  @override
  String get authTagline => 'Your personal health education companion';

  @override
  String get authTabSignIn => 'Sign In';

  @override
  String get authTabCreateAccount => 'Create Account';

  @override
  String get signInWelcome => 'Welcome back 👋';

  @override
  String get signInSubtitle => 'Sign in to continue your health journey';

  @override
  String get fieldEmail => 'Email address';

  @override
  String get fieldEmailHint => 'Enter your email';

  @override
  String get validationEmailRequired => 'Please enter your email';

  @override
  String get validationEmailInvalid => 'Please enter a valid email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldPasswordHint => 'Enter your password';

  @override
  String get validationPasswordRequired => 'Please enter your password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get signInForgot => 'Forgot password?';

  @override
  String get createTitle => 'Create your account';

  @override
  String get createSubtitle => 'Start your health education journey today';

  @override
  String get fieldFullName => 'Full name';

  @override
  String get fieldFullNameHint => 'Enter your full name';

  @override
  String get validationNameRequired => 'Please enter your name';

  @override
  String get fieldUsername => 'Username';

  @override
  String get fieldUsernameHint => 'The username your study team gave you';

  @override
  String get fieldUsernameHelper =>
      'Use the username your study team gave you. It links your surveys to your account and can’t be changed later.';

  @override
  String get validationUsernameRequired => 'Please enter your username';

  @override
  String get validationUsernameFormat =>
      'Use 3–20 letters or numbers (no spaces or symbols)';

  @override
  String get fieldPhone => 'Phone number';

  @override
  String get fieldPhoneHint => 'e.g. (949) 555-0100';

  @override
  String get validationPhoneRequired => 'Please enter your phone number';

  @override
  String get validationPhoneInvalid => 'Please enter a valid phone number';

  @override
  String get fieldCreatePasswordHint => 'Create a password';

  @override
  String get validationNewPasswordRequired => 'Please enter a password';

  @override
  String get validationPasswordMin8 => 'Password must be at least 8 characters';

  @override
  String get fieldConfirmPassword => 'Confirm password';

  @override
  String get fieldConfirmPasswordHint => 'Type your password again';

  @override
  String get validationConfirmRequired => 'Please confirm your password';

  @override
  String get validationPasswordsMismatch => 'Passwords do not match';

  @override
  String get legalTerms => 'Terms of Use';

  @override
  String get legalPrivacy => 'Privacy Policy';

  @override
  String createAgree(String terms, String privacy) {
    return 'I agree to the $terms and $privacy';
  }

  @override
  String get createAgreeRequired =>
      'Please agree to the Terms of Use and Privacy Policy';

  @override
  String get authErrorCredentials => 'Incorrect email or password.';

  @override
  String get authErrorUsernameRejected =>
      'That username is already taken or not allowed. Please choose another.';

  @override
  String get authErrorUsernameTaken =>
      'That username is already taken. Use the username your study team gave you, or contact the care team if it is already registered.';

  @override
  String get authErrorDisabled =>
      'This account has been disabled. Please contact your care team.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Please confirm your email before signing in.';

  @override
  String get authErrorEmailExists =>
      'An account with this email already exists. Try signing in.';

  @override
  String get authErrorRateLimited =>
      'Too many attempts. Please wait a minute and try again.';

  @override
  String get authErrorPassword => 'Please choose a different password.';

  @override
  String get checkEmailTitle => 'Check your email';

  @override
  String checkEmailBody(String email) {
    return 'We sent a confirmation link to\n$email\nOpen it on this device to finish creating your account.';
  }

  @override
  String get checkEmailResent => 'Confirmation email sent again.';

  @override
  String get checkEmailResend => 'Resend confirmation email';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get forgotTitle => 'Reset your password';

  @override
  String get forgotIntro =>
      'Enter your email and we will send you a reset link.';

  @override
  String forgotSent(String email) {
    return 'If an account exists for $email, a reset link is on its way. Open it on this device.';
  }

  @override
  String get forgotSend => 'Send reset link';

  @override
  String get resetTitle => 'Choose a new password';

  @override
  String get passwordMinShort => 'Use at least 8 characters.';

  @override
  String get fieldNewPassword => 'New password';

  @override
  String get fieldConfirmNewPassword => 'Confirm new password';

  @override
  String get resetButton => 'Update password';

  @override
  String get gateTitle => 'Set a new password';

  @override
  String get gateBody =>
      'Your care team created this account with a temporary password. Please choose your own to continue.';

  @override
  String get gateRule =>
      'At least 8 characters with an uppercase letter, a lowercase letter, and a number.';

  @override
  String get gateErrorMix =>
      'Include an uppercase letter, a lowercase letter, and a number.';

  @override
  String get gateSuccess => 'Password updated. Welcome!';

  @override
  String get gateErrorSame =>
      'Choose a password different from the temporary one.';

  @override
  String get gateErrorFailed =>
      'Could not update your password. Check your connection.';

  @override
  String get gateSave => 'Save password';

  @override
  String get menuOpen => 'Open menu';

  @override
  String get menuAssessments => 'Holistic Assessments';

  @override
  String get menuAssessmentsSubtitle => 'Questionnaires from your care team';

  @override
  String get menuAssistance => 'I need assistance';

  @override
  String get menuAssistanceSubtitle => 'Ask your care team for help';

  @override
  String get menuMyRequests => 'My help requests';

  @override
  String get menuMyRequestsSubtitle => 'See the status of what you sent';

  @override
  String get menuEmergency => 'In an emergency, call 911.';

  @override
  String get navEducation => 'Education';

  @override
  String get navResources => 'Resources';

  @override
  String get navProgress => 'Progress';

  @override
  String get navChat => 'Chat';

  @override
  String get navProfile => 'Profile';

  @override
  String get crashTitle => 'Something went wrong';

  @override
  String get crashBody =>
      'Please restart the app. If this keeps happening, contact the research team.';

  @override
  String get homeGoodMorning => 'Good morning';

  @override
  String get homeGoodAfternoon => 'Good afternoon';

  @override
  String get homeGoodEvening => 'Good evening';

  @override
  String get homeHi => 'Hi 👋';

  @override
  String homeHiName(String name) {
    return 'Hi, $name 👋';
  }

  @override
  String get homeTitle => 'Your Health\nEducation Hub';

  @override
  String get homeSearchHint => 'Search lessons, topics...';

  @override
  String get homeCategoryAll => 'All';

  @override
  String get homeNoLessons => 'No lessons are available yet. Check back soon.';

  @override
  String get homeNoMatches => 'No lessons match your search.';

  @override
  String get progressCardTitle => 'Your progress';

  @override
  String progressCardLessons(int completed, int total) {
    return '$completed / $total lessons';
  }

  @override
  String get progressCardStart => 'Let\'s get started!';

  @override
  String progressCardGreat(int percent) {
    return '$percent% complete — you\'re doing great!';
  }

  @override
  String progressCardKeepGoing(int percent) {
    return '$percent% complete — keep going!';
  }

  @override
  String get progressCardDone => '100% complete — amazing work!';

  @override
  String get lessonHeader => 'Lesson';

  @override
  String get lessonNoLessonsShort => 'No lessons are available yet.';

  @override
  String get lessonNoneSelected => 'No lesson selected.';

  @override
  String get lessonMarked => 'Lesson marked as completed. Great job!';

  @override
  String get lessonCompletedTitle => 'Lesson completed';

  @override
  String get lessonFinishPrompt => 'Finished this lesson?';

  @override
  String get lessonCompletedBody =>
      'Great job! You can come back and review it any time.';

  @override
  String get lessonFinishBody =>
      'Mark it as completed to keep track of your progress.';

  @override
  String get lessonMarkButton => 'Mark as completed';

  @override
  String lessonSections(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sections',
      one: '1 section',
    );
    return '$_temp0';
  }

  @override
  String get refTitle => 'References';

  @override
  String get refLessonVideo => 'Lesson video';

  @override
  String get refLessonAudio => 'Lesson audio';

  @override
  String get scriptTitle => 'Lesson notes';

  @override
  String get scriptReadMore => 'Read more';

  @override
  String get scriptShowLess => 'Show less';

  @override
  String get infoTitle => 'Infographic';

  @override
  String get infoCardTitle => 'Lesson infographic';

  @override
  String infoCardSubtitle(String title) {
    return 'Visual summary of $title';
  }

  @override
  String infoSemantic(String title) {
    return 'Infographic for $title';
  }

  @override
  String get infoTapHint => 'Tap the image to view full screen and zoom';

  @override
  String get imageOpenFullscreen => 'View full screen';

  @override
  String get imageLoadFailed => 'Could not load the image.';

  @override
  String get imageCloseFullscreen => 'Close full screen view';

  @override
  String get imageZoomHint => 'Pinch or double-tap to zoom';

  @override
  String get videoTitle => 'Video lesson';

  @override
  String get videoPlaying => 'Playing video';

  @override
  String get videoTapToPlay => 'Tap to play video';

  @override
  String get videoYouTube => 'YouTube video';

  @override
  String get audioTitle => 'Audio lesson';

  @override
  String get audioOpen => 'Open audio';

  @override
  String get audioListen => 'Listen to this lesson';

  @override
  String get kahootTitle => 'Knowledge game';

  @override
  String get kahootMarked => 'Nice work! Quiz marked as finished.';

  @override
  String get kahootCopied => 'Username copied.';

  @override
  String get kahootCopyTooltip => 'Copy username';

  @override
  String get kahootUsernameLabel => 'Your Kahoot username';

  @override
  String get kahootUsernameHint =>
      'Use this username when the Kahoot game asks for a nickname';

  @override
  String get kahootIntro =>
      'Test what you\'ve learned with an interactive Kahoot! game';

  @override
  String get kahootBadgeTime => '⏱ ~5 min';

  @override
  String get kahootBadgeInteractive => '✨ Interactive';

  @override
  String get kahootBadgeFun => '🎉 Fun!';

  @override
  String get kahootStart => 'Start Kahoot! game';

  @override
  String get kahootEmbedHint =>
      'The game opens below when you tap the button above';

  @override
  String get kahootFinished => 'Quiz finished';

  @override
  String get kahootIFinished => 'I finished the quiz';

  @override
  String get chatAiTitle => 'AI Assistant';

  @override
  String get chatAiSubtitle => 'Automated answers, 24/7';

  @override
  String get chatTeamTitle => 'Research Team';

  @override
  String get chatTeamSubtitle => 'Happy Hearts Study';

  @override
  String get chatTabTeam => 'Care Team';

  @override
  String get chatSignInAi => 'Please sign in to use the AI assistant.';

  @override
  String get chatSignIn => 'Please sign in to use chat.';

  @override
  String get chatNeedHelp => 'Need help with something?';

  @override
  String get chatViewRequests => 'View my requests';

  @override
  String get chatEmptyTitle => 'Start a conversation';

  @override
  String get chatEmptyBody =>
      'Send a message to the Happy Hearts research team. We\'re here to help with any questions about your study.';

  @override
  String get chatNotSent => 'Not sent';

  @override
  String get chatDelete => 'Delete';

  @override
  String get chatEdit => 'Edit';

  @override
  String get chatCopy => 'Copy';

  @override
  String get chatEdited => 'Edited';

  @override
  String get chatEditingMessage => 'Editing message';

  @override
  String get chatDeleteConfirm => 'Delete this message?';

  @override
  String get chatYouDeleted => 'You deleted this message';

  @override
  String get chatMessageDeleted => 'This message was deleted';

  @override
  String get chatRemovedByTeam => 'Removed by the research team';

  @override
  String get chatEditTooLate =>
      'Messages can only be edited within 15 minutes.';

  @override
  String get chatEditFailed => 'Could not edit the message.';

  @override
  String get chatDeleteFailed => 'Could not delete the message.';

  @override
  String get chatSending => 'Sending…';

  @override
  String get chatInputHint => 'Message the research team...';

  @override
  String get chatSend => 'Send';

  @override
  String get chatErrorWrongAccount =>
      'This account cannot use patient chat. Please sign in with a patient account.';

  @override
  String get chatErrorOpen =>
      'Could not open your conversation. Please try again.';

  @override
  String get chatErrorLoad =>
      'Could not load messages. Check your connection and try again.';

  @override
  String get chatErrorKept =>
      'Could not reach the server. Your message was kept. Tap Retry.';

  @override
  String get chatErrorNoPermission =>
      'You do not have permission to send messages in this conversation.';

  @override
  String get chatErrorLength => 'Messages must be 1–4000 characters.';

  @override
  String get chatErrorNotSent => 'Message not sent. Please try again.';

  @override
  String get chatErrorGeneric =>
      'Something went wrong loading your conversation.';

  @override
  String get aiErrorConnection =>
      'Could not load the AI assistant. Check your connection.';

  @override
  String get aiErrorUnavailable => 'The AI assistant is unavailable right now.';

  @override
  String get aiErrorStart => 'Could not start the AI assistant.';

  @override
  String get aiErrorTimeout => 'The AI assistant is taking too long to load.';

  @override
  String get aiWebOnly =>
      'The AI assistant is available in the HappyHearts iOS and Android app.';

  @override
  String get assistMyRequests => 'My requests';

  @override
  String get assistIntro =>
      'Tell the research team what you need help with. A team member will follow up, usually by message in Care Team chat.';

  @override
  String get assistEmergency =>
      'This is not monitored around the clock. If this is an emergency, call 911.';

  @override
  String get assistHint =>
      'For example: \"I have a question about my medication\" or \"The video in Session 3 won\'t play.\"';

  @override
  String get assistSend => 'Send request';

  @override
  String get assistErrorEmpty => 'Please describe what you need help with.';

  @override
  String assistErrorTooLong(int max) {
    return 'Please keep your message under $max characters.';
  }

  @override
  String get assistErrorOffline =>
      'Could not reach the server. Your message was kept — please try again.';

  @override
  String get assistErrorLoad =>
      'Could not load your requests. Check your connection and try again.';

  @override
  String get assistErrorNotParticipant =>
      'Only participant accounts can send assistance requests.';

  @override
  String assistErrorLength(int max) {
    return 'Please write a message between 1 and $max characters.';
  }

  @override
  String get assistErrorRateLimited =>
      'You have sent several requests recently. The team will get back to you soon. If it is urgent, call your care team. In an emergency, call 911.';

  @override
  String get assistErrorNotSent =>
      'Your request was not sent. Your message was kept — please try again.';

  @override
  String get requestsTitle => 'My assistance requests';

  @override
  String get requestsNew => 'New request';

  @override
  String get requestsEmptyTitle => 'No requests yet';

  @override
  String get requestsEmptyBody =>
      'When you need help from the research team, send a request and you can follow its status here.';

  @override
  String get requestStatusSent => 'Sent';

  @override
  String get requestStatusSeen => 'Seen by the team';

  @override
  String get requestStatusResolved => 'Resolved';

  @override
  String get requestWaiting => 'Waiting for a team member to review it.';

  @override
  String get requestFollowing => 'A team member is following up.';

  @override
  String requestFollowingSince(String time) {
    return 'A team member is following up ($time).';
  }

  @override
  String get requestResolved => 'Marked resolved.';

  @override
  String requestResolvedSince(String time) {
    return 'Marked resolved ($time).';
  }

  @override
  String get assessSubtitleSurvey => 'Questionnaires from your care team.';

  @override
  String get assessSubtitleResources =>
      'Track your mental and physical health with these validated screening tools.';

  @override
  String get assessEmptySurvey =>
      'No holistic assessments right now. Your care team will add them here.';

  @override
  String get assessEmptyResources =>
      'No resources right now. Your care team will add them here.';

  @override
  String get assessUsernameError =>
      'Could not load your username. Please try again.';

  @override
  String assessLastCompleted(String date) {
    return 'Last completed $date';
  }

  @override
  String get assessStart => 'Start assessment';

  @override
  String get surveyErrorLoad =>
      'Could not load surveys. Check your connection and try again.';

  @override
  String get surveyRecordFailed =>
      'Your answers were submitted, but the app could not mark the survey as completed.';

  @override
  String get surveyThanks => 'Thank you!';

  @override
  String get surveyThanksBody =>
      'Your responses were submitted. You can see this survey in your Progress calendar.';

  @override
  String get surveyLoading => 'Loading survey...';

  @override
  String get surveyLoadFailedTitle => 'Unable to load survey';

  @override
  String get surveyLoadFailedBody =>
      'Please check your internet connection and try again.';

  @override
  String get progressSubtitle =>
      'Track your learning journey and celebrate milestones.';

  @override
  String get progressCalendar => 'Activity calendar';

  @override
  String get progressBreakdown => 'Lessons';

  @override
  String activityCompleted(String title) {
    return 'Completed: $title';
  }

  @override
  String activityQuizFinished(String title) {
    return 'Finished quiz: $title';
  }

  @override
  String activitySurveyFallback(String code) {
    return 'Survey ($code)';
  }

  @override
  String get calPrevMonth => 'Previous month';

  @override
  String get calNextMonth => 'Next month';

  @override
  String get legendLesson => 'Lesson';

  @override
  String get legendQuiz => 'Quiz';

  @override
  String get legendSurvey => 'Survey';

  @override
  String get calLessonDone => 'lesson completed';

  @override
  String get calQuizDone => 'quiz finished';

  @override
  String get calSurveyDone => 'survey completed';

  @override
  String get activityRecent => 'Recent activity';

  @override
  String activityOnDay(String date) {
    return 'Activity on $date';
  }

  @override
  String get activityShowAll => 'Show all';

  @override
  String get activityEmpty =>
      'Complete a lesson, quiz, or survey and it will show up here.';

  @override
  String get activityEmptyDay => 'Nothing completed on this day.';

  @override
  String get overallTitle => 'Overall completion';

  @override
  String overallCount(int completed, int total) {
    return '$completed of $total lessons';
  }

  @override
  String get overallAllDone => '🎉 All lessons complete!';

  @override
  String get overallKeepGoing => 'Keep going — you\'re making great progress!';

  @override
  String get overallStart => 'Start your first lesson to begin.';

  @override
  String get statTimeSpent => 'Time spent';

  @override
  String timeSpentSuffix(String time) {
    return '$time spent';
  }

  @override
  String get profileSignOutConfirm => 'Are you sure you want to sign out?';

  @override
  String profileResetSent(String email) {
    return 'Password reset link sent to $email';
  }

  @override
  String get profileAccount => 'Account';

  @override
  String get profileChangePassword => 'Change password (send reset email)';

  @override
  String get profilePreferences => 'Preferences';

  @override
  String get profileAbout => 'About';

  @override
  String get profileVersion => 'App version';

  @override
  String get profileNotAvailable => 'Your profile is not available.';

  @override
  String get profileEditName => 'Edit name';

  @override
  String get profileLearningSummary => 'Learning summary';

  @override
  String get profileStatComplete => 'Complete';

  @override
  String get profileProgressFailed =>
      'Could not load your progress. Tap to retry.';

  @override
  String get profileErrorSignIn => 'Please sign in.';

  @override
  String get profileErrorSessionChanged => 'Session changed. Please try again.';

  @override
  String get profileErrorMissing =>
      'Your profile could not be found. Pull down to retry; if this keeps happening, contact the research team.';

  @override
  String get profileErrorPermission =>
      'You do not have permission to view this profile.';

  @override
  String get profileErrorLoad =>
      'Could not load your profile. Check your connection and try again.';

  @override
  String get profileErrorNameEmpty => 'Name cannot be empty.';

  @override
  String get profileErrorSaveName =>
      'Could not save your name. Check your connection and try again.';

  @override
  String get contentErrorLessons =>
      'Could not load lessons. Check your connection and try again.';

  @override
  String get contentErrorProgress =>
      'Could not load your progress. Check your connection and try again.';

  @override
  String get materialsTitle => 'Materials';

  @override
  String get materialsPdf => 'PDF document';

  @override
  String materialsPdfSize(String size) {
    return 'PDF · $size';
  }

  @override
  String fileSizeMb(String size) {
    return '$size MB';
  }

  @override
  String fileSizeKb(String size) {
    return '$size KB';
  }

  @override
  String materialsOpenImage(String name) {
    return 'Open image: $name';
  }

  @override
  String materialsOpenPdf(String name) {
    return 'Open PDF: $name';
  }

  @override
  String get listSeparator => ', ';

  @override
  String get msgLangTitle => 'Check the language of your message';

  @override
  String msgLangBody(String languages) {
    return 'The research team only reads these languages: $languages. They may not be able to understand your message.';
  }

  @override
  String get msgLangSendAnyway => 'Send anyway';

  @override
  String get msgLangEdit => 'Edit message';
}
