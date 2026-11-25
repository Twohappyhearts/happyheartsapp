/// What the assistant is doing, shown in the patient's chat while it answers:
/// a row per search of the HappyHearts library (searchKnowledge) or of the
/// trusted websites (webSearch). Native chat only; the web chat shows a single
/// status line instead.
///
/// Every non-English text is a machine translation, pending research-team
/// review (like the rest of the chat's texts).
class AiToolStrings {
  final String searchingLibrary;
  final String searchedLibrary;
  final String searchingWeb;
  final String searchedWeb;
  final String searchFailed;
  final String Function(int n) results;

  const AiToolStrings({
    required this.searchingLibrary,
    required this.searchedLibrary,
    required this.searchingWeb,
    required this.searchedWeb,
    required this.searchFailed,
    required this.results,
  });

  /// Texts for an app language code (en, es, vi, ko, zh-Hans, zh-Hant, fa, ar); else English.
  static AiToolStrings of(String code) => _byLanguage[code] ?? _en;
}

final _en = AiToolStrings(
  searchingLibrary: 'Searching the HappyHearts library…',
  searchedLibrary: 'Searched the HappyHearts library',
  searchingWeb: 'Searching trusted websites…',
  searchedWeb: 'Searched trusted websites',
  searchFailed: 'This search did not work',
  results: (n) => n == 1 ? '1 result' : '$n results',
);

final Map<String, AiToolStrings> _byLanguage = {
  'en': _en,
  'es': AiToolStrings(
    searchingLibrary: 'Buscando en la biblioteca de HappyHearts…',
    searchedLibrary: 'Se buscó en la biblioteca de HappyHearts',
    searchingWeb: 'Buscando en sitios web confiables…',
    searchedWeb: 'Se buscó en sitios web confiables',
    searchFailed: 'Esta búsqueda no funcionó',
    results: (n) => n == 1 ? '1 resultado' : '$n resultados',
  ),
  'vi': AiToolStrings(
    searchingLibrary: 'Đang tìm trong thư viện HappyHearts…',
    searchedLibrary: 'Đã tìm trong thư viện HappyHearts',
    searchingWeb: 'Đang tìm trên các trang web đáng tin cậy…',
    searchedWeb: 'Đã tìm trên các trang web đáng tin cậy',
    searchFailed: 'Lần tìm kiếm này không thành công',
    results: (n) => '$n kết quả',
  ),
  'ko': AiToolStrings(
    searchingLibrary: 'HappyHearts 자료실에서 찾는 중…',
    searchedLibrary: 'HappyHearts 자료실에서 찾았습니다',
    searchingWeb: '신뢰할 수 있는 웹사이트에서 찾는 중…',
    searchedWeb: '신뢰할 수 있는 웹사이트에서 찾았습니다',
    searchFailed: '검색하지 못했습니다',
    results: (n) => '결과 $n개',
  ),
  'zh-Hans': AiToolStrings(
    searchingLibrary: '正在查找 HappyHearts 资料库…',
    searchedLibrary: '已查找 HappyHearts 资料库',
    searchingWeb: '正在查找可信网站…',
    searchedWeb: '已查找可信网站',
    searchFailed: '这次搜索没有成功',
    results: (n) => '$n 条结果',
  ),
  'zh-Hant': AiToolStrings(
    searchingLibrary: '正在查找 HappyHearts 資料庫…',
    searchedLibrary: '已查找 HappyHearts 資料庫',
    searchingWeb: '正在查找可信網站…',
    searchedWeb: '已查找可信網站',
    searchFailed: '這次搜尋沒有成功',
    results: (n) => '$n 筆結果',
  ),
  'fa': AiToolStrings(
    searchingLibrary: 'در حال جست‌وجو در کتابخانه HappyHearts…',
    searchedLibrary: 'در کتابخانه HappyHearts جست‌وجو شد',
    searchingWeb: 'در حال جست‌وجو در وب‌سایت‌های معتبر…',
    searchedWeb: 'در وب‌سایت‌های معتبر جست‌وجو شد',
    searchFailed: 'این جست‌وجو انجام نشد',
    results: (n) => '$n نتیجه',
  ),
  'ar': AiToolStrings(
    searchingLibrary: 'جارٍ البحث في مكتبة HappyHearts…',
    searchedLibrary: 'تم البحث في مكتبة HappyHearts',
    searchingWeb: 'جارٍ البحث في مواقع إلكترونية موثوقة…',
    searchedWeb: 'تم البحث في مواقع إلكترونية موثوقة',
    searchFailed: 'تعذّر إجراء هذا البحث',
    results: (n) => n == 1
        ? 'نتيجة واحدة'
        : n == 2
        ? 'نتيجتان'
        : n <= 10
        ? '$n نتائج'
        : '$n نتيجة',
  ),
};
