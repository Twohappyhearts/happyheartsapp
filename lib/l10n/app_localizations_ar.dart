// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get done => 'تم';

  @override
  String get close => 'إغلاق';

  @override
  String get back => 'رجوع';

  @override
  String get view => 'عرض';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get errorGeneric => 'حدث خطأ ما. يُرجى المحاولة مرة أخرى.';

  @override
  String get errorConnection =>
      'حدث خطأ ما. تحقّق من اتصالك بالإنترنت وحاول مرة أخرى.';

  @override
  String get errorServerUnreachable =>
      'تعذّر الوصول إلى الخادم. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String get couldNotOpenLink => 'تعذّر فتح هذا الرابط.';

  @override
  String get requestSent => 'تم إرسال الطلب. سيتواصل معك أحد أعضاء الفريق.';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get statusInProgress => 'قيد التقدّم';

  @override
  String get statusAvailable => 'متاح';

  @override
  String get statusNotStarted => 'لم يبدأ';

  @override
  String get dateToday => 'اليوم';

  @override
  String get dateYesterday => 'أمس';

  @override
  String dateTodayAt(String time) {
    return 'اليوم، $time';
  }

  @override
  String dateYesterdayAt(String time) {
    return 'أمس، $time';
  }

  @override
  String dateAt(String date, String time) {
    return '$date، $time';
  }

  @override
  String minutesShort(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String timeMinutes(int minutes) {
    return '$minutes د';
  }

  @override
  String timeHoursMinutes(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String linkSemantic(String text) {
    return 'رابط: $text';
  }

  @override
  String get languageTitle => 'اللغة';

  @override
  String get languagePhone => 'لغة الهاتف';

  @override
  String languagePhoneDetail(String language) {
    return 'مثل هاتفك ($language)';
  }

  @override
  String get languagePickerTitle => 'اختر اللغة';

  @override
  String languageButtonSemantic(String language) {
    return 'اللغة: $language. اضغط للتغيير.';
  }

  @override
  String get authTagline => 'رفيقك الشخصي للتثقيف الصحي';

  @override
  String get authTabSignIn => 'تسجيل الدخول';

  @override
  String get authTabCreateAccount => 'إنشاء حساب';

  @override
  String get signInWelcome => 'مرحبًا بعودتك 👋';

  @override
  String get signInSubtitle => 'سجّل الدخول لمتابعة رحلتك الصحية';

  @override
  String get fieldEmail => 'البريد الإلكتروني';

  @override
  String get fieldEmailHint => 'أدخل بريدك الإلكتروني';

  @override
  String get validationEmailRequired => 'يُرجى إدخال بريدك الإلكتروني';

  @override
  String get validationEmailInvalid => 'يُرجى إدخال بريد إلكتروني صحيح';

  @override
  String get fieldPassword => 'كلمة المرور';

  @override
  String get fieldPasswordHint => 'أدخل كلمة المرور';

  @override
  String get validationPasswordRequired => 'يُرجى إدخال كلمة المرور';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get signInForgot => 'هل نسيت كلمة المرور؟';

  @override
  String get createTitle => 'أنشئ حسابك';

  @override
  String get createSubtitle => 'ابدأ رحلة التثقيف الصحي اليوم';

  @override
  String get fieldFullName => 'الاسم الكامل';

  @override
  String get fieldFullNameHint => 'أدخل اسمك الكامل';

  @override
  String get validationNameRequired => 'يُرجى إدخال اسمك';

  @override
  String get fieldUsername => 'اسم المستخدم';

  @override
  String get fieldUsernameHint => 'اسم المستخدم الذي أعطاك إياه فريق الدراسة';

  @override
  String get fieldUsernameHelper =>
      'استخدم اسم المستخدم الذي أعطاك إياه فريق الدراسة. فهو يربط استبياناتك بحسابك ولا يمكن تغييره لاحقًا.';

  @override
  String get validationUsernameRequired => 'يُرجى إدخال اسم المستخدم';

  @override
  String get validationUsernameFormat =>
      'استخدم من 3 إلى 20 حرفًا إنجليزيًا أو رقمًا (بدون مسافات أو رموز)';

  @override
  String get fieldPhone => 'رقم الهاتف';

  @override
  String get fieldPhoneHint => 'مثال: (949) 555-0100';

  @override
  String get validationPhoneRequired => 'يُرجى إدخال رقم هاتفك';

  @override
  String get validationPhoneInvalid => 'يُرجى إدخال رقم هاتف صحيح';

  @override
  String get fieldCreatePasswordHint => 'أنشئ كلمة مرور';

  @override
  String get validationNewPasswordRequired => 'يُرجى إدخال كلمة مرور';

  @override
  String get validationPasswordMin8 =>
      'يجب أن تتكوّن كلمة المرور من 8 أحرف على الأقل';

  @override
  String get fieldConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get fieldConfirmPasswordHint => 'اكتب كلمة المرور مرة أخرى';

  @override
  String get validationConfirmRequired => 'يُرجى تأكيد كلمة المرور';

  @override
  String get validationPasswordsMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get legalTerms => 'شروط الاستخدام';

  @override
  String get legalPrivacy => 'سياسة الخصوصية';

  @override
  String createAgree(String terms, String privacy) {
    return 'أوافق على $terms و$privacy';
  }

  @override
  String get createAgreeRequired =>
      'يُرجى الموافقة على شروط الاستخدام وسياسة الخصوصية';

  @override
  String get authErrorCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get authErrorUsernameRejected =>
      'اسم المستخدم هذا مستخدم بالفعل أو غير مسموح به. يُرجى اختيار اسم آخر.';

  @override
  String get authErrorUsernameTaken =>
      'اسم المستخدم هذا مستخدم بالفعل. استخدم اسم المستخدم الذي أعطاك إياه فريق الدراسة، أو تواصل مع فريق الرعاية إذا كان مسجّلًا من قبل.';

  @override
  String get authErrorDisabled =>
      'تم تعطيل هذا الحساب. يُرجى التواصل مع فريق الرعاية.';

  @override
  String get authErrorEmailNotConfirmed =>
      'يُرجى تأكيد بريدك الإلكتروني قبل تسجيل الدخول.';

  @override
  String get authErrorEmailExists =>
      'يوجد حساب بهذا البريد الإلكتروني بالفعل. جرّب تسجيل الدخول.';

  @override
  String get authErrorRateLimited =>
      'محاولات كثيرة جدًا. انتظر دقيقة ثم حاول مرة أخرى.';

  @override
  String get authErrorPassword => 'يُرجى اختيار كلمة مرور أخرى.';

  @override
  String get checkEmailTitle => 'تحقّق من بريدك الإلكتروني';

  @override
  String checkEmailBody(String email) {
    return 'أرسلنا رابط تأكيد إلى\n$email\nافتحه على هذا الجهاز لإكمال إنشاء حسابك.';
  }

  @override
  String get checkEmailResent => 'تمت إعادة إرسال رسالة التأكيد.';

  @override
  String get checkEmailResend => 'إعادة إرسال رسالة التأكيد';

  @override
  String get backToSignIn => 'العودة إلى تسجيل الدخول';

  @override
  String get forgotTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get forgotIntro =>
      'أدخل بريدك الإلكتروني وسنرسل إليك رابطًا لإعادة التعيين.';

  @override
  String forgotSent(String email) {
    return 'إذا كان هناك حساب مرتبط بـ $email، فسيصلك رابط إعادة التعيين قريبًا. افتحه على هذا الجهاز.';
  }

  @override
  String get forgotSend => 'إرسال رابط إعادة التعيين';

  @override
  String get resetTitle => 'اختر كلمة مرور جديدة';

  @override
  String get passwordMinShort => 'استخدم 8 أحرف على الأقل.';

  @override
  String get fieldNewPassword => 'كلمة المرور الجديدة';

  @override
  String get fieldConfirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get resetButton => 'تحديث كلمة المرور';

  @override
  String get gateTitle => 'عيّن كلمة مرور جديدة';

  @override
  String get gateBody =>
      'أنشأ فريق الرعاية هذا الحساب بكلمة مرور مؤقتة. يُرجى اختيار كلمة مرور خاصة بك للمتابعة.';

  @override
  String get gateRule =>
      '8 أحرف على الأقل، تتضمّن حرفًا كبيرًا وحرفًا صغيرًا ورقمًا.';

  @override
  String get gateErrorMix => 'يجب أن تتضمّن حرفًا كبيرًا وحرفًا صغيرًا ورقمًا.';

  @override
  String get gateSuccess => 'تم تحديث كلمة المرور. مرحبًا بك!';

  @override
  String get gateErrorSame => 'اختر كلمة مرور مختلفة عن المؤقتة.';

  @override
  String get gateErrorFailed => 'تعذّر تحديث كلمة المرور. تحقّق من اتصالك.';

  @override
  String get gateSave => 'حفظ كلمة المرور';

  @override
  String get menuOpen => 'فتح القائمة';

  @override
  String get menuAssessments => 'التقييمات الشاملة';

  @override
  String get menuAssessmentsSubtitle => 'استبيانات من فريق الرعاية';

  @override
  String get menuAssistance => 'أحتاج إلى مساعدة';

  @override
  String get menuAssistanceSubtitle => 'اطلب المساعدة من فريق الرعاية';

  @override
  String get menuMyRequests => 'طلبات المساعدة الخاصة بي';

  @override
  String get menuMyRequestsSubtitle => 'اطّلع على حالة ما أرسلته';

  @override
  String get menuEmergency => 'في حالات الطوارئ، اتصل بالرقم 911.';

  @override
  String get navEducation => 'التثقيف';

  @override
  String get navResources => 'الموارد';

  @override
  String get navProgress => 'التقدّم';

  @override
  String get navChat => 'الدردشة';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get crashTitle => 'حدث خطأ ما';

  @override
  String get crashBody =>
      'يُرجى إعادة تشغيل التطبيق. إذا استمرت المشكلة، تواصل مع فريق البحث.';

  @override
  String get homeGoodMorning => 'صباح الخير';

  @override
  String get homeGoodAfternoon => 'مساء الخير';

  @override
  String get homeGoodEvening => 'مساء الخير';

  @override
  String get homeHi => 'مرحبًا 👋';

  @override
  String homeHiName(String name) {
    return 'مرحبًا $name 👋';
  }

  @override
  String get homeTitle => 'مركزك\nللتثقيف الصحي';

  @override
  String get homeSearchHint => 'ابحث عن الدروس والمواضيع...';

  @override
  String get homeCategoryAll => 'الكل';

  @override
  String get homeNoLessons => 'لا توجد دروس متاحة بعد. عُد قريبًا.';

  @override
  String get homeNoMatches => 'لا توجد دروس تطابق بحثك.';

  @override
  String get progressCardTitle => 'تقدّمك';

  @override
  String progressCardLessons(int completed, int total) {
    return '$completed / $total دروس';
  }

  @override
  String get progressCardStart => 'لنبدأ!';

  @override
  String progressCardGreat(int percent) {
    return 'اكتمل $percent% — أداؤك رائع!';
  }

  @override
  String progressCardKeepGoing(int percent) {
    return 'اكتمل $percent% — واصل!';
  }

  @override
  String get progressCardDone => 'اكتمل 100% — عمل رائع!';

  @override
  String get lessonHeader => 'الدرس';

  @override
  String get lessonNoLessonsShort => 'لا توجد دروس متاحة بعد.';

  @override
  String get lessonNoneSelected => 'لم يتم اختيار درس.';

  @override
  String get lessonMarked => 'تم وضع علامة على الدرس كمكتمل. أحسنت!';

  @override
  String get lessonCompletedTitle => 'اكتمل الدرس';

  @override
  String get lessonFinishPrompt => 'هل أنهيت هذا الدرس؟';

  @override
  String get lessonCompletedBody => 'أحسنت! يمكنك العودة لمراجعته في أي وقت.';

  @override
  String get lessonFinishBody => 'ضع علامة على أنه مكتمل لمتابعة تقدّمك.';

  @override
  String get lessonMarkButton => 'وضع علامة كمكتمل';

  @override
  String lessonSections(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قسم',
      few: '$count أقسام',
      two: 'قسمان',
      one: 'قسم واحد',
    );
    return '$_temp0';
  }

  @override
  String get refTitle => 'المراجع';

  @override
  String get refLessonVideo => 'فيديو الدرس';

  @override
  String get refLessonAudio => 'التسجيل الصوتي للدرس';

  @override
  String get scriptTitle => 'ملاحظات الدرس';

  @override
  String get scriptReadMore => 'اقرأ المزيد';

  @override
  String get scriptShowLess => 'عرض أقل';

  @override
  String get infoTitle => 'إنفوجرافيك';

  @override
  String get infoCardTitle => 'إنفوجرافيك الدرس';

  @override
  String infoCardSubtitle(String title) {
    return 'ملخص مرئي لـ $title';
  }

  @override
  String infoSemantic(String title) {
    return 'إنفوجرافيك $title';
  }

  @override
  String get infoTapHint => 'اضغط على الصورة لعرضها بملء الشاشة وتكبيرها';

  @override
  String get imageOpenFullscreen => 'عرض بملء الشاشة';

  @override
  String get imageLoadFailed => 'تعذّر تحميل الصورة.';

  @override
  String get imageCloseFullscreen => 'إغلاق ملء الشاشة';

  @override
  String get imageZoomHint => 'باعِد بين إصبعين أو اضغط مرتين للتكبير';

  @override
  String get videoTitle => 'درس بالفيديو';

  @override
  String get videoPlaying => 'جارٍ تشغيل الفيديو';

  @override
  String get videoTapToPlay => 'اضغط لتشغيل الفيديو';

  @override
  String get videoYouTube => 'فيديو يوتيوب';

  @override
  String get audioTitle => 'درس صوتي';

  @override
  String get audioOpen => 'فتح التسجيل الصوتي';

  @override
  String get audioListen => 'استمع إلى هذا الدرس';

  @override
  String get kahootTitle => 'لعبة المعلومات';

  @override
  String get kahootMarked => 'عمل رائع! تم وضع علامة على الاختبار كمنتهٍ.';

  @override
  String get kahootCopied => 'تم نسخ اسم المستخدم.';

  @override
  String get kahootCopyTooltip => 'نسخ اسم المستخدم';

  @override
  String get kahootUsernameLabel => 'اسم المستخدم الخاص بك في Kahoot';

  @override
  String get kahootUsernameHint =>
      'استخدم اسم المستخدم هذا عندما تطلب لعبة Kahoot اسمًا مستعارًا';

  @override
  String get kahootIntro => 'اختبر ما تعلّمته من خلال لعبة Kahoot! تفاعلية';

  @override
  String get kahootBadgeTime => '⏱ نحو 5 دقائق';

  @override
  String get kahootBadgeInteractive => '✨ تفاعلي';

  @override
  String get kahootBadgeFun => '🎉 ممتع!';

  @override
  String get kahootStart => 'ابدأ لعبة Kahoot!';

  @override
  String get kahootEmbedHint =>
      'تُفتح اللعبة في الأسفل عند الضغط على الزر أعلاه';

  @override
  String get kahootFinished => 'انتهى الاختبار';

  @override
  String get kahootIFinished => 'أنهيت الاختبار';

  @override
  String get chatAiTitle => 'المساعد الذكي';

  @override
  String get chatAiSubtitle => 'إجابات آلية على مدار الساعة';

  @override
  String get chatTeamTitle => 'فريق البحث';

  @override
  String get chatTeamSubtitle => 'دراسة Happy Hearts';

  @override
  String get chatTabTeam => 'فريق الرعاية';

  @override
  String get chatSignInAi => 'يُرجى تسجيل الدخول لاستخدام المساعد الذكي.';

  @override
  String get chatSignIn => 'يُرجى تسجيل الدخول لاستخدام الدردشة.';

  @override
  String get chatNeedHelp => 'هل تحتاج إلى مساعدة؟';

  @override
  String get chatViewRequests => 'عرض طلباتي';

  @override
  String get chatEmptyTitle => 'ابدأ محادثة';

  @override
  String get chatEmptyBody =>
      'أرسل رسالة إلى فريق بحث Happy Hearts. نحن هنا لمساعدتك في أي سؤال عن دراستك.';

  @override
  String get chatNotSent => 'لم تُرسل';

  @override
  String get chatDelete => 'حذف';

  @override
  String get chatSending => 'جارٍ الإرسال…';

  @override
  String get chatInputHint => 'راسل فريق البحث...';

  @override
  String get chatSend => 'إرسال';

  @override
  String get chatErrorWrongAccount =>
      'لا يمكن لهذا الحساب استخدام دردشة المرضى. يُرجى تسجيل الدخول بحساب مريض.';

  @override
  String get chatErrorOpen => 'تعذّر فتح محادثتك. يُرجى المحاولة مرة أخرى.';

  @override
  String get chatErrorLoad =>
      'تعذّر تحميل الرسائل. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String get chatErrorKept =>
      'تعذّر الوصول إلى الخادم. تم الاحتفاظ برسالتك. اضغط «إعادة المحاولة».';

  @override
  String get chatErrorNoPermission =>
      'ليس لديك إذن بإرسال رسائل في هذه المحادثة.';

  @override
  String get chatErrorLength => 'يجب أن تتكوّن الرسالة من 1 إلى 4000 حرف.';

  @override
  String get chatErrorNotSent => 'لم تُرسل الرسالة. يُرجى المحاولة مرة أخرى.';

  @override
  String get chatErrorGeneric => 'حدث خطأ أثناء تحميل محادثتك.';

  @override
  String get aiErrorConnection => 'تعذّر تحميل المساعد الذكي. تحقّق من اتصالك.';

  @override
  String get aiErrorUnavailable => 'المساعد الذكي غير متاح الآن.';

  @override
  String get aiErrorStart => 'تعذّر تشغيل المساعد الذكي.';

  @override
  String get aiErrorTimeout => 'يستغرق تحميل المساعد الذكي وقتًا طويلًا.';

  @override
  String get aiWebOnly =>
      'المساعد الذكي متاح في تطبيق HappyHearts على iOS وAndroid.';

  @override
  String get assistMyRequests => 'طلباتي';

  @override
  String get assistIntro =>
      'أخبر فريق البحث بما تحتاج المساعدة فيه. سيتابع معك أحد أعضاء الفريق، عادةً برسالة في دردشة «فريق الرعاية».';

  @override
  String get assistEmergency =>
      'لا تتم مراقبة هذه الطلبات على مدار الساعة. إذا كانت حالة طارئة، اتصل بالرقم 911.';

  @override
  String get assistHint =>
      'مثال: «لدي سؤال عن دوائي» أو «فيديو الجلسة 3 لا يعمل.»';

  @override
  String get assistSend => 'إرسال الطلب';

  @override
  String get assistErrorEmpty => 'يُرجى وصف ما تحتاج المساعدة فيه.';

  @override
  String assistErrorTooLong(int max) {
    return 'يُرجى ألا تتجاوز رسالتك $max حرف.';
  }

  @override
  String get assistErrorOffline =>
      'تعذّر الوصول إلى الخادم. تم الاحتفاظ برسالتك، يُرجى المحاولة مرة أخرى.';

  @override
  String get assistErrorLoad =>
      'تعذّر تحميل طلباتك. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String get assistErrorNotParticipant =>
      'يمكن لحسابات المشاركين فقط إرسال طلبات المساعدة.';

  @override
  String assistErrorLength(int max) {
    return 'يُرجى كتابة رسالة بين 1 و$max حرف.';
  }

  @override
  String get assistErrorRateLimited =>
      'لقد أرسلت عدة طلبات مؤخرًا. سيرد عليك الفريق قريبًا. إذا كان الأمر عاجلًا، اتصل بفريق الرعاية. في حالات الطوارئ، اتصل بالرقم 911.';

  @override
  String get assistErrorNotSent =>
      'لم يُرسل طلبك. تم الاحتفاظ برسالتك، يُرجى المحاولة مرة أخرى.';

  @override
  String get requestsTitle => 'طلبات المساعدة الخاصة بي';

  @override
  String get requestsNew => 'طلب جديد';

  @override
  String get requestsEmptyTitle => 'لا توجد طلبات بعد';

  @override
  String get requestsEmptyBody =>
      'عندما تحتاج إلى مساعدة من فريق البحث، أرسل طلبًا ويمكنك متابعة حالته هنا.';

  @override
  String get requestStatusSent => 'تم الإرسال';

  @override
  String get requestStatusSeen => 'اطّلع عليه الفريق';

  @override
  String get requestStatusResolved => 'تم الحل';

  @override
  String get requestWaiting => 'في انتظار مراجعة أحد أعضاء الفريق.';

  @override
  String get requestFollowing => 'يتابع أحد أعضاء الفريق طلبك.';

  @override
  String requestFollowingSince(String time) {
    return 'يتابع أحد أعضاء الفريق طلبك ($time).';
  }

  @override
  String get requestResolved => 'تم وضع علامة «تم الحل».';

  @override
  String requestResolvedSince(String time) {
    return 'تم وضع علامة «تم الحل» ($time).';
  }

  @override
  String get assessSubtitleSurvey => 'استبيانات من فريق الرعاية.';

  @override
  String get assessSubtitleResources =>
      'تابع صحتك النفسية والجسدية باستخدام أدوات الفحص المعتمدة هذه.';

  @override
  String get assessEmptySurvey =>
      'لا توجد تقييمات شاملة الآن. سيضيفها فريق الرعاية هنا.';

  @override
  String get assessEmptyResources =>
      'لا توجد موارد الآن. سيضيفها فريق الرعاية هنا.';

  @override
  String get assessUsernameError =>
      'تعذّر تحميل اسم المستخدم. يُرجى المحاولة مرة أخرى.';

  @override
  String assessLastCompleted(String date) {
    return 'آخر إكمال: $date';
  }

  @override
  String get assessStart => 'ابدأ التقييم';

  @override
  String get surveyErrorLoad =>
      'تعذّر تحميل الاستبيانات. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String get surveyRecordFailed =>
      'تم إرسال إجاباتك، لكن التطبيق لم يتمكن من تسجيل الاستبيان كمكتمل.';

  @override
  String get surveyThanks => 'شكرًا لك!';

  @override
  String get surveyThanksBody =>
      'تم إرسال إجاباتك. يمكنك رؤية هذا الاستبيان في تقويم «التقدّم».';

  @override
  String get surveyLoading => 'جارٍ تحميل الاستبيان...';

  @override
  String get surveyLoadFailedTitle => 'تعذّر تحميل الاستبيان';

  @override
  String get surveyLoadFailedBody =>
      'يُرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';

  @override
  String get progressSubtitle => 'تابع رحلة تعلّمك واحتفل بإنجازاتك.';

  @override
  String get progressCalendar => 'تقويم النشاط';

  @override
  String get progressBreakdown => 'الدروس';

  @override
  String activityCompleted(String title) {
    return 'مكتمل: $title';
  }

  @override
  String activityQuizFinished(String title) {
    return 'اختبار منتهٍ: $title';
  }

  @override
  String activitySurveyFallback(String code) {
    return 'استبيان ($code)';
  }

  @override
  String get calPrevMonth => 'الشهر السابق';

  @override
  String get calNextMonth => 'الشهر التالي';

  @override
  String get legendLesson => 'درس';

  @override
  String get legendQuiz => 'اختبار';

  @override
  String get legendSurvey => 'استبيان';

  @override
  String get calLessonDone => 'اكتمل درس';

  @override
  String get calQuizDone => 'انتهى اختبار';

  @override
  String get calSurveyDone => 'اكتمل استبيان';

  @override
  String get activityRecent => 'النشاط الأخير';

  @override
  String activityOnDay(String date) {
    return 'النشاط في $date';
  }

  @override
  String get activityShowAll => 'عرض الكل';

  @override
  String get activityEmpty => 'أكمل درسًا أو اختبارًا أو استبيانًا وسيظهر هنا.';

  @override
  String get activityEmptyDay => 'لم يكتمل شيء في هذا اليوم.';

  @override
  String get overallTitle => 'نسبة الإكمال الكلية';

  @override
  String overallCount(int completed, int total) {
    return '$completed من $total دروس';
  }

  @override
  String get overallAllDone => '🎉 اكتملت كل الدروس!';

  @override
  String get overallKeepGoing => 'واصل — أنت تحرز تقدّمًا رائعًا!';

  @override
  String get overallStart => 'ابدأ درسك الأول.';

  @override
  String get statTimeSpent => 'الوقت المستغرق';

  @override
  String timeSpentSuffix(String time) {
    return '$time مستغرقة';
  }

  @override
  String get profileSignOutConfirm => 'هل أنت متأكد من أنك تريد تسجيل الخروج؟';

  @override
  String profileResetSent(String email) {
    return 'تم إرسال رابط إعادة تعيين كلمة المرور إلى $email';
  }

  @override
  String get profileAccount => 'الحساب';

  @override
  String get profileChangePassword =>
      'تغيير كلمة المرور (إرسال رسالة إعادة التعيين)';

  @override
  String get profilePreferences => 'التفضيلات';

  @override
  String get profileAbout => 'حول';

  @override
  String get profileVersion => 'إصدار التطبيق';

  @override
  String get profileNotAvailable => 'ملفك الشخصي غير متاح.';

  @override
  String get profileEditName => 'تعديل الاسم';

  @override
  String get profileLearningSummary => 'ملخص التعلّم';

  @override
  String get profileStatComplete => 'الإكمال';

  @override
  String get profileProgressFailed =>
      'تعذّر تحميل تقدّمك. اضغط لإعادة المحاولة.';

  @override
  String get profileErrorSignIn => 'يُرجى تسجيل الدخول.';

  @override
  String get profileErrorSessionChanged =>
      'تغيّرت الجلسة. يُرجى المحاولة مرة أخرى.';

  @override
  String get profileErrorMissing =>
      'تعذّر العثور على ملفك الشخصي. اسحب لأسفل لإعادة المحاولة، وإذا استمرت المشكلة فتواصل مع فريق البحث.';

  @override
  String get profileErrorPermission => 'ليس لديك إذن بعرض هذا الملف الشخصي.';

  @override
  String get profileErrorLoad =>
      'تعذّر تحميل ملفك الشخصي. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String get profileErrorNameEmpty => 'لا يمكن ترك الاسم فارغًا.';

  @override
  String get profileErrorSaveName =>
      'تعذّر حفظ اسمك. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String get contentErrorLessons =>
      'تعذّر تحميل الدروس. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String get contentErrorProgress =>
      'تعذّر تحميل تقدّمك. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String get materialsTitle => 'المواد';

  @override
  String get materialsPdf => 'مستند PDF';

  @override
  String materialsPdfSize(String size) {
    return 'PDF · $size';
  }

  @override
  String fileSizeMb(String size) {
    return '$size ميجابايت';
  }

  @override
  String fileSizeKb(String size) {
    return '$size كيلوبايت';
  }

  @override
  String materialsOpenImage(String name) {
    return 'فتح الصورة: $name';
  }

  @override
  String materialsOpenPdf(String name) {
    return 'فتح ملف PDF: $name';
  }

  @override
  String get listSeparator => '، ';

  @override
  String get msgLangTitle => 'تحقّق من لغة رسالتك';

  @override
  String msgLangBody(String languages) {
    return 'يقرأ فريق البحث هذه اللغات فقط: $languages. قد لا يتمكنون من فهم رسالتك.';
  }

  @override
  String get msgLangSendAnyway => 'أرسل على أي حال';

  @override
  String get msgLangEdit => 'تعديل الرسالة';
}
