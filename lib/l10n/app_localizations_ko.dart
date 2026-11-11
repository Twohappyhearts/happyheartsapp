// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get retry => '다시 시도';

  @override
  String get cancel => '취소';

  @override
  String get save => '저장';

  @override
  String get done => '완료';

  @override
  String get close => '닫기';

  @override
  String get back => '뒤로';

  @override
  String get view => '보기';

  @override
  String get signOut => '로그아웃';

  @override
  String get errorGeneric => '문제가 발생했습니다. 다시 시도해 주세요.';

  @override
  String get errorConnection => '문제가 발생했습니다. 인터넷 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get errorServerUnreachable =>
      '서버에 연결할 수 없습니다. 인터넷 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get couldNotOpenLink => '이 링크를 열 수 없습니다.';

  @override
  String get requestSent => '요청을 보냈습니다. 팀원이 연락드릴 예정입니다.';

  @override
  String get statusCompleted => '완료됨';

  @override
  String get statusInProgress => '진행 중';

  @override
  String get statusAvailable => '시작 가능';

  @override
  String get statusNotStarted => '시작 전';

  @override
  String get dateToday => '오늘';

  @override
  String get dateYesterday => '어제';

  @override
  String dateTodayAt(String time) {
    return '오늘 $time';
  }

  @override
  String dateYesterdayAt(String time) {
    return '어제 $time';
  }

  @override
  String dateAt(String date, String time) {
    return '$date $time';
  }

  @override
  String minutesShort(int minutes) {
    return '$minutes분';
  }

  @override
  String timeMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String timeHoursMinutes(int hours, int minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String linkSemantic(String text) {
    return '링크: $text';
  }

  @override
  String get languageTitle => '언어';

  @override
  String get languagePhone => '휴대폰 언어';

  @override
  String languagePhoneDetail(String language) {
    return '휴대폰과 같음 ($language)';
  }

  @override
  String get languagePickerTitle => '언어 선택';

  @override
  String languageButtonSemantic(String language) {
    return '언어: $language. 눌러서 변경하세요.';
  }

  @override
  String get authTagline => '나만의 건강 교육 도우미';

  @override
  String get authTabSignIn => '로그인';

  @override
  String get authTabCreateAccount => '계정 만들기';

  @override
  String get signInWelcome => '다시 오신 것을 환영합니다 👋';

  @override
  String get signInSubtitle => '로그인하고 건강 학습을 이어가세요';

  @override
  String get fieldEmail => '이메일 주소';

  @override
  String get fieldEmailHint => '이메일을 입력하세요';

  @override
  String get validationEmailRequired => '이메일을 입력해 주세요';

  @override
  String get validationEmailInvalid => '올바른 이메일을 입력해 주세요';

  @override
  String get fieldPassword => '비밀번호';

  @override
  String get fieldPasswordHint => '비밀번호를 입력하세요';

  @override
  String get validationPasswordRequired => '비밀번호를 입력해 주세요';

  @override
  String get showPassword => '비밀번호 보기';

  @override
  String get hidePassword => '비밀번호 숨기기';

  @override
  String get signInForgot => '비밀번호를 잊으셨나요?';

  @override
  String get createTitle => '계정을 만드세요';

  @override
  String get createSubtitle => '오늘 건강 교육을 시작하세요';

  @override
  String get fieldFullName => '이름';

  @override
  String get fieldFullNameHint => '이름을 입력하세요';

  @override
  String get validationNameRequired => '이름을 입력해 주세요';

  @override
  String get fieldUsername => '사용자 이름';

  @override
  String get fieldUsernameHint => '연구팀에서 받은 사용자 이름';

  @override
  String get fieldUsernameHelper =>
      '연구팀에서 받은 사용자 이름을 사용하세요. 설문과 계정을 연결하는 데 쓰이며 나중에 바꿀 수 없습니다.';

  @override
  String get validationUsernameRequired => '사용자 이름을 입력해 주세요';

  @override
  String get validationUsernameFormat => '영문자 또는 숫자 3~20자 (공백·기호 제외)';

  @override
  String get fieldPhone => '전화번호';

  @override
  String get fieldPhoneHint => '예: (949) 555-0100';

  @override
  String get validationPhoneRequired => '전화번호를 입력해 주세요';

  @override
  String get validationPhoneInvalid => '올바른 전화번호를 입력해 주세요';

  @override
  String get fieldCreatePasswordHint => '비밀번호를 만드세요';

  @override
  String get validationNewPasswordRequired => '비밀번호를 입력해 주세요';

  @override
  String get validationPasswordMin8 => '비밀번호는 8자 이상이어야 합니다';

  @override
  String get fieldConfirmPassword => '비밀번호 확인';

  @override
  String get fieldConfirmPasswordHint => '비밀번호를 다시 입력하세요';

  @override
  String get validationConfirmRequired => '비밀번호를 확인해 주세요';

  @override
  String get validationPasswordsMismatch => '비밀번호가 일치하지 않습니다';

  @override
  String get legalTerms => '이용약관';

  @override
  String get legalPrivacy => '개인정보 처리방침';

  @override
  String createAgree(String terms, String privacy) {
    return '$terms 및 $privacy에 동의합니다';
  }

  @override
  String get createAgreeRequired => '이용약관 및 개인정보 처리방침에 동의해 주세요';

  @override
  String get authErrorCredentials => '이메일 또는 비밀번호가 올바르지 않습니다.';

  @override
  String get authErrorUsernameRejected =>
      '이미 사용 중이거나 사용할 수 없는 사용자 이름입니다. 다른 이름을 선택해 주세요.';

  @override
  String get authErrorUsernameTaken =>
      '이미 사용 중인 사용자 이름입니다. 연구팀에서 받은 사용자 이름을 사용하시고, 이미 등록되어 있다면 케어팀에 문의해 주세요.';

  @override
  String get authErrorDisabled => '이 계정은 사용 중지되었습니다. 케어팀에 문의해 주세요.';

  @override
  String get authErrorEmailNotConfirmed => '로그인하기 전에 이메일을 인증해 주세요.';

  @override
  String get authErrorEmailExists => '이 이메일로 된 계정이 이미 있습니다. 로그인해 보세요.';

  @override
  String get authErrorRateLimited => '시도 횟수가 너무 많습니다. 1분 후에 다시 시도해 주세요.';

  @override
  String get authErrorPassword => '다른 비밀번호를 선택해 주세요.';

  @override
  String get checkEmailTitle => '이메일을 확인하세요';

  @override
  String checkEmailBody(String email) {
    return '다음 주소로 인증 링크를 보냈습니다.\n$email\n이 기기에서 링크를 열어 계정 만들기를 완료하세요.';
  }

  @override
  String get checkEmailResent => '인증 이메일을 다시 보냈습니다.';

  @override
  String get checkEmailResend => '인증 이메일 다시 보내기';

  @override
  String get backToSignIn => '로그인으로 돌아가기';

  @override
  String get forgotTitle => '비밀번호 재설정';

  @override
  String get forgotIntro => '이메일을 입력하시면 재설정 링크를 보내 드립니다.';

  @override
  String forgotSent(String email) {
    return '$email 계정이 있다면 재설정 링크가 곧 도착합니다. 이 기기에서 열어 주세요.';
  }

  @override
  String get forgotSend => '재설정 링크 보내기';

  @override
  String get resetTitle => '새 비밀번호를 정하세요';

  @override
  String get passwordMinShort => '8자 이상 입력하세요.';

  @override
  String get fieldNewPassword => '새 비밀번호';

  @override
  String get fieldConfirmNewPassword => '새 비밀번호 확인';

  @override
  String get resetButton => '비밀번호 변경';

  @override
  String get gateTitle => '새 비밀번호 설정';

  @override
  String get gateBody => '케어팀이 임시 비밀번호로 이 계정을 만들었습니다. 계속하려면 직접 비밀번호를 정해 주세요.';

  @override
  String get gateRule => '대문자, 소문자, 숫자를 포함해 8자 이상';

  @override
  String get gateErrorMix => '대문자, 소문자, 숫자를 모두 포함해 주세요.';

  @override
  String get gateSuccess => '비밀번호가 변경되었습니다. 환영합니다!';

  @override
  String get gateErrorSame => '임시 비밀번호와 다른 비밀번호를 선택해 주세요.';

  @override
  String get gateErrorFailed => '비밀번호를 변경하지 못했습니다. 인터넷 연결을 확인해 주세요.';

  @override
  String get gateSave => '비밀번호 저장';

  @override
  String get menuOpen => '메뉴 열기';

  @override
  String get menuAssessments => '종합 평가';

  @override
  String get menuAssessmentsSubtitle => '케어팀이 보낸 설문지';

  @override
  String get menuAssistance => '도움이 필요해요';

  @override
  String get menuAssistanceSubtitle => '케어팀에 도움 요청하기';

  @override
  String get menuMyRequests => '내 도움 요청';

  @override
  String get menuMyRequestsSubtitle => '보낸 요청의 상태 보기';

  @override
  String get menuEmergency => '응급 상황에서는 911에 전화하세요.';

  @override
  String get navEducation => '교육';

  @override
  String get navResources => '자료';

  @override
  String get navProgress => '진행 상황';

  @override
  String get navChat => '채팅';

  @override
  String get navProfile => '프로필';

  @override
  String get crashTitle => '문제가 발생했습니다';

  @override
  String get crashBody => '앱을 다시 시작해 주세요. 문제가 계속되면 연구팀에 문의해 주세요.';

  @override
  String get homeGoodMorning => '좋은 아침입니다';

  @override
  String get homeGoodAfternoon => '좋은 오후입니다';

  @override
  String get homeGoodEvening => '좋은 저녁입니다';

  @override
  String get homeHi => '안녕하세요 👋';

  @override
  String homeHiName(String name) {
    return '$name님, 안녕하세요 👋';
  }

  @override
  String get homeTitle => '나의 건강\n교육 센터';

  @override
  String get homeSearchHint => '강의, 주제 검색...';

  @override
  String get homeCategoryAll => '전체';

  @override
  String get homeNoLessons => '아직 강의가 없습니다. 곧 다시 확인해 주세요.';

  @override
  String get homeNoMatches => '검색과 일치하는 강의가 없습니다.';

  @override
  String get progressCardTitle => '나의 진행 상황';

  @override
  String progressCardLessons(int completed, int total) {
    return '강의 $completed / $total';
  }

  @override
  String get progressCardStart => '시작해 볼까요!';

  @override
  String progressCardGreat(int percent) {
    return '$percent% 완료 — 잘하고 계세요!';
  }

  @override
  String progressCardKeepGoing(int percent) {
    return '$percent% 완료 — 계속해 보세요!';
  }

  @override
  String get progressCardDone => '100% 완료 — 정말 잘하셨어요!';

  @override
  String get lessonHeader => '강의';

  @override
  String get lessonNoLessonsShort => '아직 강의가 없습니다.';

  @override
  String get lessonNoneSelected => '선택한 강의가 없습니다.';

  @override
  String get lessonMarked => '강의를 완료로 표시했습니다. 잘하셨어요!';

  @override
  String get lessonCompletedTitle => '강의 완료';

  @override
  String get lessonFinishPrompt => '이 강의를 다 들으셨나요?';

  @override
  String get lessonCompletedBody => '잘하셨어요! 언제든 다시 와서 복습할 수 있습니다.';

  @override
  String get lessonFinishBody => '완료로 표시하면 진행 상황을 확인할 수 있습니다.';

  @override
  String get lessonMarkButton => '완료로 표시';

  @override
  String lessonSections(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 섹션',
    );
    return '$_temp0';
  }

  @override
  String get refTitle => '참고 자료';

  @override
  String get refLessonVideo => '강의 동영상';

  @override
  String get refLessonAudio => '강의 오디오';

  @override
  String get scriptTitle => '강의 노트';

  @override
  String get scriptReadMore => '더 보기';

  @override
  String get scriptShowLess => '접기';

  @override
  String get infoTitle => '인포그래픽';

  @override
  String get infoCardTitle => '강의 인포그래픽';

  @override
  String infoCardSubtitle(String title) {
    return '$title 시각 요약';
  }

  @override
  String infoSemantic(String title) {
    return '$title 인포그래픽';
  }

  @override
  String get infoTapHint => '이미지를 누르면 전체 화면으로 보고 확대할 수 있습니다';

  @override
  String get imageOpenFullscreen => '전체 화면으로 보기';

  @override
  String get imageLoadFailed => '이미지를 불러올 수 없습니다.';

  @override
  String get imageCloseFullscreen => '전체 화면 닫기';

  @override
  String get imageZoomHint => '두 손가락으로 벌리거나 두 번 눌러 확대하세요';

  @override
  String get videoTitle => '동영상 강의';

  @override
  String get videoPlaying => '동영상 재생 중';

  @override
  String get videoTapToPlay => '눌러서 동영상 재생';

  @override
  String get videoYouTube => 'YouTube 동영상';

  @override
  String get audioTitle => '오디오 강의';

  @override
  String get audioOpen => '오디오 열기';

  @override
  String get audioListen => '이 강의 듣기';

  @override
  String get kahootTitle => '지식 퀴즈 게임';

  @override
  String get kahootMarked => '잘하셨어요! 퀴즈를 완료로 표시했습니다.';

  @override
  String get kahootCopied => '사용자 이름을 복사했습니다.';

  @override
  String get kahootCopyTooltip => '사용자 이름 복사';

  @override
  String get kahootUsernameLabel => '나의 Kahoot 사용자 이름';

  @override
  String get kahootUsernameHint => 'Kahoot 게임에서 닉네임을 물으면 이 사용자 이름을 입력하세요';

  @override
  String get kahootIntro => 'Kahoot! 게임으로 배운 내용을 확인해 보세요';

  @override
  String get kahootBadgeTime => '⏱ 약 5분';

  @override
  String get kahootBadgeInteractive => '✨ 참여형';

  @override
  String get kahootBadgeFun => '🎉 재미있어요!';

  @override
  String get kahootStart => 'Kahoot! 게임 시작';

  @override
  String get kahootEmbedHint => '위 버튼을 누르면 아래에 게임이 열립니다';

  @override
  String get kahootFinished => '퀴즈 완료';

  @override
  String get kahootIFinished => '퀴즈를 마쳤어요';

  @override
  String get chatAiTitle => 'AI 도우미';

  @override
  String get chatAiSubtitle => '연중무휴 자동 답변';

  @override
  String get chatTeamTitle => '연구팀';

  @override
  String get chatTeamSubtitle => 'Happy Hearts 연구';

  @override
  String get chatTabTeam => '케어팀';

  @override
  String get chatSignInAi => 'AI 도우미를 사용하려면 로그인해 주세요.';

  @override
  String get chatSignIn => '채팅을 사용하려면 로그인해 주세요.';

  @override
  String get chatNeedHelp => '도움이 필요하신가요?';

  @override
  String get chatViewRequests => '내 요청 보기';

  @override
  String get chatEmptyTitle => '대화를 시작하세요';

  @override
  String get chatEmptyBody =>
      'Happy Hearts 연구팀에 메시지를 보내세요. 연구에 관한 궁금한 점을 도와드립니다.';

  @override
  String get chatNotSent => '전송 안 됨';

  @override
  String get chatDelete => '삭제';

  @override
  String get chatSending => '보내는 중…';

  @override
  String get chatInputHint => '연구팀에 메시지 보내기...';

  @override
  String get chatSend => '보내기';

  @override
  String get chatErrorWrongAccount =>
      '이 계정으로는 환자 채팅을 사용할 수 없습니다. 환자 계정으로 로그인해 주세요.';

  @override
  String get chatErrorOpen => '대화를 열 수 없습니다. 다시 시도해 주세요.';

  @override
  String get chatErrorLoad => '메시지를 불러올 수 없습니다. 인터넷 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get chatErrorKept => '서버에 연결할 수 없습니다. 메시지는 보관되었습니다. 다시 시도를 누르세요.';

  @override
  String get chatErrorNoPermission => '이 대화에서 메시지를 보낼 권한이 없습니다.';

  @override
  String get chatErrorLength => '메시지는 1~4000자여야 합니다.';

  @override
  String get chatErrorNotSent => '메시지를 보내지 못했습니다. 다시 시도해 주세요.';

  @override
  String get chatErrorGeneric => '대화를 불러오는 중 문제가 발생했습니다.';

  @override
  String get aiErrorConnection => 'AI 도우미를 불러올 수 없습니다. 인터넷 연결을 확인해 주세요.';

  @override
  String get aiErrorUnavailable => '지금은 AI 도우미를 사용할 수 없습니다.';

  @override
  String get aiErrorStart => 'AI 도우미를 시작할 수 없습니다.';

  @override
  String get aiErrorTimeout => 'AI 도우미를 불러오는 데 시간이 너무 오래 걸립니다.';

  @override
  String get aiWebOnly => 'AI 도우미는 HappyHearts iOS 및 Android 앱에서 사용할 수 있습니다.';

  @override
  String get assistMyRequests => '내 요청';

  @override
  String get assistIntro =>
      '어떤 도움이 필요한지 연구팀에 알려 주세요. 팀원이 보통 케어팀 채팅 메시지로 연락드립니다.';

  @override
  String get assistEmergency => '이 요청은 24시간 확인되지 않습니다. 응급 상황이면 911에 전화하세요.';

  @override
  String get assistHint =>
      '예: \"복용 중인 약에 대해 질문이 있어요\" 또는 \"3회차 동영상이 재생되지 않아요.\"';

  @override
  String get assistSend => '요청 보내기';

  @override
  String get assistErrorEmpty => '어떤 도움이 필요한지 적어 주세요.';

  @override
  String assistErrorTooLong(int max) {
    return '메시지는 $max자 이내로 작성해 주세요.';
  }

  @override
  String get assistErrorOffline => '서버에 연결할 수 없습니다. 메시지는 보관되었으니 다시 시도해 주세요.';

  @override
  String get assistErrorLoad => '요청 목록을 불러올 수 없습니다. 인터넷 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get assistErrorNotParticipant => '참여자 계정만 도움 요청을 보낼 수 있습니다.';

  @override
  String assistErrorLength(int max) {
    return '1~$max자 사이로 메시지를 작성해 주세요.';
  }

  @override
  String get assistErrorRateLimited =>
      '최근에 여러 번 요청을 보내셨습니다. 팀에서 곧 연락드릴 예정입니다. 급한 경우 케어팀에 전화하시고, 응급 상황에서는 911에 전화하세요.';

  @override
  String get assistErrorNotSent => '요청을 보내지 못했습니다. 메시지는 보관되었으니 다시 시도해 주세요.';

  @override
  String get requestsTitle => '내 도움 요청';

  @override
  String get requestsNew => '새 요청';

  @override
  String get requestsEmptyTitle => '아직 요청이 없습니다';

  @override
  String get requestsEmptyBody =>
      '연구팀의 도움이 필요하면 요청을 보내세요. 여기에서 상태를 확인할 수 있습니다.';

  @override
  String get requestStatusSent => '보냄';

  @override
  String get requestStatusSeen => '팀이 확인함';

  @override
  String get requestStatusResolved => '해결됨';

  @override
  String get requestWaiting => '팀원의 확인을 기다리고 있습니다.';

  @override
  String get requestFollowing => '팀원이 처리하고 있습니다.';

  @override
  String requestFollowingSince(String time) {
    return '팀원이 처리하고 있습니다 ($time).';
  }

  @override
  String get requestResolved => '해결됨으로 표시되었습니다.';

  @override
  String requestResolvedSince(String time) {
    return '해결됨으로 표시되었습니다 ($time).';
  }

  @override
  String get assessSubtitleSurvey => '케어팀이 보낸 설문지입니다.';

  @override
  String get assessSubtitleResources => '검증된 선별 도구로 정신 건강과 신체 건강을 확인하세요.';

  @override
  String get assessEmptySurvey => '지금은 종합 평가가 없습니다. 케어팀이 여기에 추가할 예정입니다.';

  @override
  String get assessEmptyResources => '지금은 자료가 없습니다. 케어팀이 여기에 추가할 예정입니다.';

  @override
  String get assessUsernameError => '사용자 이름을 불러올 수 없습니다. 다시 시도해 주세요.';

  @override
  String assessLastCompleted(String date) {
    return '마지막 완료: $date';
  }

  @override
  String get assessStart => '평가 시작';

  @override
  String get surveyErrorLoad => '설문을 불러올 수 없습니다. 인터넷 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get surveyRecordFailed => '답변은 제출되었지만 앱에서 설문을 완료로 표시하지 못했습니다.';

  @override
  String get surveyThanks => '감사합니다!';

  @override
  String get surveyThanksBody => '답변이 제출되었습니다. 진행 상황 달력에서 이 설문을 볼 수 있습니다.';

  @override
  String get surveyLoading => '설문 불러오는 중...';

  @override
  String get surveyLoadFailedTitle => '설문을 불러올 수 없습니다';

  @override
  String get surveyLoadFailedBody => '인터넷 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get progressSubtitle => '학습 과정을 확인하고 성과를 축하하세요.';

  @override
  String get progressCalendar => '활동 달력';

  @override
  String get progressBreakdown => '강의별 진행';

  @override
  String activityCompleted(String title) {
    return '완료: $title';
  }

  @override
  String activityQuizFinished(String title) {
    return '퀴즈 완료: $title';
  }

  @override
  String activitySurveyFallback(String code) {
    return '설문 ($code)';
  }

  @override
  String get calPrevMonth => '이전 달';

  @override
  String get calNextMonth => '다음 달';

  @override
  String get legendLesson => '강의';

  @override
  String get legendQuiz => '퀴즈';

  @override
  String get legendSurvey => '설문';

  @override
  String get calLessonDone => '강의 완료';

  @override
  String get calQuizDone => '퀴즈 완료';

  @override
  String get calSurveyDone => '설문 완료';

  @override
  String get activityRecent => '최근 활동';

  @override
  String activityOnDay(String date) {
    return '$date 활동';
  }

  @override
  String get activityShowAll => '모두 보기';

  @override
  String get activityEmpty => '강의, 퀴즈 또는 설문을 완료하면 여기에 표시됩니다.';

  @override
  String get activityEmptyDay => '이날 완료한 항목이 없습니다.';

  @override
  String get overallTitle => '전체 완료율';

  @override
  String overallCount(int completed, int total) {
    return '강의 $total개 중 $completed개';
  }

  @override
  String get overallAllDone => '🎉 모든 강의를 완료했습니다!';

  @override
  String get overallKeepGoing => '계속해 보세요. 잘하고 계세요!';

  @override
  String get overallStart => '첫 강의를 시작해 보세요.';

  @override
  String get statTimeSpent => '학습 시간';

  @override
  String timeSpentSuffix(String time) {
    return '$time 학습';
  }

  @override
  String get profileSignOutConfirm => '로그아웃하시겠습니까?';

  @override
  String profileResetSent(String email) {
    return '$email(으)로 비밀번호 재설정 링크를 보냈습니다';
  }

  @override
  String get profileAccount => '계정';

  @override
  String get profileChangePassword => '비밀번호 변경 (재설정 이메일 보내기)';

  @override
  String get profilePreferences => '환경설정';

  @override
  String get profileAbout => '정보';

  @override
  String get profileVersion => '앱 버전';

  @override
  String get profileNotAvailable => '프로필을 불러올 수 없습니다.';

  @override
  String get profileEditName => '이름 수정';

  @override
  String get profileLearningSummary => '학습 요약';

  @override
  String get profileStatComplete => '완료율';

  @override
  String get profileProgressFailed => '진행 상황을 불러올 수 없습니다. 눌러서 다시 시도하세요.';

  @override
  String get profileErrorSignIn => '로그인해 주세요.';

  @override
  String get profileErrorSessionChanged => '세션이 변경되었습니다. 다시 시도해 주세요.';

  @override
  String get profileErrorMissing =>
      '프로필을 찾을 수 없습니다. 아래로 당겨 다시 시도하시고, 계속되면 연구팀에 문의해 주세요.';

  @override
  String get profileErrorPermission => '이 프로필을 볼 권한이 없습니다.';

  @override
  String get profileErrorLoad => '프로필을 불러올 수 없습니다. 인터넷 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get profileErrorNameEmpty => '이름을 비워 둘 수 없습니다.';

  @override
  String get profileErrorSaveName => '이름을 저장할 수 없습니다. 인터넷 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get contentErrorLessons => '강의를 불러올 수 없습니다. 인터넷 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get contentErrorProgress =>
      '진행 상황을 불러올 수 없습니다. 인터넷 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get materialsTitle => '자료';

  @override
  String get materialsPdf => 'PDF 문서';

  @override
  String materialsPdfSize(String size) {
    return 'PDF · $size';
  }

  @override
  String fileSizeMb(String size) {
    return '${size}MB';
  }

  @override
  String fileSizeKb(String size) {
    return '${size}KB';
  }

  @override
  String materialsOpenImage(String name) {
    return '이미지 열기: $name';
  }

  @override
  String materialsOpenPdf(String name) {
    return 'PDF 열기: $name';
  }
}
