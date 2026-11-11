// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get retry => '重试';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get done => '完成';

  @override
  String get close => '关闭';

  @override
  String get back => '返回';

  @override
  String get view => '查看';

  @override
  String get signOut => '退出登录';

  @override
  String get errorGeneric => '出了点问题，请再试一次。';

  @override
  String get errorConnection => '出了点问题。请检查网络连接后再试一次。';

  @override
  String get errorServerUnreachable => '无法连接服务器。请检查网络连接后再试一次。';

  @override
  String get couldNotOpenLink => '无法打开这个链接。';

  @override
  String get requestSent => '请求已发送，团队成员会与您联系。';

  @override
  String get statusCompleted => '已完成';

  @override
  String get statusInProgress => '进行中';

  @override
  String get statusAvailable => '可开始';

  @override
  String get statusNotStarted => '未开始';

  @override
  String get dateToday => '今天';

  @override
  String get dateYesterday => '昨天';

  @override
  String dateTodayAt(String time) {
    return '今天 $time';
  }

  @override
  String dateYesterdayAt(String time) {
    return '昨天 $time';
  }

  @override
  String dateAt(String date, String time) {
    return '$date $time';
  }

  @override
  String minutesShort(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String timeMinutes(int minutes) {
    return '$minutes 分';
  }

  @override
  String timeHoursMinutes(int hours, int minutes) {
    return '$hours 小时 $minutes 分';
  }

  @override
  String linkSemantic(String text) {
    return '链接：$text';
  }

  @override
  String get languageTitle => '语言';

  @override
  String get languagePhone => '手机语言';

  @override
  String languagePhoneDetail(String language) {
    return '与手机相同（$language）';
  }

  @override
  String get languagePickerTitle => '选择语言';

  @override
  String languageButtonSemantic(String language) {
    return '语言：$language。点按即可更改。';
  }

  @override
  String get authTagline => '您的个人健康教育伙伴';

  @override
  String get authTabSignIn => '登录';

  @override
  String get authTabCreateAccount => '创建账户';

  @override
  String get signInWelcome => '欢迎回来 👋';

  @override
  String get signInSubtitle => '登录以继续您的健康学习';

  @override
  String get fieldEmail => '电子邮箱';

  @override
  String get fieldEmailHint => '输入您的电子邮箱';

  @override
  String get validationEmailRequired => '请输入电子邮箱';

  @override
  String get validationEmailInvalid => '请输入有效的电子邮箱';

  @override
  String get fieldPassword => '密码';

  @override
  String get fieldPasswordHint => '输入您的密码';

  @override
  String get validationPasswordRequired => '请输入密码';

  @override
  String get showPassword => '显示密码';

  @override
  String get hidePassword => '隐藏密码';

  @override
  String get signInForgot => '忘记密码？';

  @override
  String get createTitle => '创建您的账户';

  @override
  String get createSubtitle => '今天就开始您的健康学习';

  @override
  String get fieldFullName => '姓名';

  @override
  String get fieldFullNameHint => '输入您的姓名';

  @override
  String get validationNameRequired => '请输入姓名';

  @override
  String get fieldUsername => '用户名';

  @override
  String get fieldUsernameHint => '研究团队给您的用户名';

  @override
  String get fieldUsernameHelper => '请使用研究团队给您的用户名。它会把您的问卷和账户关联起来，之后无法更改。';

  @override
  String get validationUsernameRequired => '请输入用户名';

  @override
  String get validationUsernameFormat => '请使用 3–20 个英文字母或数字（不含空格或符号）';

  @override
  String get fieldPhone => '电话号码';

  @override
  String get fieldPhoneHint => '例如：(949) 555-0100';

  @override
  String get validationPhoneRequired => '请输入电话号码';

  @override
  String get validationPhoneInvalid => '请输入有效的电话号码';

  @override
  String get fieldCreatePasswordHint => '设置密码';

  @override
  String get validationNewPasswordRequired => '请输入密码';

  @override
  String get validationPasswordMin8 => '密码至少需要 8 个字符';

  @override
  String get fieldConfirmPassword => '确认密码';

  @override
  String get fieldConfirmPasswordHint => '再输入一次密码';

  @override
  String get validationConfirmRequired => '请确认密码';

  @override
  String get validationPasswordsMismatch => '两次输入的密码不一致';

  @override
  String get legalTerms => '使用条款';

  @override
  String get legalPrivacy => '隐私政策';

  @override
  String createAgree(String terms, String privacy) {
    return '我同意$terms和$privacy';
  }

  @override
  String get createAgreeRequired => '请同意使用条款和隐私政策';

  @override
  String get authErrorCredentials => '电子邮箱或密码不正确。';

  @override
  String get authErrorUsernameRejected => '这个用户名已被使用或不允许使用，请换一个。';

  @override
  String get authErrorUsernameTaken =>
      '这个用户名已被使用。请使用研究团队给您的用户名；如果它已经注册，请联系护理团队。';

  @override
  String get authErrorDisabled => '这个账户已停用，请联系您的护理团队。';

  @override
  String get authErrorEmailNotConfirmed => '登录前请先验证您的电子邮箱。';

  @override
  String get authErrorEmailExists => '这个电子邮箱已有账户，请尝试登录。';

  @override
  String get authErrorRateLimited => '尝试次数过多，请等一分钟后再试。';

  @override
  String get authErrorPassword => '请换一个密码。';

  @override
  String get checkEmailTitle => '请查看您的电子邮箱';

  @override
  String checkEmailBody(String email) {
    return '我们已把验证链接发送到\n$email\n请在这台设备上打开链接，完成创建账户。';
  }

  @override
  String get checkEmailResent => '已重新发送验证邮件。';

  @override
  String get checkEmailResend => '重新发送验证邮件';

  @override
  String get backToSignIn => '返回登录';

  @override
  String get forgotTitle => '重置密码';

  @override
  String get forgotIntro => '输入您的电子邮箱，我们会给您发送重置链接。';

  @override
  String forgotSent(String email) {
    return '如果 $email 有账户，重置链接很快就会发到。请在这台设备上打开。';
  }

  @override
  String get forgotSend => '发送重置链接';

  @override
  String get resetTitle => '设置新密码';

  @override
  String get passwordMinShort => '请使用至少 8 个字符。';

  @override
  String get fieldNewPassword => '新密码';

  @override
  String get fieldConfirmNewPassword => '确认新密码';

  @override
  String get resetButton => '更新密码';

  @override
  String get gateTitle => '设置新的密码';

  @override
  String get gateBody => '您的护理团队用临时密码创建了这个账户。请设置您自己的密码后继续。';

  @override
  String get gateRule => '至少 8 个字符，包含大写字母、小写字母和数字。';

  @override
  String get gateErrorMix => '请包含大写字母、小写字母和数字。';

  @override
  String get gateSuccess => '密码已更新，欢迎！';

  @override
  String get gateErrorSame => '请选择与临时密码不同的密码。';

  @override
  String get gateErrorFailed => '无法更新密码，请检查网络连接。';

  @override
  String get gateSave => '保存密码';

  @override
  String get menuOpen => '打开菜单';

  @override
  String get menuAssessments => '整体评估';

  @override
  String get menuAssessmentsSubtitle => '护理团队提供的问卷';

  @override
  String get menuAssistance => '我需要帮助';

  @override
  String get menuAssistanceSubtitle => '向护理团队求助';

  @override
  String get menuMyRequests => '我的求助记录';

  @override
  String get menuMyRequestsSubtitle => '查看已发送请求的状态';

  @override
  String get menuEmergency => '紧急情况请拨打 911。';

  @override
  String get navEducation => '课程';

  @override
  String get navResources => '资源';

  @override
  String get navProgress => '进度';

  @override
  String get navChat => '聊天';

  @override
  String get navProfile => '个人资料';

  @override
  String get crashTitle => '出了点问题';

  @override
  String get crashBody => '请重新启动应用。如果问题一直出现，请联系研究团队。';

  @override
  String get homeGoodMorning => '早上好';

  @override
  String get homeGoodAfternoon => '下午好';

  @override
  String get homeGoodEvening => '晚上好';

  @override
  String get homeHi => '您好 👋';

  @override
  String homeHiName(String name) {
    return '$name，您好 👋';
  }

  @override
  String get homeTitle => '您的健康\n教育中心';

  @override
  String get homeSearchHint => '搜索课程、主题…';

  @override
  String get homeCategoryAll => '全部';

  @override
  String get homeNoLessons => '目前还没有课程，请稍后再来看看。';

  @override
  String get homeNoMatches => '没有找到符合搜索的课程。';

  @override
  String get progressCardTitle => '您的进度';

  @override
  String progressCardLessons(int completed, int total) {
    return '$completed / $total 节课';
  }

  @override
  String get progressCardStart => '我们开始吧！';

  @override
  String progressCardGreat(int percent) {
    return '已完成 $percent%，做得很好！';
  }

  @override
  String progressCardKeepGoing(int percent) {
    return '已完成 $percent%，继续加油！';
  }

  @override
  String get progressCardDone => '已完成 100%，太棒了！';

  @override
  String get lessonHeader => '课程';

  @override
  String get lessonNoLessonsShort => '目前还没有课程。';

  @override
  String get lessonNoneSelected => '还没有选择课程。';

  @override
  String get lessonMarked => '已将课程标记为完成，做得好！';

  @override
  String get lessonCompletedTitle => '课程已完成';

  @override
  String get lessonFinishPrompt => '学完这节课了吗？';

  @override
  String get lessonCompletedBody => '做得好！您随时可以回来复习。';

  @override
  String get lessonFinishBody => '标记为完成，就能跟踪您的进度。';

  @override
  String get lessonMarkButton => '标记为完成';

  @override
  String lessonSections(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个部分',
    );
    return '$_temp0';
  }

  @override
  String get refTitle => '参考资料';

  @override
  String get refLessonVideo => '课程视频';

  @override
  String get refLessonAudio => '课程音频';

  @override
  String get scriptTitle => '课程笔记';

  @override
  String get scriptReadMore => '阅读更多';

  @override
  String get scriptShowLess => '收起';

  @override
  String get infoTitle => '信息图';

  @override
  String get infoCardTitle => '课程信息图';

  @override
  String infoCardSubtitle(String title) {
    return '$title的图解摘要';
  }

  @override
  String infoSemantic(String title) {
    return '$title的信息图';
  }

  @override
  String get infoTapHint => '点按图片即可全屏查看并放大';

  @override
  String get imageOpenFullscreen => '全屏查看';

  @override
  String get imageLoadFailed => '无法加载图片。';

  @override
  String get imageCloseFullscreen => '关闭全屏';

  @override
  String get imageZoomHint => '双指缩放或点按两下放大';

  @override
  String get videoTitle => '视频课程';

  @override
  String get videoPlaying => '正在播放视频';

  @override
  String get videoTapToPlay => '点按播放视频';

  @override
  String get videoYouTube => 'YouTube 视频';

  @override
  String get audioTitle => '音频课程';

  @override
  String get audioOpen => '打开音频';

  @override
  String get audioListen => '收听这节课';

  @override
  String get kahootTitle => '知识小游戏';

  @override
  String get kahootMarked => '做得好！已将测验标记为完成。';

  @override
  String get kahootCopied => '已复制用户名。';

  @override
  String get kahootCopyTooltip => '复制用户名';

  @override
  String get kahootUsernameLabel => '您的 Kahoot 用户名';

  @override
  String get kahootUsernameHint => 'Kahoot 游戏要求输入昵称时，请使用这个用户名';

  @override
  String get kahootIntro => '用互动的 Kahoot! 游戏测试您学到的内容';

  @override
  String get kahootBadgeTime => '⏱ 约 5 分钟';

  @override
  String get kahootBadgeInteractive => '✨ 互动式';

  @override
  String get kahootBadgeFun => '🎉 好玩！';

  @override
  String get kahootStart => '开始 Kahoot! 游戏';

  @override
  String get kahootEmbedHint => '点按上方按钮，游戏会在下方打开';

  @override
  String get kahootFinished => '测验已完成';

  @override
  String get kahootIFinished => '我完成测验了';

  @override
  String get chatAiTitle => 'AI 助手';

  @override
  String get chatAiSubtitle => '自动回答，全天候';

  @override
  String get chatTeamTitle => '研究团队';

  @override
  String get chatTeamSubtitle => 'Happy Hearts 研究';

  @override
  String get chatTabTeam => '护理团队';

  @override
  String get chatSignInAi => '请登录以使用 AI 助手。';

  @override
  String get chatSignIn => '请登录以使用聊天功能。';

  @override
  String get chatNeedHelp => '需要帮助吗？';

  @override
  String get chatViewRequests => '查看我的请求';

  @override
  String get chatEmptyTitle => '开始对话';

  @override
  String get chatEmptyBody => '给 Happy Hearts 研究团队发消息。有任何关于研究的问题，我们都乐意帮忙。';

  @override
  String get chatNotSent => '未发送';

  @override
  String get chatDelete => '删除';

  @override
  String get chatSending => '发送中…';

  @override
  String get chatInputHint => '给研究团队发消息…';

  @override
  String get chatSend => '发送';

  @override
  String get chatErrorWrongAccount => '这个账户无法使用患者聊天功能，请用患者账户登录。';

  @override
  String get chatErrorOpen => '无法打开您的对话，请再试一次。';

  @override
  String get chatErrorLoad => '无法加载消息。请检查网络连接后再试一次。';

  @override
  String get chatErrorKept => '无法连接服务器。您的消息已保留，请点按“重试”。';

  @override
  String get chatErrorNoPermission => '您没有在这个对话中发送消息的权限。';

  @override
  String get chatErrorLength => '消息长度需为 1 到 4000 个字符。';

  @override
  String get chatErrorNotSent => '消息未发送，请再试一次。';

  @override
  String get chatErrorGeneric => '加载对话时出了点问题。';

  @override
  String get aiErrorConnection => '无法加载 AI 助手，请检查网络连接。';

  @override
  String get aiErrorUnavailable => 'AI 助手目前无法使用。';

  @override
  String get aiErrorStart => '无法启动 AI 助手。';

  @override
  String get aiErrorTimeout => 'AI 助手加载时间过长。';

  @override
  String get aiWebOnly => 'AI 助手可在 HappyHearts 的 iOS 和 Android 应用中使用。';

  @override
  String get assistMyRequests => '我的请求';

  @override
  String get assistIntro => '告诉研究团队您需要什么帮助。团队成员会跟进，通常是通过“护理团队”聊天消息。';

  @override
  String get assistEmergency => '这里不是 24 小时有人查看。如有紧急情况，请拨打 911。';

  @override
  String get assistHint => '例如：“我对我的药物有疑问”或“第 3 节课的视频无法播放。”';

  @override
  String get assistSend => '发送请求';

  @override
  String get assistErrorEmpty => '请说明您需要什么帮助。';

  @override
  String assistErrorTooLong(int max) {
    return '消息请少于 $max 个字符。';
  }

  @override
  String get assistErrorOffline => '无法连接服务器。您的消息已保留，请再试一次。';

  @override
  String get assistErrorLoad => '无法加载您的请求。请检查网络连接后再试一次。';

  @override
  String get assistErrorNotParticipant => '只有参与者账户可以发送求助请求。';

  @override
  String assistErrorLength(int max) {
    return '请输入 1 到 $max 个字符的消息。';
  }

  @override
  String get assistErrorRateLimited =>
      '您最近已发送多个请求，团队很快会回复您。如果情况紧急，请给您的护理团队打电话；紧急情况请拨打 911。';

  @override
  String get assistErrorNotSent => '请求未发送。您的消息已保留，请再试一次。';

  @override
  String get requestsTitle => '我的求助请求';

  @override
  String get requestsNew => '新请求';

  @override
  String get requestsEmptyTitle => '还没有请求';

  @override
  String get requestsEmptyBody => '需要研究团队帮助时，发送请求后就能在这里跟踪状态。';

  @override
  String get requestStatusSent => '已发送';

  @override
  String get requestStatusSeen => '团队已查看';

  @override
  String get requestStatusResolved => '已解决';

  @override
  String get requestWaiting => '正在等待团队成员查看。';

  @override
  String get requestFollowing => '团队成员正在跟进。';

  @override
  String requestFollowingSince(String time) {
    return '团队成员正在跟进（$time）。';
  }

  @override
  String get requestResolved => '已标记为解决。';

  @override
  String requestResolvedSince(String time) {
    return '已标记为解决（$time）。';
  }

  @override
  String get assessSubtitleSurvey => '护理团队提供的问卷。';

  @override
  String get assessSubtitleResources => '用这些经过验证的筛查工具跟踪您的身心健康。';

  @override
  String get assessEmptySurvey => '目前没有整体评估，护理团队会在这里添加。';

  @override
  String get assessEmptyResources => '目前没有资源，护理团队会在这里添加。';

  @override
  String get assessUsernameError => '无法加载您的用户名，请再试一次。';

  @override
  String assessLastCompleted(String date) {
    return '上次完成：$date';
  }

  @override
  String get assessStart => '开始评估';

  @override
  String get surveyErrorLoad => '无法加载问卷。请检查网络连接后再试一次。';

  @override
  String get surveyRecordFailed => '您的答案已提交，但应用无法将问卷标记为完成。';

  @override
  String get surveyThanks => '谢谢您！';

  @override
  String get surveyThanksBody => '您的回答已提交，可以在“进度”日历中看到这份问卷。';

  @override
  String get surveyLoading => '正在加载问卷…';

  @override
  String get surveyLoadFailedTitle => '无法加载问卷';

  @override
  String get surveyLoadFailedBody => '请检查网络连接后再试一次。';

  @override
  String get progressSubtitle => '跟踪您的学习历程，庆祝每个里程碑。';

  @override
  String get progressCalendar => '活动日历';

  @override
  String get progressBreakdown => '各课程进度';

  @override
  String activityCompleted(String title) {
    return '已完成：$title';
  }

  @override
  String activityQuizFinished(String title) {
    return '已完成测验：$title';
  }

  @override
  String activitySurveyFallback(String code) {
    return '问卷（$code）';
  }

  @override
  String get calPrevMonth => '上个月';

  @override
  String get calNextMonth => '下个月';

  @override
  String get legendLesson => '课程';

  @override
  String get legendQuiz => '测验';

  @override
  String get legendSurvey => '问卷';

  @override
  String get calLessonDone => '完成课程';

  @override
  String get calQuizDone => '完成测验';

  @override
  String get calSurveyDone => '完成问卷';

  @override
  String get activityRecent => '最近活动';

  @override
  String activityOnDay(String date) {
    return '$date 的活动';
  }

  @override
  String get activityShowAll => '显示全部';

  @override
  String get activityEmpty => '完成课程、测验或问卷后，就会显示在这里。';

  @override
  String get activityEmptyDay => '这天没有完成任何项目。';

  @override
  String get overallTitle => '总体完成度';

  @override
  String overallCount(int completed, int total) {
    return '$total 节课中完成 $completed 节';
  }

  @override
  String get overallAllDone => '🎉 所有课程都完成了！';

  @override
  String get overallKeepGoing => '继续加油，您进步得很好！';

  @override
  String get overallStart => '从第一节课开始吧。';

  @override
  String get statTimeSpent => '学习时间';

  @override
  String timeSpentSuffix(String time) {
    return '已学习 $time';
  }

  @override
  String get profileSignOutConfirm => '确定要退出登录吗？';

  @override
  String profileResetSent(String email) {
    return '已将重置密码链接发送到 $email';
  }

  @override
  String get profileAccount => '账户';

  @override
  String get profileChangePassword => '更改密码（发送重置邮件）';

  @override
  String get profilePreferences => '偏好设置';

  @override
  String get profileAbout => '关于';

  @override
  String get profileVersion => '应用版本';

  @override
  String get profileNotAvailable => '无法获取您的个人资料。';

  @override
  String get profileEditName => '编辑姓名';

  @override
  String get profileLearningSummary => '学习摘要';

  @override
  String get profileStatComplete => '完成度';

  @override
  String get profileProgressFailed => '无法加载您的进度，点按重试。';

  @override
  String get profileErrorSignIn => '请登录。';

  @override
  String get profileErrorSessionChanged => '登录状态已变化，请再试一次。';

  @override
  String get profileErrorMissing => '找不到您的个人资料。请下拉重试；如果一直出现，请联系研究团队。';

  @override
  String get profileErrorPermission => '您没有查看这份个人资料的权限。';

  @override
  String get profileErrorLoad => '无法加载您的个人资料。请检查网络连接后再试一次。';

  @override
  String get profileErrorNameEmpty => '姓名不能为空。';

  @override
  String get profileErrorSaveName => '无法保存您的姓名。请检查网络连接后再试一次。';

  @override
  String get contentErrorLessons => '无法加载课程。请检查网络连接后再试一次。';

  @override
  String get contentErrorProgress => '无法加载您的进度。请检查网络连接后再试一次。';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get retry => '重試';

  @override
  String get cancel => '取消';

  @override
  String get save => '儲存';

  @override
  String get done => '完成';

  @override
  String get close => '關閉';

  @override
  String get back => '返回';

  @override
  String get view => '查看';

  @override
  String get signOut => '登出';

  @override
  String get errorGeneric => '發生錯誤，請再試一次。';

  @override
  String get errorConnection => '發生錯誤。請檢查網路連線後再試一次。';

  @override
  String get errorServerUnreachable => '無法連線到伺服器。請檢查網路連線後再試一次。';

  @override
  String get couldNotOpenLink => '無法開啟這個連結。';

  @override
  String get requestSent => '已送出請求，團隊成員會與您聯絡。';

  @override
  String get statusCompleted => '已完成';

  @override
  String get statusInProgress => '進行中';

  @override
  String get statusAvailable => '可開始';

  @override
  String get statusNotStarted => '尚未開始';

  @override
  String get dateToday => '今天';

  @override
  String get dateYesterday => '昨天';

  @override
  String dateTodayAt(String time) {
    return '今天 $time';
  }

  @override
  String dateYesterdayAt(String time) {
    return '昨天 $time';
  }

  @override
  String dateAt(String date, String time) {
    return '$date $time';
  }

  @override
  String minutesShort(int minutes) {
    return '$minutes 分鐘';
  }

  @override
  String timeMinutes(int minutes) {
    return '$minutes 分';
  }

  @override
  String timeHoursMinutes(int hours, int minutes) {
    return '$hours 小時 $minutes 分';
  }

  @override
  String linkSemantic(String text) {
    return '連結：$text';
  }

  @override
  String get languageTitle => '語言';

  @override
  String get languagePhone => '手機語言';

  @override
  String languagePhoneDetail(String language) {
    return '與手機相同（$language）';
  }

  @override
  String get languagePickerTitle => '選擇語言';

  @override
  String languageButtonSemantic(String language) {
    return '語言：$language。點一下即可變更。';
  }

  @override
  String get authTagline => '您的個人健康教育夥伴';

  @override
  String get authTabSignIn => '登入';

  @override
  String get authTabCreateAccount => '建立帳戶';

  @override
  String get signInWelcome => '歡迎回來 👋';

  @override
  String get signInSubtitle => '登入以繼續您的健康學習';

  @override
  String get fieldEmail => '電子郵件地址';

  @override
  String get fieldEmailHint => '輸入您的電子郵件';

  @override
  String get validationEmailRequired => '請輸入電子郵件';

  @override
  String get validationEmailInvalid => '請輸入有效的電子郵件';

  @override
  String get fieldPassword => '密碼';

  @override
  String get fieldPasswordHint => '輸入您的密碼';

  @override
  String get validationPasswordRequired => '請輸入密碼';

  @override
  String get showPassword => '顯示密碼';

  @override
  String get hidePassword => '隱藏密碼';

  @override
  String get signInForgot => '忘記密碼？';

  @override
  String get createTitle => '建立您的帳戶';

  @override
  String get createSubtitle => '今天就開始您的健康學習';

  @override
  String get fieldFullName => '姓名';

  @override
  String get fieldFullNameHint => '輸入您的姓名';

  @override
  String get validationNameRequired => '請輸入姓名';

  @override
  String get fieldUsername => '使用者名稱';

  @override
  String get fieldUsernameHint => '研究團隊給您的使用者名稱';

  @override
  String get fieldUsernameHelper => '請使用研究團隊給您的使用者名稱。它會把您的問卷和帳戶連結起來，之後無法更改。';

  @override
  String get validationUsernameRequired => '請輸入使用者名稱';

  @override
  String get validationUsernameFormat => '請使用 3–20 個英文字母或數字（不含空格或符號）';

  @override
  String get fieldPhone => '電話號碼';

  @override
  String get fieldPhoneHint => '例如：(949) 555-0100';

  @override
  String get validationPhoneRequired => '請輸入電話號碼';

  @override
  String get validationPhoneInvalid => '請輸入有效的電話號碼';

  @override
  String get fieldCreatePasswordHint => '設定密碼';

  @override
  String get validationNewPasswordRequired => '請輸入密碼';

  @override
  String get validationPasswordMin8 => '密碼至少需要 8 個字元';

  @override
  String get fieldConfirmPassword => '確認密碼';

  @override
  String get fieldConfirmPasswordHint => '再輸入一次密碼';

  @override
  String get validationConfirmRequired => '請確認密碼';

  @override
  String get validationPasswordsMismatch => '兩次輸入的密碼不一致';

  @override
  String get legalTerms => '使用條款';

  @override
  String get legalPrivacy => '隱私權政策';

  @override
  String createAgree(String terms, String privacy) {
    return '我同意$terms和$privacy';
  }

  @override
  String get createAgreeRequired => '請同意使用條款和隱私權政策';

  @override
  String get authErrorCredentials => '電子郵件或密碼不正確。';

  @override
  String get authErrorUsernameRejected => '這個使用者名稱已被使用或不允許使用，請換一個。';

  @override
  String get authErrorUsernameTaken =>
      '這個使用者名稱已被使用。請使用研究團隊給您的使用者名稱；如果它已經註冊，請聯絡照護團隊。';

  @override
  String get authErrorDisabled => '這個帳戶已停用，請聯絡您的照護團隊。';

  @override
  String get authErrorEmailNotConfirmed => '登入前請先確認您的電子郵件。';

  @override
  String get authErrorEmailExists => '這個電子郵件已有帳戶，請試著登入。';

  @override
  String get authErrorRateLimited => '嘗試次數過多，請等一分鐘後再試。';

  @override
  String get authErrorPassword => '請改用其他密碼。';

  @override
  String get checkEmailTitle => '請查看您的電子郵件';

  @override
  String checkEmailBody(String email) {
    return '我們已把確認連結寄到\n$email\n請在這部裝置上開啟連結，完成建立帳戶。';
  }

  @override
  String get checkEmailResent => '已重新寄出確認郵件。';

  @override
  String get checkEmailResend => '重新寄送確認郵件';

  @override
  String get backToSignIn => '返回登入';

  @override
  String get forgotTitle => '重設密碼';

  @override
  String get forgotIntro => '輸入您的電子郵件，我們會寄給您重設連結。';

  @override
  String forgotSent(String email) {
    return '如果 $email 有帳戶，重設連結很快就會寄到。請在這部裝置上開啟。';
  }

  @override
  String get forgotSend => '寄送重設連結';

  @override
  String get resetTitle => '設定新密碼';

  @override
  String get passwordMinShort => '請使用至少 8 個字元。';

  @override
  String get fieldNewPassword => '新密碼';

  @override
  String get fieldConfirmNewPassword => '確認新密碼';

  @override
  String get resetButton => '更新密碼';

  @override
  String get gateTitle => '設定新的密碼';

  @override
  String get gateBody => '您的照護團隊用臨時密碼建立了這個帳戶。請設定您自己的密碼後繼續。';

  @override
  String get gateRule => '至少 8 個字元，包含大寫字母、小寫字母和數字。';

  @override
  String get gateErrorMix => '請包含大寫字母、小寫字母和數字。';

  @override
  String get gateSuccess => '密碼已更新，歡迎！';

  @override
  String get gateErrorSame => '請選擇與臨時密碼不同的密碼。';

  @override
  String get gateErrorFailed => '無法更新密碼，請檢查網路連線。';

  @override
  String get gateSave => '儲存密碼';

  @override
  String get menuOpen => '開啟選單';

  @override
  String get menuAssessments => '整體評估';

  @override
  String get menuAssessmentsSubtitle => '照護團隊提供的問卷';

  @override
  String get menuAssistance => '我需要協助';

  @override
  String get menuAssistanceSubtitle => '向照護團隊求助';

  @override
  String get menuMyRequests => '我的求助紀錄';

  @override
  String get menuMyRequestsSubtitle => '查看已送出請求的狀態';

  @override
  String get menuEmergency => '緊急情況請撥打 911。';

  @override
  String get navEducation => '課程';

  @override
  String get navResources => '資源';

  @override
  String get navProgress => '進度';

  @override
  String get navChat => '聊天';

  @override
  String get navProfile => '個人資料';

  @override
  String get crashTitle => '發生錯誤';

  @override
  String get crashBody => '請重新啟動應用程式。如果問題持續發生，請聯絡研究團隊。';

  @override
  String get homeGoodMorning => '早安';

  @override
  String get homeGoodAfternoon => '午安';

  @override
  String get homeGoodEvening => '晚上好';

  @override
  String get homeHi => '您好 👋';

  @override
  String homeHiName(String name) {
    return '$name，您好 👋';
  }

  @override
  String get homeTitle => '您的健康\n教育中心';

  @override
  String get homeSearchHint => '搜尋課程、主題…';

  @override
  String get homeCategoryAll => '全部';

  @override
  String get homeNoLessons => '目前還沒有課程，請稍後再來看看。';

  @override
  String get homeNoMatches => '找不到符合搜尋的課程。';

  @override
  String get progressCardTitle => '您的進度';

  @override
  String progressCardLessons(int completed, int total) {
    return '$completed / $total 堂課';
  }

  @override
  String get progressCardStart => '我們開始吧！';

  @override
  String progressCardGreat(int percent) {
    return '已完成 $percent%，做得很好！';
  }

  @override
  String progressCardKeepGoing(int percent) {
    return '已完成 $percent%，繼續加油！';
  }

  @override
  String get progressCardDone => '已完成 100%，太棒了！';

  @override
  String get lessonHeader => '課程';

  @override
  String get lessonNoLessonsShort => '目前還沒有課程。';

  @override
  String get lessonNoneSelected => '尚未選擇課程。';

  @override
  String get lessonMarked => '已將課程標為完成，做得好！';

  @override
  String get lessonCompletedTitle => '課程已完成';

  @override
  String get lessonFinishPrompt => '上完這堂課了嗎？';

  @override
  String get lessonCompletedBody => '做得好！您隨時可以回來複習。';

  @override
  String get lessonFinishBody => '標為完成，就能追蹤您的進度。';

  @override
  String get lessonMarkButton => '標為完成';

  @override
  String lessonSections(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個單元',
    );
    return '$_temp0';
  }

  @override
  String get refTitle => '參考資料';

  @override
  String get refLessonVideo => '課程影片';

  @override
  String get refLessonAudio => '課程音訊';

  @override
  String get scriptTitle => '課程筆記';

  @override
  String get scriptReadMore => '閱讀更多';

  @override
  String get scriptShowLess => '收起';

  @override
  String get infoTitle => '資訊圖表';

  @override
  String get infoCardTitle => '課程資訊圖表';

  @override
  String infoCardSubtitle(String title) {
    return '$title的圖像摘要';
  }

  @override
  String infoSemantic(String title) {
    return '$title的資訊圖表';
  }

  @override
  String get infoTapHint => '點一下圖片即可全螢幕檢視並放大';

  @override
  String get imageOpenFullscreen => '全螢幕檢視';

  @override
  String get imageLoadFailed => '無法載入圖片。';

  @override
  String get imageCloseFullscreen => '關閉全螢幕';

  @override
  String get imageZoomHint => '用兩指縮放或點兩下放大';

  @override
  String get videoTitle => '影片課程';

  @override
  String get videoPlaying => '正在播放影片';

  @override
  String get videoTapToPlay => '點一下播放影片';

  @override
  String get videoYouTube => 'YouTube 影片';

  @override
  String get audioTitle => '音訊課程';

  @override
  String get audioOpen => '開啟音訊';

  @override
  String get audioListen => '收聽這堂課';

  @override
  String get kahootTitle => '知識小遊戲';

  @override
  String get kahootMarked => '做得好！已將測驗標為完成。';

  @override
  String get kahootCopied => '已複製使用者名稱。';

  @override
  String get kahootCopyTooltip => '複製使用者名稱';

  @override
  String get kahootUsernameLabel => '您的 Kahoot 使用者名稱';

  @override
  String get kahootUsernameHint => 'Kahoot 遊戲要求輸入暱稱時，請使用這個使用者名稱';

  @override
  String get kahootIntro => '用互動的 Kahoot! 遊戲測試您學到的內容';

  @override
  String get kahootBadgeTime => '⏱ 約 5 分鐘';

  @override
  String get kahootBadgeInteractive => '✨ 互動式';

  @override
  String get kahootBadgeFun => '🎉 好玩！';

  @override
  String get kahootStart => '開始 Kahoot! 遊戲';

  @override
  String get kahootEmbedHint => '點一下上方按鈕，遊戲就會在下方開啟';

  @override
  String get kahootFinished => '測驗已完成';

  @override
  String get kahootIFinished => '我完成測驗了';

  @override
  String get chatAiTitle => 'AI 助理';

  @override
  String get chatAiSubtitle => '自動回答，全天候';

  @override
  String get chatTeamTitle => '研究團隊';

  @override
  String get chatTeamSubtitle => 'Happy Hearts 研究';

  @override
  String get chatTabTeam => '照護團隊';

  @override
  String get chatSignInAi => '請登入以使用 AI 助理。';

  @override
  String get chatSignIn => '請登入以使用聊天功能。';

  @override
  String get chatNeedHelp => '需要協助嗎？';

  @override
  String get chatViewRequests => '查看我的請求';

  @override
  String get chatEmptyTitle => '開始對話';

  @override
  String get chatEmptyBody => '傳訊息給 Happy Hearts 研究團隊。有任何關於研究的問題，我們都樂意協助。';

  @override
  String get chatNotSent => '未送出';

  @override
  String get chatDelete => '刪除';

  @override
  String get chatSending => '傳送中…';

  @override
  String get chatInputHint => '傳訊息給研究團隊…';

  @override
  String get chatSend => '傳送';

  @override
  String get chatErrorWrongAccount => '這個帳戶無法使用病人聊天功能，請用病人帳戶登入。';

  @override
  String get chatErrorOpen => '無法開啟您的對話，請再試一次。';

  @override
  String get chatErrorLoad => '無法載入訊息。請檢查網路連線後再試一次。';

  @override
  String get chatErrorKept => '無法連線到伺服器。您的訊息已保留，請點「重試」。';

  @override
  String get chatErrorNoPermission => '您沒有在這個對話中傳送訊息的權限。';

  @override
  String get chatErrorLength => '訊息長度需為 1 到 4000 個字元。';

  @override
  String get chatErrorNotSent => '訊息未送出，請再試一次。';

  @override
  String get chatErrorGeneric => '載入對話時發生錯誤。';

  @override
  String get aiErrorConnection => '無法載入 AI 助理，請檢查網路連線。';

  @override
  String get aiErrorUnavailable => 'AI 助理目前無法使用。';

  @override
  String get aiErrorStart => '無法啟動 AI 助理。';

  @override
  String get aiErrorTimeout => 'AI 助理載入時間過長。';

  @override
  String get aiWebOnly => 'AI 助理可在 HappyHearts 的 iOS 和 Android 應用程式中使用。';

  @override
  String get assistMyRequests => '我的請求';

  @override
  String get assistIntro => '告訴研究團隊您需要什麼協助。團隊成員會跟進，通常是透過「照護團隊」聊天訊息。';

  @override
  String get assistEmergency => '這裡不是 24 小時有人查看。如有緊急情況，請撥打 911。';

  @override
  String get assistHint => '例如：「我對我的藥物有疑問」或「第 3 堂課的影片無法播放。」';

  @override
  String get assistSend => '送出請求';

  @override
  String get assistErrorEmpty => '請說明您需要什麼協助。';

  @override
  String assistErrorTooLong(int max) {
    return '訊息請少於 $max 個字元。';
  }

  @override
  String get assistErrorOffline => '無法連線到伺服器。您的訊息已保留，請再試一次。';

  @override
  String get assistErrorLoad => '無法載入您的請求。請檢查網路連線後再試一次。';

  @override
  String get assistErrorNotParticipant => '只有參與者帳戶可以送出求助請求。';

  @override
  String assistErrorLength(int max) {
    return '請輸入 1 到 $max 個字元的訊息。';
  }

  @override
  String get assistErrorRateLimited =>
      '您最近已送出多個請求，團隊很快會回覆您。如果情況緊急，請打電話給您的照護團隊；緊急情況請撥打 911。';

  @override
  String get assistErrorNotSent => '請求未送出。您的訊息已保留，請再試一次。';

  @override
  String get requestsTitle => '我的求助請求';

  @override
  String get requestsNew => '新請求';

  @override
  String get requestsEmptyTitle => '目前沒有請求';

  @override
  String get requestsEmptyBody => '需要研究團隊協助時，送出請求後就能在這裡追蹤狀態。';

  @override
  String get requestStatusSent => '已送出';

  @override
  String get requestStatusSeen => '團隊已查看';

  @override
  String get requestStatusResolved => '已解決';

  @override
  String get requestWaiting => '正在等待團隊成員查看。';

  @override
  String get requestFollowing => '團隊成員正在跟進。';

  @override
  String requestFollowingSince(String time) {
    return '團隊成員正在跟進（$time）。';
  }

  @override
  String get requestResolved => '已標為解決。';

  @override
  String requestResolvedSince(String time) {
    return '已標為解決（$time）。';
  }

  @override
  String get assessSubtitleSurvey => '照護團隊提供的問卷。';

  @override
  String get assessSubtitleResources => '用這些經過驗證的篩檢工具追蹤您的身心健康。';

  @override
  String get assessEmptySurvey => '目前沒有整體評估，照護團隊會在這裡新增。';

  @override
  String get assessEmptyResources => '目前沒有資源，照護團隊會在這裡新增。';

  @override
  String get assessUsernameError => '無法載入您的使用者名稱，請再試一次。';

  @override
  String assessLastCompleted(String date) {
    return '上次完成：$date';
  }

  @override
  String get assessStart => '開始評估';

  @override
  String get surveyErrorLoad => '無法載入問卷。請檢查網路連線後再試一次。';

  @override
  String get surveyRecordFailed => '您的答案已送出，但應用程式無法將問卷標為完成。';

  @override
  String get surveyThanks => '謝謝您！';

  @override
  String get surveyThanksBody => '您的回覆已送出，可以在「進度」日曆中看到這份問卷。';

  @override
  String get surveyLoading => '正在載入問卷…';

  @override
  String get surveyLoadFailedTitle => '無法載入問卷';

  @override
  String get surveyLoadFailedBody => '請檢查網路連線後再試一次。';

  @override
  String get progressSubtitle => '追蹤您的學習歷程，慶祝每個里程碑。';

  @override
  String get progressCalendar => '活動日曆';

  @override
  String get progressBreakdown => '各課程進度';

  @override
  String activityCompleted(String title) {
    return '已完成：$title';
  }

  @override
  String activityQuizFinished(String title) {
    return '已完成測驗：$title';
  }

  @override
  String activitySurveyFallback(String code) {
    return '問卷（$code）';
  }

  @override
  String get calPrevMonth => '上個月';

  @override
  String get calNextMonth => '下個月';

  @override
  String get legendLesson => '課程';

  @override
  String get legendQuiz => '測驗';

  @override
  String get legendSurvey => '問卷';

  @override
  String get calLessonDone => '完成課程';

  @override
  String get calQuizDone => '完成測驗';

  @override
  String get calSurveyDone => '完成問卷';

  @override
  String get activityRecent => '最近活動';

  @override
  String activityOnDay(String date) {
    return '$date 的活動';
  }

  @override
  String get activityShowAll => '顯示全部';

  @override
  String get activityEmpty => '完成課程、測驗或問卷後，就會顯示在這裡。';

  @override
  String get activityEmptyDay => '這天沒有完成任何項目。';

  @override
  String get overallTitle => '整體完成度';

  @override
  String overallCount(int completed, int total) {
    return '$total 堂課中完成 $completed 堂';
  }

  @override
  String get overallAllDone => '🎉 所有課程都完成了！';

  @override
  String get overallKeepGoing => '繼續加油，您進步得很好！';

  @override
  String get overallStart => '從第一堂課開始吧。';

  @override
  String get statTimeSpent => '學習時間';

  @override
  String timeSpentSuffix(String time) {
    return '已學習 $time';
  }

  @override
  String get profileSignOutConfirm => '確定要登出嗎？';

  @override
  String profileResetSent(String email) {
    return '已將重設密碼連結寄到 $email';
  }

  @override
  String get profileAccount => '帳戶';

  @override
  String get profileChangePassword => '變更密碼（寄送重設郵件）';

  @override
  String get profilePreferences => '偏好設定';

  @override
  String get profileAbout => '關於';

  @override
  String get profileVersion => '應用程式版本';

  @override
  String get profileNotAvailable => '無法取得您的個人資料。';

  @override
  String get profileEditName => '編輯姓名';

  @override
  String get profileLearningSummary => '學習摘要';

  @override
  String get profileStatComplete => '完成度';

  @override
  String get profileProgressFailed => '無法載入您的進度，點一下重試。';

  @override
  String get profileErrorSignIn => '請登入。';

  @override
  String get profileErrorSessionChanged => '登入狀態已變更，請再試一次。';

  @override
  String get profileErrorMissing => '找不到您的個人資料。請向下拉重試；如果一直發生，請聯絡研究團隊。';

  @override
  String get profileErrorPermission => '您沒有查看這份個人資料的權限。';

  @override
  String get profileErrorLoad => '無法載入您的個人資料。請檢查網路連線後再試一次。';

  @override
  String get profileErrorNameEmpty => '姓名不能空白。';

  @override
  String get profileErrorSaveName => '無法儲存您的姓名。請檢查網路連線後再試一次。';

  @override
  String get contentErrorLessons => '無法載入課程。請檢查網路連線後再試一次。';

  @override
  String get contentErrorProgress => '無法載入您的進度。請檢查網路連線後再試一次。';
}
