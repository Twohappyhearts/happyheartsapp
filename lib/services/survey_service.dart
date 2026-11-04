import 'package:supabase_flutter/supabase_flutter.dart';

/// Where a link is listed in the app (survey_links.placement), set by staff
/// on the dashboard. Both kinds are REDCap links opened the same way.
enum SurveyPlacement {
  /// The Resources tab in the bottom navigation.
  resource('resource'),

  /// Survey, opened from the side menu.
  survey('survey');

  const SurveyPlacement(this.dbValue);
  final String dbValue;
}

/// REDCap survey links managed on the dashboard (public.survey_links).
/// RLS only returns ACTIVE links to patients.
class SurveyLink {
  final String id;
  final String title;
  final String code;
  final String url;
  final String description;
  final String? category;
  final String? frequency;
  final String? duration;
  final int sortOrder;

  const SurveyLink({
    required this.id,
    required this.title,
    required this.code,
    required this.url,
    required this.description,
    this.category,
    this.frequency,
    this.duration,
    required this.sortOrder,
  });

  /// The URL the app opens: the public link + `participant_code=<username>`
  /// (Dashboard Prompt 5 / app Prompt 9).
  String personalizedUrl(String username) {
    final sep = url.contains('?') ? '&' : '?';
    return '$url${sep}participant_code=${Uri.encodeQueryComponent(username)}';
  }
}

class SurveyCompletion {
  final String? surveyId;
  final String code;
  final DateTime completedAt;
  const SurveyCompletion({
    required this.surveyId,
    required this.code,
    required this.completedAt,
  });
}

class SurveyException implements Exception {
  final String message;
  const SurveyException(this.message);
  @override
  String toString() => message;
}

class SurveyService {
  SurveyService._();
  static final SurveyService instance = SurveyService._();

  /// When a REDCap survey ends it can redirect here (set per survey in
  /// REDCap > Survey Settings > "Redirect to a URL"); the survey web view
  /// intercepts it and records the completion. Same origin as the media pages.
  static const String completionUrlPrefix =
      'https://io.happyhearts.app/survey-complete';

  SupabaseClient get _client => Supabase.instance.client;

  static String? _nonEmpty(Object? v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  Future<List<SurveyLink>> loadSurveys({
    SurveyPlacement placement = SurveyPlacement.resource,
  }) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('survey_links')
          .select(
            'id, title, code, url, description, category, frequency, '
            'duration, sort_order',
          )
          // Staff accounts can read hidden links too; the app never shows them.
          .eq('is_active', true)
          .eq('placement', placement.dbValue)
          .order('sort_order')
          .order('title');
      return rows
          .map(
            (r) => SurveyLink(
              id: r['id'] as String,
              title: (r['title'] as String?) ?? '',
              code: (r['code'] as String?) ?? '',
              url: (r['url'] as String?) ?? '',
              description: (r['description'] as String?) ?? '',
              category: _nonEmpty(r['category']),
              frequency: _nonEmpty(r['frequency']),
              duration: _nonEmpty(r['duration']),
              sortOrder: (r['sort_order'] as num?)?.toInt() ?? 0,
            ),
          )
          .where((s) => s.url.startsWith('https://'))
          .toList();
    } on PostgrestException catch (e) {
      throw SurveyException('Could not load surveys: ${e.message}');
    } catch (_) {
      throw const SurveyException(
        'Could not load surveys. Check your connection and try again.',
      );
    }
  }

  /// This patient's recorded completions, newest first.
  Future<List<SurveyCompletion>> myCompletions() async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('survey_completions')
          .select('survey_id, survey_code, completed_at')
          .order('completed_at', ascending: false)
          .limit(500);
      return rows
          .map(
            (r) => SurveyCompletion(
              surveyId: r['survey_id'] as String?,
              code: (r['survey_code'] as String?) ?? '',
              completedAt:
                  DateTime.tryParse(r['completed_at'] as String? ?? '')
                      ?.toLocal() ??
                  DateTime.now(),
            ),
          )
          .toList();
    } catch (_) {
      return const []; // nice-to-have; never block the list
    }
  }

  /// Called when the survey web view reaches the completion redirect.
  Future<void> recordCompletion(String code) async {
    try {
      await _client.rpc(
        'record_survey_completion',
        params: {'p_code': code},
      );
    } on PostgrestException catch (e) {
      throw SurveyException(e.message);
    }
  }

  /// Survey code from a completion redirect URL, or null if [url] isn't one.
  static String? completionCode(String url) {
    if (!url.startsWith(completionUrlPrefix)) return null;
    final uri = Uri.tryParse(url);
    final code = uri?.queryParameters['code']?.trim().toUpperCase();
    if (code == null || !RegExp(r'^[A-Z][A-Z0-9_]{0,49}$').hasMatch(code)) {
      return '';
    }
    return code;
  }
}
