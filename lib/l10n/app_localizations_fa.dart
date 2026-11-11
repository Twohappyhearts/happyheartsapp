// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get retry => 'تلاش دوباره';

  @override
  String get cancel => 'لغو';

  @override
  String get save => 'ذخیره';

  @override
  String get done => 'تمام';

  @override
  String get close => 'بستن';

  @override
  String get back => 'بازگشت';

  @override
  String get view => 'مشاهده';

  @override
  String get signOut => 'خروج از حساب';

  @override
  String get errorGeneric => 'مشکلی پیش آمد. لطفاً دوباره تلاش کنید.';

  @override
  String get errorConnection =>
      'مشکلی پیش آمد. اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get errorServerUnreachable =>
      'اتصال به سرور برقرار نشد. اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get couldNotOpenLink => 'این پیوند باز نشد.';

  @override
  String get requestSent =>
      'درخواست ارسال شد. یکی از اعضای تیم با شما پیگیری می‌کند.';

  @override
  String get statusCompleted => 'تکمیل‌شده';

  @override
  String get statusInProgress => 'در حال انجام';

  @override
  String get statusAvailable => 'در دسترس';

  @override
  String get statusNotStarted => 'شروع‌نشده';

  @override
  String get dateToday => 'امروز';

  @override
  String get dateYesterday => 'دیروز';

  @override
  String dateTodayAt(String time) {
    return 'امروز، $time';
  }

  @override
  String dateYesterdayAt(String time) {
    return 'دیروز، $time';
  }

  @override
  String dateAt(String date, String time) {
    return '$date، $time';
  }

  @override
  String minutesShort(int minutes) {
    return '$minutes دقیقه';
  }

  @override
  String timeMinutes(int minutes) {
    return '$minutes دقیقه';
  }

  @override
  String timeHoursMinutes(int hours, int minutes) {
    return '$hours ساعت $minutes دقیقه';
  }

  @override
  String linkSemantic(String text) {
    return 'پیوند: $text';
  }

  @override
  String get languageTitle => 'زبان';

  @override
  String get languagePhone => 'زبان گوشی';

  @override
  String languagePhoneDetail(String language) {
    return 'مانند گوشی شما ($language)';
  }

  @override
  String get languagePickerTitle => 'انتخاب زبان';

  @override
  String languageButtonSemantic(String language) {
    return 'زبان: $language. برای تغییر ضربه بزنید.';
  }

  @override
  String get authTagline => 'همراه شخصی شما برای آموزش سلامت';

  @override
  String get authTabSignIn => 'ورود';

  @override
  String get authTabCreateAccount => 'ایجاد حساب';

  @override
  String get signInWelcome => 'خوش آمدید 👋';

  @override
  String get signInSubtitle => 'برای ادامهٔ مسیر سلامت خود وارد شوید';

  @override
  String get fieldEmail => 'نشانی ایمیل';

  @override
  String get fieldEmailHint => 'ایمیل خود را وارد کنید';

  @override
  String get validationEmailRequired => 'لطفاً ایمیل خود را وارد کنید';

  @override
  String get validationEmailInvalid => 'لطفاً یک ایمیل معتبر وارد کنید';

  @override
  String get fieldPassword => 'رمز عبور';

  @override
  String get fieldPasswordHint => 'رمز عبور خود را وارد کنید';

  @override
  String get validationPasswordRequired => 'لطفاً رمز عبور را وارد کنید';

  @override
  String get showPassword => 'نمایش رمز عبور';

  @override
  String get hidePassword => 'پنهان کردن رمز عبور';

  @override
  String get signInForgot => 'رمز عبور را فراموش کرده‌اید؟';

  @override
  String get createTitle => 'حساب خود را بسازید';

  @override
  String get createSubtitle => 'از امروز آموزش سلامت را شروع کنید';

  @override
  String get fieldFullName => 'نام و نام خانوادگی';

  @override
  String get fieldFullNameHint => 'نام کامل خود را وارد کنید';

  @override
  String get validationNameRequired => 'لطفاً نام خود را وارد کنید';

  @override
  String get fieldUsername => 'نام کاربری';

  @override
  String get fieldUsernameHint => 'نام کاربری‌ای که تیم پژوهش به شما داده است';

  @override
  String get fieldUsernameHelper =>
      'از نام کاربری‌ای که تیم پژوهش به شما داده استفاده کنید. این نام پرسشنامه‌های شما را به حسابتان وصل می‌کند و بعداً قابل تغییر نیست.';

  @override
  String get validationUsernameRequired => 'لطفاً نام کاربری را وارد کنید';

  @override
  String get validationUsernameFormat =>
      'از 3 تا 20 حرف انگلیسی یا عدد استفاده کنید (بدون فاصله یا نماد)';

  @override
  String get fieldPhone => 'شماره تلفن';

  @override
  String get fieldPhoneHint => 'مثلاً (949) 555-0100';

  @override
  String get validationPhoneRequired => 'لطفاً شماره تلفن را وارد کنید';

  @override
  String get validationPhoneInvalid => 'لطفاً یک شماره تلفن معتبر وارد کنید';

  @override
  String get fieldCreatePasswordHint => 'یک رمز عبور بسازید';

  @override
  String get validationNewPasswordRequired => 'لطفاً یک رمز عبور وارد کنید';

  @override
  String get validationPasswordMin8 => 'رمز عبور باید دست‌کم 8 نویسه باشد';

  @override
  String get fieldConfirmPassword => 'تکرار رمز عبور';

  @override
  String get fieldConfirmPasswordHint => 'رمز عبور را دوباره وارد کنید';

  @override
  String get validationConfirmRequired => 'لطفاً رمز عبور را تکرار کنید';

  @override
  String get validationPasswordsMismatch => 'رمزهای عبور یکسان نیستند';

  @override
  String get legalTerms => 'شرایط استفاده';

  @override
  String get legalPrivacy => 'سیاست حریم خصوصی';

  @override
  String createAgree(String terms, String privacy) {
    return 'با $terms و $privacy موافقم';
  }

  @override
  String get createAgreeRequired =>
      'لطفاً با شرایط استفاده و سیاست حریم خصوصی موافقت کنید';

  @override
  String get authErrorCredentials => 'ایمیل یا رمز عبور نادرست است.';

  @override
  String get authErrorUsernameRejected =>
      'این نام کاربری قبلاً استفاده شده یا مجاز نیست. لطفاً نام دیگری انتخاب کنید.';

  @override
  String get authErrorUsernameTaken =>
      'این نام کاربری قبلاً استفاده شده است. از نام کاربری‌ای که تیم پژوهش به شما داده استفاده کنید، یا اگر قبلاً ثبت شده با تیم مراقبت تماس بگیرید.';

  @override
  String get authErrorDisabled =>
      'این حساب غیرفعال شده است. لطفاً با تیم مراقبت خود تماس بگیرید.';

  @override
  String get authErrorEmailNotConfirmed =>
      'لطفاً پیش از ورود، ایمیل خود را تأیید کنید.';

  @override
  String get authErrorEmailExists => 'حسابی با این ایمیل وجود دارد. وارد شوید.';

  @override
  String get authErrorRateLimited =>
      'تعداد تلاش‌ها زیاد است. یک دقیقه صبر کنید و دوباره تلاش کنید.';

  @override
  String get authErrorPassword => 'لطفاً رمز عبور دیگری انتخاب کنید.';

  @override
  String get checkEmailTitle => 'ایمیل خود را بررسی کنید';

  @override
  String checkEmailBody(String email) {
    return 'یک پیوند تأیید به این نشانی فرستادیم:\n$email\nآن را در همین دستگاه باز کنید تا ساخت حساب کامل شود.';
  }

  @override
  String get checkEmailResent => 'ایمیل تأیید دوباره ارسال شد.';

  @override
  String get checkEmailResend => 'ارسال دوبارهٔ ایمیل تأیید';

  @override
  String get backToSignIn => 'بازگشت به ورود';

  @override
  String get forgotTitle => 'بازنشانی رمز عبور';

  @override
  String get forgotIntro =>
      'ایمیل خود را وارد کنید تا پیوند بازنشانی را برایتان بفرستیم.';

  @override
  String forgotSent(String email) {
    return 'اگر حسابی با $email وجود داشته باشد، پیوند بازنشانی در راه است. آن را در همین دستگاه باز کنید.';
  }

  @override
  String get forgotSend => 'ارسال پیوند بازنشانی';

  @override
  String get resetTitle => 'رمز عبور جدید انتخاب کنید';

  @override
  String get passwordMinShort => 'دست‌کم 8 نویسه وارد کنید.';

  @override
  String get fieldNewPassword => 'رمز عبور جدید';

  @override
  String get fieldConfirmNewPassword => 'تکرار رمز عبور جدید';

  @override
  String get resetButton => 'به‌روزرسانی رمز عبور';

  @override
  String get gateTitle => 'رمز عبور جدید بگذارید';

  @override
  String get gateBody =>
      'تیم مراقبت این حساب را با یک رمز عبور موقت ساخته است. برای ادامه، رمز عبور خودتان را انتخاب کنید.';

  @override
  String get gateRule =>
      'دست‌کم 8 نویسه، شامل یک حرف بزرگ انگلیسی، یک حرف کوچک انگلیسی و یک عدد.';

  @override
  String get gateErrorMix => 'یک حرف بزرگ، یک حرف کوچک و یک عدد بگذارید.';

  @override
  String get gateSuccess => 'رمز عبور به‌روز شد. خوش آمدید!';

  @override
  String get gateErrorSame => 'رمزی متفاوت با رمز موقت انتخاب کنید.';

  @override
  String get gateErrorFailed =>
      'رمز عبور به‌روز نشد. اتصال اینترنت را بررسی کنید.';

  @override
  String get gateSave => 'ذخیرهٔ رمز عبور';

  @override
  String get menuOpen => 'باز کردن منو';

  @override
  String get menuAssessments => 'ارزیابی‌های جامع';

  @override
  String get menuAssessmentsSubtitle => 'پرسشنامه‌های تیم مراقبت شما';

  @override
  String get menuAssistance => 'به کمک نیاز دارم';

  @override
  String get menuAssistanceSubtitle => 'از تیم مراقبت کمک بخواهید';

  @override
  String get menuMyRequests => 'درخواست‌های کمک من';

  @override
  String get menuMyRequestsSubtitle =>
      'وضعیت درخواست‌هایی را که فرستاده‌اید ببینید';

  @override
  String get menuEmergency => 'در مواقع اضطراری با 911 تماس بگیرید.';

  @override
  String get navEducation => 'آموزش';

  @override
  String get navResources => 'منابع';

  @override
  String get navProgress => 'پیشرفت';

  @override
  String get navChat => 'گفتگو';

  @override
  String get navProfile => 'نمایه';

  @override
  String get crashTitle => 'مشکلی پیش آمد';

  @override
  String get crashBody =>
      'لطفاً برنامه را دوباره باز کنید. اگر مشکل ادامه داشت، با تیم پژوهش تماس بگیرید.';

  @override
  String get homeGoodMorning => 'صبح بخیر';

  @override
  String get homeGoodAfternoon => 'ظهر بخیر';

  @override
  String get homeGoodEvening => 'عصر بخیر';

  @override
  String get homeHi => 'سلام 👋';

  @override
  String homeHiName(String name) {
    return 'سلام $name 👋';
  }

  @override
  String get homeTitle => 'مرکز آموزش\nسلامت شما';

  @override
  String get homeSearchHint => 'جستجوی درس‌ها و موضوع‌ها...';

  @override
  String get homeCategoryAll => 'همه';

  @override
  String get homeNoLessons => 'هنوز درسی وجود ندارد. به‌زودی دوباره سر بزنید.';

  @override
  String get homeNoMatches => 'درسی با جستجوی شما پیدا نشد.';

  @override
  String get progressCardTitle => 'پیشرفت شما';

  @override
  String progressCardLessons(int completed, int total) {
    return '$completed از $total درس';
  }

  @override
  String get progressCardStart => 'بیایید شروع کنیم!';

  @override
  String progressCardGreat(int percent) {
    return '$percent٪ کامل شد — عالی پیش می‌روید!';
  }

  @override
  String progressCardKeepGoing(int percent) {
    return '$percent٪ کامل شد — ادامه دهید!';
  }

  @override
  String get progressCardDone => '100٪ کامل شد — کارتان عالی بود!';

  @override
  String get lessonHeader => 'درس';

  @override
  String get lessonNoLessonsShort => 'هنوز درسی وجود ندارد.';

  @override
  String get lessonNoneSelected => 'درسی انتخاب نشده است.';

  @override
  String get lessonMarked => 'درس به‌عنوان تکمیل‌شده علامت خورد. آفرین!';

  @override
  String get lessonCompletedTitle => 'درس تکمیل شد';

  @override
  String get lessonFinishPrompt => 'این درس را تمام کردید؟';

  @override
  String get lessonCompletedBody =>
      'آفرین! هر زمان خواستید می‌توانید برگردید و مرور کنید.';

  @override
  String get lessonFinishBody =>
      'آن را تکمیل‌شده علامت بزنید تا پیشرفتتان ثبت شود.';

  @override
  String get lessonMarkButton => 'علامت‌گذاری به‌عنوان تکمیل‌شده';

  @override
  String lessonSections(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بخش',
    );
    return '$_temp0';
  }

  @override
  String get refTitle => 'مراجع';

  @override
  String get refLessonVideo => 'ویدیوی درس';

  @override
  String get refLessonAudio => 'صوت درس';

  @override
  String get scriptTitle => 'یادداشت‌های درس';

  @override
  String get scriptReadMore => 'بیشتر بخوانید';

  @override
  String get scriptShowLess => 'نمایش کمتر';

  @override
  String get infoTitle => 'اینفوگرافیک';

  @override
  String get infoCardTitle => 'اینفوگرافیک درس';

  @override
  String infoCardSubtitle(String title) {
    return 'خلاصهٔ تصویری $title';
  }

  @override
  String infoSemantic(String title) {
    return 'اینفوگرافیک $title';
  }

  @override
  String get infoTapHint =>
      'برای نمایش تمام‌صفحه و بزرگ‌نمایی، روی تصویر ضربه بزنید';

  @override
  String get imageOpenFullscreen => 'نمایش تمام‌صفحه';

  @override
  String get imageLoadFailed => 'تصویر بارگیری نشد.';

  @override
  String get imageCloseFullscreen => 'بستن نمای تمام‌صفحه';

  @override
  String get imageZoomHint =>
      'برای بزرگ‌نمایی، دو انگشت را باز کنید یا دو بار ضربه بزنید';

  @override
  String get videoTitle => 'درس ویدیویی';

  @override
  String get videoPlaying => 'در حال پخش ویدیو';

  @override
  String get videoTapToPlay => 'برای پخش ویدیو ضربه بزنید';

  @override
  String get videoYouTube => 'ویدیوی یوتیوب';

  @override
  String get audioTitle => 'درس صوتی';

  @override
  String get audioOpen => 'باز کردن فایل صوتی';

  @override
  String get audioListen => 'به این درس گوش دهید';

  @override
  String get kahootTitle => 'بازی دانش';

  @override
  String get kahootMarked => 'آفرین! آزمونک به‌عنوان تمام‌شده علامت خورد.';

  @override
  String get kahootCopied => 'نام کاربری کپی شد.';

  @override
  String get kahootCopyTooltip => 'کپی نام کاربری';

  @override
  String get kahootUsernameLabel => 'نام کاربری شما در Kahoot';

  @override
  String get kahootUsernameHint =>
      'وقتی بازی Kahoot نام مستعار خواست، این نام کاربری را وارد کنید';

  @override
  String get kahootIntro =>
      'آنچه یاد گرفته‌اید را با یک بازی تعاملی Kahoot! بسنجید';

  @override
  String get kahootBadgeTime => '⏱ حدود 5 دقیقه';

  @override
  String get kahootBadgeInteractive => '✨ تعاملی';

  @override
  String get kahootBadgeFun => '🎉 سرگرم‌کننده!';

  @override
  String get kahootStart => 'شروع بازی Kahoot!';

  @override
  String get kahootEmbedHint => 'با زدن دکمهٔ بالا، بازی در پایین باز می‌شود';

  @override
  String get kahootFinished => 'آزمونک تمام شد';

  @override
  String get kahootIFinished => 'آزمونک را تمام کردم';

  @override
  String get chatAiTitle => 'دستیار هوش مصنوعی';

  @override
  String get chatAiSubtitle => 'پاسخ خودکار، شبانه‌روزی';

  @override
  String get chatTeamTitle => 'تیم پژوهش';

  @override
  String get chatTeamSubtitle => 'پژوهش Happy Hearts';

  @override
  String get chatTabTeam => 'تیم مراقبت';

  @override
  String get chatSignInAi => 'برای استفاده از دستیار هوش مصنوعی وارد شوید.';

  @override
  String get chatSignIn => 'برای استفاده از گفتگو وارد شوید.';

  @override
  String get chatNeedHelp => 'به کمک نیاز دارید؟';

  @override
  String get chatViewRequests => 'مشاهدهٔ درخواست‌های من';

  @override
  String get chatEmptyTitle => 'گفتگو را شروع کنید';

  @override
  String get chatEmptyBody =>
      'به تیم پژوهش Happy Hearts پیام بدهید. برای هر پرسشی دربارهٔ پژوهش، کنار شما هستیم.';

  @override
  String get chatNotSent => 'ارسال نشد';

  @override
  String get chatDelete => 'حذف';

  @override
  String get chatSending => 'در حال ارسال…';

  @override
  String get chatInputHint => 'به تیم پژوهش پیام دهید...';

  @override
  String get chatSend => 'ارسال';

  @override
  String get chatErrorWrongAccount =>
      'این حساب نمی‌تواند از گفتگوی بیمار استفاده کند. لطفاً با حساب بیمار وارد شوید.';

  @override
  String get chatErrorOpen => 'گفتگوی شما باز نشد. لطفاً دوباره تلاش کنید.';

  @override
  String get chatErrorLoad =>
      'پیام‌ها بارگیری نشد. اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get chatErrorKept =>
      'اتصال به سرور برقرار نشد. پیام شما نگه داشته شد. «تلاش دوباره» را بزنید.';

  @override
  String get chatErrorNoPermission =>
      'اجازهٔ ارسال پیام در این گفتگو را ندارید.';

  @override
  String get chatErrorLength => 'پیام باید بین 1 تا 4000 نویسه باشد.';

  @override
  String get chatErrorNotSent => 'پیام ارسال نشد. لطفاً دوباره تلاش کنید.';

  @override
  String get chatErrorGeneric => 'هنگام بارگیری گفتگو مشکلی پیش آمد.';

  @override
  String get aiErrorConnection =>
      'دستیار هوش مصنوعی بارگیری نشد. اتصال اینترنت را بررسی کنید.';

  @override
  String get aiErrorUnavailable =>
      'دستیار هوش مصنوعی در حال حاضر در دسترس نیست.';

  @override
  String get aiErrorStart => 'دستیار هوش مصنوعی راه‌اندازی نشد.';

  @override
  String get aiErrorTimeout => 'بارگیری دستیار هوش مصنوعی بیش از حد طول کشید.';

  @override
  String get aiWebOnly =>
      'دستیار هوش مصنوعی در برنامهٔ HappyHearts برای iOS و Android در دسترس است.';

  @override
  String get assistMyRequests => 'درخواست‌های من';

  @override
  String get assistIntro =>
      'به تیم پژوهش بگویید در چه موردی به کمک نیاز دارید. یکی از اعضای تیم، معمولاً با پیام در گفتگوی «تیم مراقبت»، پیگیری می‌کند.';

  @override
  String get assistEmergency =>
      'این بخش شبانه‌روزی بررسی نمی‌شود. اگر وضعیت اضطراری است، با 911 تماس بگیرید.';

  @override
  String get assistHint =>
      'مثلاً: «دربارهٔ داروی خودم سؤال دارم» یا «ویدیوی جلسهٔ 3 پخش نمی‌شود.»';

  @override
  String get assistSend => 'ارسال درخواست';

  @override
  String get assistErrorEmpty => 'لطفاً توضیح دهید به چه کمکی نیاز دارید.';

  @override
  String assistErrorTooLong(int max) {
    return 'پیام شما باید کمتر از $max نویسه باشد.';
  }

  @override
  String get assistErrorOffline =>
      'اتصال به سرور برقرار نشد. پیام شما نگه داشته شد؛ لطفاً دوباره تلاش کنید.';

  @override
  String get assistErrorLoad =>
      'درخواست‌های شما بارگیری نشد. اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get assistErrorNotParticipant =>
      'فقط حساب‌های شرکت‌کنندگان می‌توانند درخواست کمک بفرستند.';

  @override
  String assistErrorLength(int max) {
    return 'لطفاً پیامی بین 1 تا $max نویسه بنویسید.';
  }

  @override
  String get assistErrorRateLimited =>
      'اخیراً چند درخواست فرستاده‌اید. تیم به‌زودی پاسخ می‌دهد. اگر فوری است، با تیم مراقبت خود تماس بگیرید. در مواقع اضطراری با 911 تماس بگیرید.';

  @override
  String get assistErrorNotSent =>
      'درخواست شما ارسال نشد. پیام شما نگه داشته شد؛ لطفاً دوباره تلاش کنید.';

  @override
  String get requestsTitle => 'درخواست‌های کمک من';

  @override
  String get requestsNew => 'درخواست جدید';

  @override
  String get requestsEmptyTitle => 'هنوز درخواستی ندارید';

  @override
  String get requestsEmptyBody =>
      'هر وقت از تیم پژوهش کمک خواستید، درخواست بفرستید؛ وضعیت آن را اینجا می‌بینید.';

  @override
  String get requestStatusSent => 'ارسال شد';

  @override
  String get requestStatusSeen => 'تیم دید';

  @override
  String get requestStatusResolved => 'حل شد';

  @override
  String get requestWaiting => 'در انتظار بررسی یکی از اعضای تیم.';

  @override
  String get requestFollowing => 'یکی از اعضای تیم در حال پیگیری است.';

  @override
  String requestFollowingSince(String time) {
    return 'یکی از اعضای تیم در حال پیگیری است ($time).';
  }

  @override
  String get requestResolved => 'به‌عنوان حل‌شده علامت خورد.';

  @override
  String requestResolvedSince(String time) {
    return 'به‌عنوان حل‌شده علامت خورد ($time).';
  }

  @override
  String get assessSubtitleSurvey => 'پرسشنامه‌های تیم مراقبت شما.';

  @override
  String get assessSubtitleResources =>
      'سلامت روان و جسم خود را با این ابزارهای غربالگری معتبر پیگیری کنید.';

  @override
  String get assessEmptySurvey =>
      'فعلاً ارزیابی جامعی وجود ندارد. تیم مراقبت آن‌ها را اینجا اضافه می‌کند.';

  @override
  String get assessEmptyResources =>
      'فعلاً منبعی وجود ندارد. تیم مراقبت آن‌ها را اینجا اضافه می‌کند.';

  @override
  String get assessUsernameError =>
      'نام کاربری شما بارگیری نشد. لطفاً دوباره تلاش کنید.';

  @override
  String assessLastCompleted(String date) {
    return 'آخرین تکمیل: $date';
  }

  @override
  String get assessStart => 'شروع ارزیابی';

  @override
  String get surveyErrorLoad =>
      'پرسشنامه‌ها بارگیری نشد. اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get surveyRecordFailed =>
      'پاسخ‌های شما ارسال شد، اما برنامه نتوانست پرسشنامه را تکمیل‌شده علامت بزند.';

  @override
  String get surveyThanks => 'سپاسگزاریم!';

  @override
  String get surveyThanksBody =>
      'پاسخ‌های شما ارسال شد. این پرسشنامه را در تقویم «پیشرفت» می‌بینید.';

  @override
  String get surveyLoading => 'در حال بارگیری پرسشنامه...';

  @override
  String get surveyLoadFailedTitle => 'پرسشنامه بارگیری نشد';

  @override
  String get surveyLoadFailedBody =>
      'لطفاً اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get progressSubtitle =>
      'مسیر یادگیری خود را دنبال کنید و موفقیت‌هایتان را جشن بگیرید.';

  @override
  String get progressCalendar => 'تقویم فعالیت';

  @override
  String get progressBreakdown => 'درس‌ها';

  @override
  String activityCompleted(String title) {
    return 'تکمیل شد: $title';
  }

  @override
  String activityQuizFinished(String title) {
    return 'آزمونک تمام شد: $title';
  }

  @override
  String activitySurveyFallback(String code) {
    return 'پرسشنامه ($code)';
  }

  @override
  String get calPrevMonth => 'ماه قبل';

  @override
  String get calNextMonth => 'ماه بعد';

  @override
  String get legendLesson => 'درس';

  @override
  String get legendQuiz => 'آزمونک';

  @override
  String get legendSurvey => 'پرسشنامه';

  @override
  String get calLessonDone => 'درس تکمیل شد';

  @override
  String get calQuizDone => 'آزمونک تمام شد';

  @override
  String get calSurveyDone => 'پرسشنامه تکمیل شد';

  @override
  String get activityRecent => 'فعالیت‌های اخیر';

  @override
  String activityOnDay(String date) {
    return 'فعالیت $date';
  }

  @override
  String get activityShowAll => 'نمایش همه';

  @override
  String get activityEmpty =>
      'یک درس، آزمونک یا پرسشنامه را تمام کنید تا اینجا نمایش داده شود.';

  @override
  String get activityEmptyDay => 'در این روز چیزی تکمیل نشده است.';

  @override
  String get overallTitle => 'میزان تکمیل کلی';

  @override
  String overallCount(int completed, int total) {
    return '$completed از $total درس';
  }

  @override
  String get overallAllDone => '🎉 همهٔ درس‌ها تکمیل شد!';

  @override
  String get overallKeepGoing => 'ادامه دهید — عالی پیش می‌روید!';

  @override
  String get overallStart => 'برای شروع، اولین درس را باز کنید.';

  @override
  String get statTimeSpent => 'زمان صرف‌شده';

  @override
  String timeSpentSuffix(String time) {
    return '$time صرف شده';
  }

  @override
  String get profileSignOutConfirm => 'آیا مطمئن هستید که می‌خواهید خارج شوید؟';

  @override
  String profileResetSent(String email) {
    return 'پیوند بازنشانی رمز عبور به $email ارسال شد';
  }

  @override
  String get profileAccount => 'حساب کاربری';

  @override
  String get profileChangePassword => 'تغییر رمز عبور (ارسال ایمیل بازنشانی)';

  @override
  String get profilePreferences => 'تنظیمات';

  @override
  String get profileAbout => 'درباره';

  @override
  String get profileVersion => 'نسخهٔ برنامه';

  @override
  String get profileNotAvailable => 'نمایهٔ شما در دسترس نیست.';

  @override
  String get profileEditName => 'ویرایش نام';

  @override
  String get profileLearningSummary => 'خلاصهٔ یادگیری';

  @override
  String get profileStatComplete => 'تکمیل';

  @override
  String get profileProgressFailed =>
      'پیشرفت شما بارگیری نشد. برای تلاش دوباره ضربه بزنید.';

  @override
  String get profileErrorSignIn => 'لطفاً وارد شوید.';

  @override
  String get profileErrorSessionChanged =>
      'نشست تغییر کرد. لطفاً دوباره تلاش کنید.';

  @override
  String get profileErrorMissing =>
      'نمایهٔ شما پیدا نشد. برای تلاش دوباره صفحه را به پایین بکشید؛ اگر ادامه داشت، با تیم پژوهش تماس بگیرید.';

  @override
  String get profileErrorPermission => 'اجازهٔ دیدن این نمایه را ندارید.';

  @override
  String get profileErrorLoad =>
      'نمایهٔ شما بارگیری نشد. اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get profileErrorNameEmpty => 'نام نمی‌تواند خالی باشد.';

  @override
  String get profileErrorSaveName =>
      'نام شما ذخیره نشد. اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get contentErrorLessons =>
      'درس‌ها بارگیری نشد. اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get contentErrorProgress =>
      'پیشرفت شما بارگیری نشد. اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get materialsTitle => 'مطالب درس';

  @override
  String get materialsPdf => 'سند PDF';

  @override
  String materialsPdfSize(String size) {
    return 'PDF · $size';
  }

  @override
  String fileSizeMb(String size) {
    return '$size مگابایت';
  }

  @override
  String fileSizeKb(String size) {
    return '$size کیلوبایت';
  }

  @override
  String materialsOpenImage(String name) {
    return 'باز کردن تصویر: $name';
  }

  @override
  String materialsOpenPdf(String name) {
    return 'باز کردن PDF: $name';
  }
}
