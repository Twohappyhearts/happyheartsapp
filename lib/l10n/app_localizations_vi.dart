// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get retry => 'Thử lại';

  @override
  String get cancel => 'Hủy';

  @override
  String get save => 'Lưu';

  @override
  String get done => 'Xong';

  @override
  String get close => 'Đóng';

  @override
  String get back => 'Quay lại';

  @override
  String get view => 'Xem';

  @override
  String get signOut => 'Đăng xuất';

  @override
  String get errorGeneric => 'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String get errorConnection =>
      'Đã xảy ra lỗi. Hãy kiểm tra kết nối mạng và thử lại.';

  @override
  String get errorServerUnreachable =>
      'Không kết nối được máy chủ. Hãy kiểm tra kết nối mạng và thử lại.';

  @override
  String get couldNotOpenLink => 'Không mở được liên kết này.';

  @override
  String get requestSent =>
      'Đã gửi yêu cầu. Một thành viên trong nhóm sẽ liên lạc với bạn.';

  @override
  String get statusCompleted => 'Đã hoàn thành';

  @override
  String get statusInProgress => 'Đang học';

  @override
  String get statusAvailable => 'Sẵn sàng';

  @override
  String get statusNotStarted => 'Chưa bắt đầu';

  @override
  String get dateToday => 'Hôm nay';

  @override
  String get dateYesterday => 'Hôm qua';

  @override
  String dateTodayAt(String time) {
    return 'Hôm nay, $time';
  }

  @override
  String dateYesterdayAt(String time) {
    return 'Hôm qua, $time';
  }

  @override
  String dateAt(String date, String time) {
    return '$date, $time';
  }

  @override
  String minutesShort(int minutes) {
    return '$minutes phút';
  }

  @override
  String timeMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String timeHoursMinutes(int hours, int minutes) {
    return '$hours giờ $minutes phút';
  }

  @override
  String linkSemantic(String text) {
    return 'Liên kết: $text';
  }

  @override
  String get languageTitle => 'Ngôn ngữ';

  @override
  String get languagePhone => 'Ngôn ngữ của điện thoại';

  @override
  String languagePhoneDetail(String language) {
    return 'Giống điện thoại của bạn ($language)';
  }

  @override
  String get languagePickerTitle => 'Chọn ngôn ngữ';

  @override
  String languageButtonSemantic(String language) {
    return 'Ngôn ngữ: $language. Chạm để đổi.';
  }

  @override
  String get authTagline => 'Người bạn đồng hành học về sức khỏe của bạn';

  @override
  String get authTabSignIn => 'Đăng nhập';

  @override
  String get authTabCreateAccount => 'Tạo tài khoản';

  @override
  String get signInWelcome => 'Chào mừng bạn trở lại 👋';

  @override
  String get signInSubtitle =>
      'Đăng nhập để tiếp tục hành trình sức khỏe của bạn';

  @override
  String get fieldEmail => 'Địa chỉ email';

  @override
  String get fieldEmailHint => 'Nhập email của bạn';

  @override
  String get validationEmailRequired => 'Vui lòng nhập email';

  @override
  String get validationEmailInvalid => 'Vui lòng nhập email hợp lệ';

  @override
  String get fieldPassword => 'Mật khẩu';

  @override
  String get fieldPasswordHint => 'Nhập mật khẩu';

  @override
  String get validationPasswordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String get showPassword => 'Hiện mật khẩu';

  @override
  String get hidePassword => 'Ẩn mật khẩu';

  @override
  String get signInForgot => 'Quên mật khẩu?';

  @override
  String get createTitle => 'Tạo tài khoản của bạn';

  @override
  String get createSubtitle =>
      'Bắt đầu hành trình học về sức khỏe ngay hôm nay';

  @override
  String get fieldFullName => 'Họ và tên';

  @override
  String get fieldFullNameHint => 'Nhập họ và tên';

  @override
  String get validationNameRequired => 'Vui lòng nhập tên';

  @override
  String get fieldUsername => 'Tên người dùng';

  @override
  String get fieldUsernameHint =>
      'Tên người dùng mà nhóm nghiên cứu đã cấp cho bạn';

  @override
  String get fieldUsernameHelper =>
      'Hãy dùng tên người dùng mà nhóm nghiên cứu đã cấp. Tên này liên kết các khảo sát với tài khoản của bạn và không thể đổi sau này.';

  @override
  String get validationUsernameRequired => 'Vui lòng nhập tên người dùng';

  @override
  String get validationUsernameFormat =>
      'Dùng 3–20 chữ cái hoặc chữ số (không có khoảng trắng hay ký hiệu)';

  @override
  String get fieldPhone => 'Số điện thoại';

  @override
  String get fieldPhoneHint => 'ví dụ: (949) 555-0100';

  @override
  String get validationPhoneRequired => 'Vui lòng nhập số điện thoại';

  @override
  String get validationPhoneInvalid => 'Vui lòng nhập số điện thoại hợp lệ';

  @override
  String get fieldCreatePasswordHint => 'Tạo mật khẩu';

  @override
  String get validationNewPasswordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String get validationPasswordMin8 => 'Mật khẩu phải có ít nhất 8 ký tự';

  @override
  String get fieldConfirmPassword => 'Xác nhận mật khẩu';

  @override
  String get fieldConfirmPasswordHint => 'Nhập lại mật khẩu';

  @override
  String get validationConfirmRequired => 'Vui lòng xác nhận mật khẩu';

  @override
  String get validationPasswordsMismatch => 'Mật khẩu không khớp';

  @override
  String get legalTerms => 'Điều khoản sử dụng';

  @override
  String get legalPrivacy => 'Chính sách quyền riêng tư';

  @override
  String createAgree(String terms, String privacy) {
    return 'Tôi đồng ý với $terms và $privacy';
  }

  @override
  String get createAgreeRequired =>
      'Vui lòng đồng ý với Điều khoản sử dụng và Chính sách quyền riêng tư';

  @override
  String get authErrorCredentials => 'Email hoặc mật khẩu không đúng.';

  @override
  String get authErrorUsernameRejected =>
      'Tên người dùng này đã có người dùng hoặc không hợp lệ. Vui lòng chọn tên khác.';

  @override
  String get authErrorUsernameTaken =>
      'Tên người dùng này đã có người dùng. Hãy dùng tên người dùng mà nhóm nghiên cứu đã cấp, hoặc liên hệ nhóm chăm sóc nếu tên đã được đăng ký.';

  @override
  String get authErrorDisabled =>
      'Tài khoản này đã bị vô hiệu hóa. Vui lòng liên hệ nhóm chăm sóc của bạn.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Vui lòng xác nhận email trước khi đăng nhập.';

  @override
  String get authErrorEmailExists =>
      'Đã có tài khoản dùng email này. Hãy thử đăng nhập.';

  @override
  String get authErrorRateLimited =>
      'Bạn đã thử quá nhiều lần. Vui lòng đợi một phút rồi thử lại.';

  @override
  String get authErrorPassword => 'Vui lòng chọn mật khẩu khác.';

  @override
  String get checkEmailTitle => 'Kiểm tra email của bạn';

  @override
  String checkEmailBody(String email) {
    return 'Chúng tôi đã gửi liên kết xác nhận đến\n$email\nHãy mở liên kết trên thiết bị này để hoàn tất việc tạo tài khoản.';
  }

  @override
  String get checkEmailResent => 'Đã gửi lại email xác nhận.';

  @override
  String get checkEmailResend => 'Gửi lại email xác nhận';

  @override
  String get backToSignIn => 'Quay lại đăng nhập';

  @override
  String get forgotTitle => 'Đặt lại mật khẩu';

  @override
  String get forgotIntro =>
      'Nhập email và chúng tôi sẽ gửi cho bạn liên kết đặt lại mật khẩu.';

  @override
  String forgotSent(String email) {
    return 'Nếu có tài khoản dùng $email, liên kết đặt lại mật khẩu đang được gửi đến. Hãy mở nó trên thiết bị này.';
  }

  @override
  String get forgotSend => 'Gửi liên kết đặt lại';

  @override
  String get resetTitle => 'Chọn mật khẩu mới';

  @override
  String get passwordMinShort => 'Dùng ít nhất 8 ký tự.';

  @override
  String get fieldNewPassword => 'Mật khẩu mới';

  @override
  String get fieldConfirmNewPassword => 'Xác nhận mật khẩu mới';

  @override
  String get resetButton => 'Cập nhật mật khẩu';

  @override
  String get gateTitle => 'Đặt mật khẩu mới';

  @override
  String get gateBody =>
      'Nhóm chăm sóc đã tạo tài khoản này với mật khẩu tạm thời. Vui lòng chọn mật khẩu của riêng bạn để tiếp tục.';

  @override
  String get gateRule =>
      'Ít nhất 8 ký tự, gồm một chữ hoa, một chữ thường và một chữ số.';

  @override
  String get gateErrorMix =>
      'Hãy có một chữ hoa, một chữ thường và một chữ số.';

  @override
  String get gateSuccess => 'Đã cập nhật mật khẩu. Chào mừng bạn!';

  @override
  String get gateErrorSame => 'Hãy chọn mật khẩu khác với mật khẩu tạm thời.';

  @override
  String get gateErrorFailed =>
      'Không cập nhật được mật khẩu. Hãy kiểm tra kết nối mạng.';

  @override
  String get gateSave => 'Lưu mật khẩu';

  @override
  String get menuOpen => 'Mở menu';

  @override
  String get menuAssessments => 'Đánh giá toàn diện';

  @override
  String get menuAssessmentsSubtitle => 'Bảng câu hỏi từ nhóm chăm sóc của bạn';

  @override
  String get menuAssistance => 'Tôi cần hỗ trợ';

  @override
  String get menuAssistanceSubtitle => 'Nhờ nhóm chăm sóc giúp đỡ';

  @override
  String get menuMyRequests => 'Yêu cầu hỗ trợ của tôi';

  @override
  String get menuMyRequestsSubtitle => 'Xem tình trạng các yêu cầu bạn đã gửi';

  @override
  String get menuEmergency => 'Trong trường hợp khẩn cấp, hãy gọi 911.';

  @override
  String get navEducation => 'Bài học';

  @override
  String get navResources => 'Tài nguyên';

  @override
  String get navProgress => 'Tiến độ';

  @override
  String get navChat => 'Trò chuyện';

  @override
  String get navProfile => 'Hồ sơ';

  @override
  String get crashTitle => 'Đã xảy ra lỗi';

  @override
  String get crashBody =>
      'Vui lòng khởi động lại ứng dụng. Nếu vẫn bị lỗi, hãy liên hệ nhóm nghiên cứu.';

  @override
  String get homeGoodMorning => 'Chào buổi sáng';

  @override
  String get homeGoodAfternoon => 'Chào buổi chiều';

  @override
  String get homeGoodEvening => 'Chào buổi tối';

  @override
  String get homeHi => 'Xin chào 👋';

  @override
  String homeHiName(String name) {
    return 'Chào $name 👋';
  }

  @override
  String get homeTitle => 'Trung tâm học\nvề sức khỏe của bạn';

  @override
  String get homeSearchHint => 'Tìm bài học, chủ đề...';

  @override
  String get homeCategoryAll => 'Tất cả';

  @override
  String get homeNoLessons => 'Hiện chưa có bài học nào. Hãy quay lại sau.';

  @override
  String get homeNoMatches =>
      'Không có bài học nào phù hợp với tìm kiếm của bạn.';

  @override
  String get progressCardTitle => 'Tiến độ của bạn';

  @override
  String progressCardLessons(int completed, int total) {
    return '$completed / $total bài học';
  }

  @override
  String get progressCardStart => 'Hãy bắt đầu nào!';

  @override
  String progressCardGreat(int percent) {
    return 'Đã hoàn thành $percent% — bạn làm rất tốt!';
  }

  @override
  String progressCardKeepGoing(int percent) {
    return 'Đã hoàn thành $percent% — tiếp tục nhé!';
  }

  @override
  String get progressCardDone => 'Đã hoàn thành 100% — thật tuyệt vời!';

  @override
  String get lessonHeader => 'Bài học';

  @override
  String get lessonNoLessonsShort => 'Hiện chưa có bài học nào.';

  @override
  String get lessonNoneSelected => 'Chưa chọn bài học.';

  @override
  String get lessonMarked => 'Đã đánh dấu bài học là hoàn thành. Làm tốt lắm!';

  @override
  String get lessonCompletedTitle => 'Đã hoàn thành bài học';

  @override
  String get lessonFinishPrompt => 'Bạn đã học xong bài này?';

  @override
  String get lessonCompletedBody =>
      'Làm tốt lắm! Bạn có thể quay lại ôn bất cứ lúc nào.';

  @override
  String get lessonFinishBody =>
      'Hãy đánh dấu hoàn thành để theo dõi tiến độ của bạn.';

  @override
  String get lessonMarkButton => 'Đánh dấu hoàn thành';

  @override
  String lessonSections(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phần',
    );
    return '$_temp0';
  }

  @override
  String get refTitle => 'Tài liệu tham khảo';

  @override
  String get refLessonVideo => 'Video bài học';

  @override
  String get refLessonAudio => 'Âm thanh bài học';

  @override
  String get scriptTitle => 'Ghi chú bài học';

  @override
  String get scriptReadMore => 'Xem thêm';

  @override
  String get scriptShowLess => 'Thu gọn';

  @override
  String get infoTitle => 'Đồ họa thông tin';

  @override
  String get infoCardTitle => 'Đồ họa thông tin của bài học';

  @override
  String infoCardSubtitle(String title) {
    return 'Tóm tắt bằng hình ảnh về $title';
  }

  @override
  String infoSemantic(String title) {
    return 'Đồ họa thông tin về $title';
  }

  @override
  String get infoTapHint => 'Chạm vào hình để xem toàn màn hình và phóng to';

  @override
  String get imageOpenFullscreen => 'Xem toàn màn hình';

  @override
  String get imageLoadFailed => 'Không tải được hình ảnh.';

  @override
  String get imageCloseFullscreen => 'Đóng chế độ toàn màn hình';

  @override
  String get imageZoomHint => 'Chụm hai ngón hoặc chạm hai lần để phóng to';

  @override
  String get videoTitle => 'Bài học video';

  @override
  String get videoPlaying => 'Đang phát video';

  @override
  String get videoTapToPlay => 'Chạm để xem video';

  @override
  String get videoYouTube => 'Video YouTube';

  @override
  String get audioTitle => 'Bài học âm thanh';

  @override
  String get audioOpen => 'Mở âm thanh';

  @override
  String get audioListen => 'Nghe bài học này';

  @override
  String get kahootTitle => 'Trò chơi kiến thức';

  @override
  String get kahootMarked =>
      'Làm tốt lắm! Đã đánh dấu hoàn thành bài trắc nghiệm.';

  @override
  String get kahootCopied => 'Đã sao chép tên người dùng.';

  @override
  String get kahootCopyTooltip => 'Sao chép tên người dùng';

  @override
  String get kahootUsernameLabel => 'Tên người dùng Kahoot của bạn';

  @override
  String get kahootUsernameHint =>
      'Hãy dùng tên này khi trò chơi Kahoot hỏi biệt danh';

  @override
  String get kahootIntro =>
      'Kiểm tra những gì bạn đã học với trò chơi Kahoot! tương tác';

  @override
  String get kahootBadgeTime => '⏱ ~5 phút';

  @override
  String get kahootBadgeInteractive => '✨ Tương tác';

  @override
  String get kahootBadgeFun => '🎉 Vui nhộn!';

  @override
  String get kahootStart => 'Bắt đầu trò chơi Kahoot!';

  @override
  String get kahootEmbedHint =>
      'Trò chơi sẽ mở bên dưới khi bạn chạm vào nút phía trên';

  @override
  String get kahootFinished => 'Đã làm xong bài trắc nghiệm';

  @override
  String get kahootIFinished => 'Tôi đã làm xong bài trắc nghiệm';

  @override
  String get chatAiTitle => 'Trợ lý AI';

  @override
  String get chatAiSubtitle => 'Trả lời tự động, 24/7';

  @override
  String get chatTeamTitle => 'Nhóm nghiên cứu';

  @override
  String get chatTeamSubtitle => 'Nghiên cứu Happy Hearts';

  @override
  String get chatTabTeam => 'Nhóm chăm sóc';

  @override
  String get chatSignInAi => 'Vui lòng đăng nhập để dùng trợ lý AI.';

  @override
  String get chatSignIn => 'Vui lòng đăng nhập để trò chuyện.';

  @override
  String get chatNeedHelp => 'Bạn cần giúp đỡ?';

  @override
  String get chatViewRequests => 'Xem yêu cầu của tôi';

  @override
  String get chatEmptyTitle => 'Bắt đầu trò chuyện';

  @override
  String get chatEmptyBody =>
      'Gửi tin nhắn cho nhóm nghiên cứu Happy Hearts. Chúng tôi sẵn sàng giúp bạn với mọi câu hỏi về nghiên cứu.';

  @override
  String get chatNotSent => 'Chưa gửi';

  @override
  String get chatDelete => 'Xóa';

  @override
  String get chatSending => 'Đang gửi…';

  @override
  String get chatInputHint => 'Nhắn tin cho nhóm nghiên cứu...';

  @override
  String get chatSend => 'Gửi';

  @override
  String get chatErrorWrongAccount =>
      'Tài khoản này không dùng được tính năng trò chuyện của bệnh nhân. Vui lòng đăng nhập bằng tài khoản bệnh nhân.';

  @override
  String get chatErrorOpen =>
      'Không mở được cuộc trò chuyện. Vui lòng thử lại.';

  @override
  String get chatErrorLoad =>
      'Không tải được tin nhắn. Hãy kiểm tra kết nối mạng và thử lại.';

  @override
  String get chatErrorKept =>
      'Không kết nối được máy chủ. Tin nhắn của bạn vẫn được giữ. Chạm Thử lại.';

  @override
  String get chatErrorNoPermission =>
      'Bạn không có quyền gửi tin nhắn trong cuộc trò chuyện này.';

  @override
  String get chatErrorLength => 'Tin nhắn phải có từ 1 đến 4000 ký tự.';

  @override
  String get chatErrorNotSent => 'Chưa gửi được tin nhắn. Vui lòng thử lại.';

  @override
  String get chatErrorGeneric => 'Đã xảy ra lỗi khi tải cuộc trò chuyện.';

  @override
  String get aiErrorConnection =>
      'Không tải được trợ lý AI. Hãy kiểm tra kết nối mạng.';

  @override
  String get aiErrorUnavailable => 'Trợ lý AI hiện không hoạt động.';

  @override
  String get aiErrorStart => 'Không khởi động được trợ lý AI.';

  @override
  String get aiErrorTimeout => 'Trợ lý AI tải quá lâu.';

  @override
  String get aiWebOnly =>
      'Trợ lý AI có trong ứng dụng HappyHearts trên iOS và Android.';

  @override
  String get assistMyRequests => 'Yêu cầu của tôi';

  @override
  String get assistIntro =>
      'Hãy cho nhóm nghiên cứu biết bạn cần giúp gì. Một thành viên sẽ liên lạc lại, thường là qua tin nhắn trong mục trò chuyện Nhóm chăm sóc.';

  @override
  String get assistEmergency =>
      'Mục này không được theo dõi suốt ngày đêm. Nếu là trường hợp khẩn cấp, hãy gọi 911.';

  @override
  String get assistHint =>
      'Ví dụ: \"Tôi có câu hỏi về thuốc của tôi\" hoặc \"Video trong Buổi 3 không phát được.\"';

  @override
  String get assistSend => 'Gửi yêu cầu';

  @override
  String get assistErrorEmpty => 'Vui lòng mô tả điều bạn cần giúp.';

  @override
  String assistErrorTooLong(int max) {
    return 'Vui lòng viết tin nhắn dưới $max ký tự.';
  }

  @override
  String get assistErrorOffline =>
      'Không kết nối được máy chủ. Tin nhắn của bạn vẫn được giữ — vui lòng thử lại.';

  @override
  String get assistErrorLoad =>
      'Không tải được các yêu cầu của bạn. Hãy kiểm tra kết nối mạng và thử lại.';

  @override
  String get assistErrorNotParticipant =>
      'Chỉ tài khoản người tham gia mới gửi được yêu cầu hỗ trợ.';

  @override
  String assistErrorLength(int max) {
    return 'Vui lòng viết tin nhắn từ 1 đến $max ký tự.';
  }

  @override
  String get assistErrorRateLimited =>
      'Gần đây bạn đã gửi nhiều yêu cầu. Nhóm sẽ sớm liên lạc với bạn. Nếu gấp, hãy gọi cho nhóm chăm sóc. Trong trường hợp khẩn cấp, hãy gọi 911.';

  @override
  String get assistErrorNotSent =>
      'Chưa gửi được yêu cầu. Tin nhắn của bạn vẫn được giữ — vui lòng thử lại.';

  @override
  String get requestsTitle => 'Yêu cầu hỗ trợ của tôi';

  @override
  String get requestsNew => 'Yêu cầu mới';

  @override
  String get requestsEmptyTitle => 'Chưa có yêu cầu nào';

  @override
  String get requestsEmptyBody =>
      'Khi cần nhóm nghiên cứu giúp đỡ, hãy gửi yêu cầu và bạn có thể theo dõi tình trạng ở đây.';

  @override
  String get requestStatusSent => 'Đã gửi';

  @override
  String get requestStatusSeen => 'Nhóm đã xem';

  @override
  String get requestStatusResolved => 'Đã giải quyết';

  @override
  String get requestWaiting => 'Đang chờ thành viên trong nhóm xem xét.';

  @override
  String get requestFollowing => 'Một thành viên trong nhóm đang xử lý.';

  @override
  String requestFollowingSince(String time) {
    return 'Một thành viên trong nhóm đang xử lý ($time).';
  }

  @override
  String get requestResolved => 'Đã đánh dấu là đã giải quyết.';

  @override
  String requestResolvedSince(String time) {
    return 'Đã đánh dấu là đã giải quyết ($time).';
  }

  @override
  String get assessSubtitleSurvey => 'Bảng câu hỏi từ nhóm chăm sóc của bạn.';

  @override
  String get assessSubtitleResources =>
      'Theo dõi sức khỏe tinh thần và thể chất với các công cụ sàng lọc đã được kiểm chứng.';

  @override
  String get assessEmptySurvey =>
      'Hiện chưa có đánh giá toàn diện nào. Nhóm chăm sóc sẽ thêm vào đây.';

  @override
  String get assessEmptyResources =>
      'Hiện chưa có tài nguyên nào. Nhóm chăm sóc sẽ thêm vào đây.';

  @override
  String get assessUsernameError =>
      'Không tải được tên người dùng của bạn. Vui lòng thử lại.';

  @override
  String assessLastCompleted(String date) {
    return 'Hoàn thành lần cuối: $date';
  }

  @override
  String get assessStart => 'Bắt đầu đánh giá';

  @override
  String get surveyErrorLoad =>
      'Không tải được khảo sát. Hãy kiểm tra kết nối mạng và thử lại.';

  @override
  String get surveyRecordFailed =>
      'Câu trả lời của bạn đã được gửi, nhưng ứng dụng không đánh dấu được khảo sát là đã hoàn thành.';

  @override
  String get surveyThanks => 'Cảm ơn bạn!';

  @override
  String get surveyThanksBody =>
      'Câu trả lời của bạn đã được gửi. Bạn có thể xem khảo sát này trong lịch Tiến độ.';

  @override
  String get surveyLoading => 'Đang tải khảo sát...';

  @override
  String get surveyLoadFailedTitle => 'Không tải được khảo sát';

  @override
  String get surveyLoadFailedBody =>
      'Vui lòng kiểm tra kết nối internet và thử lại.';

  @override
  String get progressSubtitle =>
      'Theo dõi quá trình học và ăn mừng các cột mốc.';

  @override
  String get progressCalendar => 'Lịch hoạt động';

  @override
  String get progressBreakdown => 'Các bài học';

  @override
  String activityCompleted(String title) {
    return 'Đã hoàn thành: $title';
  }

  @override
  String activityQuizFinished(String title) {
    return 'Đã làm xong trắc nghiệm: $title';
  }

  @override
  String activitySurveyFallback(String code) {
    return 'Khảo sát ($code)';
  }

  @override
  String get calPrevMonth => 'Tháng trước';

  @override
  String get calNextMonth => 'Tháng sau';

  @override
  String get legendLesson => 'Bài học';

  @override
  String get legendQuiz => 'Trắc nghiệm';

  @override
  String get legendSurvey => 'Khảo sát';

  @override
  String get calLessonDone => 'đã hoàn thành bài học';

  @override
  String get calQuizDone => 'đã làm xong trắc nghiệm';

  @override
  String get calSurveyDone => 'đã hoàn thành khảo sát';

  @override
  String get activityRecent => 'Hoạt động gần đây';

  @override
  String activityOnDay(String date) {
    return 'Hoạt động ngày $date';
  }

  @override
  String get activityShowAll => 'Xem tất cả';

  @override
  String get activityEmpty =>
      'Hoàn thành một bài học, bài trắc nghiệm hoặc khảo sát, và nó sẽ hiện ở đây.';

  @override
  String get activityEmptyDay =>
      'Không có hoạt động nào được hoàn thành trong ngày này.';

  @override
  String get overallTitle => 'Mức hoàn thành chung';

  @override
  String overallCount(int completed, int total) {
    return '$completed/$total bài học';
  }

  @override
  String get overallAllDone => '🎉 Đã hoàn thành tất cả bài học!';

  @override
  String get overallKeepGoing => 'Tiếp tục nhé — bạn đang tiến bộ rất tốt!';

  @override
  String get overallStart => 'Hãy bắt đầu bài học đầu tiên.';

  @override
  String get statTimeSpent => 'Thời gian học';

  @override
  String timeSpentSuffix(String time) {
    return 'đã học $time';
  }

  @override
  String get profileSignOutConfirm => 'Bạn có chắc muốn đăng xuất không?';

  @override
  String profileResetSent(String email) {
    return 'Đã gửi liên kết đặt lại mật khẩu đến $email';
  }

  @override
  String get profileAccount => 'Tài khoản';

  @override
  String get profileChangePassword => 'Đổi mật khẩu (gửi email đặt lại)';

  @override
  String get profilePreferences => 'Tùy chọn';

  @override
  String get profileAbout => 'Giới thiệu';

  @override
  String get profileVersion => 'Phiên bản ứng dụng';

  @override
  String get profileNotAvailable => 'Hồ sơ của bạn hiện không có.';

  @override
  String get profileEditName => 'Sửa tên';

  @override
  String get profileLearningSummary => 'Tóm tắt quá trình học';

  @override
  String get profileStatComplete => 'Hoàn thành';

  @override
  String get profileProgressFailed =>
      'Không tải được tiến độ. Chạm để thử lại.';

  @override
  String get profileErrorSignIn => 'Vui lòng đăng nhập.';

  @override
  String get profileErrorSessionChanged =>
      'Phiên đăng nhập đã thay đổi. Vui lòng thử lại.';

  @override
  String get profileErrorMissing =>
      'Không tìm thấy hồ sơ của bạn. Kéo xuống để thử lại; nếu vẫn bị, hãy liên hệ nhóm nghiên cứu.';

  @override
  String get profileErrorPermission => 'Bạn không có quyền xem hồ sơ này.';

  @override
  String get profileErrorLoad =>
      'Không tải được hồ sơ. Hãy kiểm tra kết nối mạng và thử lại.';

  @override
  String get profileErrorNameEmpty => 'Tên không được để trống.';

  @override
  String get profileErrorSaveName =>
      'Không lưu được tên. Hãy kiểm tra kết nối mạng và thử lại.';

  @override
  String get contentErrorLessons =>
      'Không tải được bài học. Hãy kiểm tra kết nối mạng và thử lại.';

  @override
  String get contentErrorProgress =>
      'Không tải được tiến độ. Hãy kiểm tra kết nối mạng và thử lại.';
}
