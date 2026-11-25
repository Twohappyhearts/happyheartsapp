/// Texts of the broadcast inbox (menu item and screen).
///
/// Every non-English text is a machine translation, pending research-team
/// review (like the AI chat's texts).
class InboxStrings {
  final String menu;
  final String menuSubtitle;
  final String title;
  final String emptyTitle;
  final String emptyBody;
  final String newBadge;
  final String loadFailed;
  final String Function(int n) unread;

  const InboxStrings({
    required this.menu,
    required this.menuSubtitle,
    required this.title,
    required this.emptyTitle,
    required this.emptyBody,
    required this.newBadge,
    required this.loadFailed,
    required this.unread,
  });

  /// Texts for an app language code (en, es, vi, ko, zh-Hans, zh-Hant, fa, ar); else English.
  static InboxStrings of(String code) => _byLanguage[code] ?? _en;
}

final _en = InboxStrings(
  menu: 'Inbox',
  menuSubtitle: 'Messages from the research team',
  title: 'Inbox',
  emptyTitle: 'No messages yet',
  emptyBody: 'Messages the research team sends to everyone will appear here.',
  newBadge: 'NEW',
  loadFailed: 'Could not load your messages. Please try again.',
  unread: (n) => n == 1 ? '1 unread message' : '$n unread messages',
);

final Map<String, InboxStrings> _byLanguage = {
  'en': _en,
  'es': InboxStrings(
    menu: 'Bandeja de entrada',
    menuSubtitle: 'Mensajes del equipo de investigación',
    title: 'Bandeja de entrada',
    emptyTitle: 'Todavía no hay mensajes',
    emptyBody:
        'Aquí aparecerán los mensajes que el equipo de investigación envíe a todos.',
    newBadge: 'NUEVO',
    loadFailed: 'No se pudieron cargar sus mensajes. Inténtelo de nuevo.',
    unread: (n) => n == 1 ? '1 mensaje sin leer' : '$n mensajes sin leer',
  ),
  'vi': InboxStrings(
    menu: 'Hộp thư',
    menuSubtitle: 'Tin nhắn từ nhóm nghiên cứu',
    title: 'Hộp thư',
    emptyTitle: 'Chưa có tin nhắn',
    emptyBody: 'Các tin nhắn nhóm nghiên cứu gửi cho mọi người sẽ hiện ở đây.',
    newBadge: 'MỚI',
    loadFailed: 'Không tải được tin nhắn. Vui lòng thử lại.',
    unread: (n) => '$n tin nhắn chưa đọc',
  ),
  'ko': InboxStrings(
    menu: '받은 메시지',
    menuSubtitle: '연구팀이 보낸 메시지',
    title: '받은 메시지',
    emptyTitle: '아직 메시지가 없습니다',
    emptyBody: '연구팀이 모두에게 보내는 메시지가 여기에 표시됩니다.',
    newBadge: '새 메시지',
    loadFailed: '메시지를 불러오지 못했습니다. 다시 시도해 주세요.',
    unread: (n) => '읽지 않은 메시지 $n개',
  ),
  'zh-Hans': InboxStrings(
    menu: '收件箱',
    menuSubtitle: '研究团队发来的消息',
    title: '收件箱',
    emptyTitle: '还没有消息',
    emptyBody: '研究团队群发的消息会显示在这里。',
    newBadge: '新',
    loadFailed: '无法加载消息，请重试。',
    unread: (n) => '$n 条未读消息',
  ),
  'zh-Hant': InboxStrings(
    menu: '收件匣',
    menuSubtitle: '研究團隊傳來的訊息',
    title: '收件匣',
    emptyTitle: '還沒有訊息',
    emptyBody: '研究團隊群發的訊息會顯示在這裡。',
    newBadge: '新',
    loadFailed: '無法載入訊息，請再試一次。',
    unread: (n) => '$n 則未讀訊息',
  ),
  'fa': InboxStrings(
    menu: 'صندوق پیام',
    menuSubtitle: 'پیام‌های تیم پژوهش',
    title: 'صندوق پیام',
    emptyTitle: 'هنوز پیامی نیست',
    emptyBody: 'پیام‌هایی که تیم پژوهش برای همه می‌فرستد اینجا نشان داده می‌شود.',
    newBadge: 'جدید',
    loadFailed: 'پیام‌ها بارگیری نشد. لطفاً دوباره امتحان کنید.',
    unread: (n) => '$n پیام خوانده‌نشده',
  ),
  'ar': InboxStrings(
    menu: 'صندوق الرسائل',
    menuSubtitle: 'رسائل من فريق البحث',
    title: 'صندوق الرسائل',
    emptyTitle: 'لا توجد رسائل بعد',
    emptyBody: 'ستظهر هنا الرسائل التي يرسلها فريق البحث إلى الجميع.',
    newBadge: 'جديد',
    loadFailed: 'تعذّر تحميل الرسائل. يُرجى المحاولة مرة أخرى.',
    unread: (n) => n == 1 ? 'رسالة واحدة غير مقروءة' : '$n رسائل غير مقروءة',
  ),
};
