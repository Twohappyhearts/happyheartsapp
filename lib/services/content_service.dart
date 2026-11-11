import 'package:html/parser.dart' as html_parser;
import 'package:supabase_flutter/supabase_flutter.dart';

import './tracking_service.dart';

/// Education content managed in the staff dashboard (public.content_items and
/// public.content_categories). RLS only returns ACTIVE sessions and ACTIVE
/// categories to patients, so anything staff hide disappears here.
///
/// Sessions are returned as the Map shape the existing education widgets use
/// (title, category, description, duration, status, imageUrl, semanticLabel,
/// infographicUrl, videoUrl, videoId, kahootUrl, ...). Optional media are null.
class ContentException implements Exception {
  final String message;
  const ContentException(this.message);
  @override
  String toString() => message;
}

class EducationContent {
  final List<String> categories; // ordered, active only
  final List<Map<String, dynamic>> sessions; // ordered by Session 1, 2, ...
  const EducationContent(this.categories, this.sessions);
}

class _Progress {
  final bool completed;
  final bool quizCompleted;
  const _Progress({required this.completed, required this.quizCompleted});
}

/// One lesson's progress for the signed-in patient (lesson_progress view +
/// events still waiting in the local outbox).
class LessonProgress {
  final String contentId;
  final bool completed;
  final int timeOnPageSec;
  final DateTime? completedAt;
  final DateTime? quizCompletedAt;
  final DateTime? lastActivityAt;

  const LessonProgress({
    required this.contentId,
    required this.completed,
    required this.timeOnPageSec,
    this.completedAt,
    this.quizCompletedAt,
    this.lastActivityAt,
  });

  LessonProgress copyWith({
    bool? completed,
    int? timeOnPageSec,
    DateTime? completedAt,
    DateTime? quizCompletedAt,
    DateTime? lastActivityAt,
  }) => LessonProgress(
    contentId: contentId,
    completed: completed ?? this.completed,
    timeOnPageSec: timeOnPageSec ?? this.timeOnPageSec,
    completedAt: completedAt ?? this.completedAt,
    quizCompletedAt: quizCompletedAt ?? this.quizCompletedAt,
    lastActivityAt: lastActivityAt ?? this.lastActivityAt,
  );
}

/// Totals shown in Progress and in Profile > Learning Summary. Only lessons
/// currently visible in the app count (same rules on both screens).
class LearningSummary {
  final int totalLessons;
  final int completed;
  final int inProgress;
  final int timeSpentSec;

  const LearningSummary({
    required this.totalLessons,
    required this.completed,
    required this.inProgress,
    required this.timeSpentSec,
  });

  double get percent => totalLessons == 0 ? 0 : completed / totalLessons;

  static LearningSummary compute(
    List<Map<String, dynamic>> sessions,
    Map<String, LessonProgress> progress,
  ) {
    var completed = 0, inProgress = 0, seconds = 0;
    for (final s in sessions) {
      final p = progress[s['id']];
      if (p == null) continue;
      if (p.completed) {
        completed++;
      } else {
        inProgress++;
      }
      seconds += p.timeOnPageSec;
    }
    return LearningSummary(
      totalLessons: sessions.length,
      completed: completed,
      inProgress: inProgress,
      timeSpentSec: seconds,
    );
  }

  /// 45 min -> "45m", 135 min -> "2h 15m".
  static String formatTime(int seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }
}

class ContentService {
  ContentService._();
  static final ContentService instance = ContentService._();

  SupabaseClient get _client => Supabase.instance.client;

  static const String _columns =
      'id, title, description, group_id, group_number, group_name, tags, '
      'video_url, audio_url, thumbnail_url, thumbnail_alt, infographic_url, '
      'quiz_url, script_html, video_duration, audio_duration, reference_links, '
      'category:content_categories(name)';

  Future<EducationContent> loadEducation() async {
    try {
      // Awaited one by one: the Supabase query builders have different result
      // types, so they can't go through Future.wait as a single list.
      final List<Map<String, dynamic>> categoryRows = await _client
          .from('content_categories')
          .select('name, sort_order')
          // Staff accounts can read inactive rows too; the app never shows them.
          .eq('is_active', true)
          .order('sort_order')
          .order('name');
      final List<Map<String, dynamic>> sessionRows = await _client
          .from('content_items')
          .select(_columns)
          .eq('kind', 'session')
          .eq('is_active', true)
          .order('group_number');
      final progress = await _progress();

      final categories = categoryRows
          .map((r) => r['name'] as String)
          .toList();
      final sessions = sessionRows
          .map((r) => _toModule(r, progress))
          .toList();
      return EducationContent(categories, sessions);
    } on PostgrestException catch (e) {
      throw ContentException('Could not load lessons: ${e.message}');
    } catch (_) {
      throw const ContentException(
        'Could not load lessons. Check your connection and try again.',
      );
    }
  }

  /// content_id -> this patient's progress (for the Progress tab).
  Future<Map<String, LessonProgress>> loadMyProgress() async {
    final map = <String, LessonProgress>{};
    try {
      final rows = await _client
          .from('lesson_progress')
          .select(
            'content_id, status, time_on_page_s, completed_at, '
            'quiz_completed_at, last_activity_at',
          )
          .limit(1000);
      for (final r in rows as List) {
        final row = r as Map<String, dynamic>;
        final id = row['content_id'] as String?;
        if (id == null) continue;
        map[id] = LessonProgress(
          contentId: id,
          completed: row['status'] == 'completed',
          timeOnPageSec: (row['time_on_page_s'] as num?)?.round() ?? 0,
          completedAt: _date(row['completed_at']),
          quizCompletedAt: _date(row['quiz_completed_at']),
          lastActivityAt: _date(row['last_activity_at']),
        );
      }
    } on PostgrestException catch (e) {
      throw ContentException('Could not load your progress: ${e.message}');
    } catch (_) {
      throw const ContentException(
        'Could not load your progress. Check your connection and try again.',
      );
    }

    // Merge what was done in the last few seconds / offline.
    LessonProgress entry(String id) =>
        map[id] ?? LessonProgress(contentId: id, completed: false, timeOnPageSec: 0);
    final t = TrackingService.instance;
    for (final e in t.pendingEvents(TrackingEvents.sessionClosed)) {
      final p = entry(e.contentId);
      map[e.contentId] = p.copyWith(
        timeOnPageSec: p.timeOnPageSec + (e.value?.round() ?? 0),
        lastActivityAt: _later(p.lastActivityAt, e.at),
      );
    }
    for (final e in t.pendingEvents(TrackingEvents.sessionOpened)) {
      final p = entry(e.contentId);
      map[e.contentId] = p.copyWith(lastActivityAt: _later(p.lastActivityAt, e.at));
    }
    for (final e in t.pendingEvents(TrackingEvents.sessionCompleted)) {
      final p = entry(e.contentId);
      map[e.contentId] = p.copyWith(
        completed: true,
        completedAt: p.completedAt ?? e.at,
      );
    }
    for (final e in t.pendingEvents(TrackingEvents.quizCompleted)) {
      final p = entry(e.contentId);
      map[e.contentId] = p.copyWith(quizCompletedAt: p.quizCompletedAt ?? e.at);
    }
    return map;
  }

  Future<LearningSummary> loadLearningSummary() async {
    final content = await loadEducation();
    final progress = await loadMyProgress();
    return LearningSummary.compute(content.sessions, progress);
  }

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  static DateTime _later(DateTime? a, DateTime b) =>
      a == null || b.isAfter(a) ? b : a;

  /// First active session (fallback when a lesson page opens without one).
  Future<Map<String, dynamic>?> firstSession() async {
    final content = await loadEducation();
    return content.sessions.isEmpty ? null : content.sessions.first;
  }

  /// content_id -> progress, from this user's own rows in the lesson_progress
  /// view (derived from tracking_events; RLS limits it to the caller).
  /// Events still waiting in the local outbox count too, so a lesson marked
  /// completed offline shows as completed right away.
  Future<Map<String, _Progress>> _progress() async {
    final map = <String, _Progress>{};
    try {
      final rows = await _client
          .from('lesson_progress')
          .select('content_id, status, quiz_completed_at')
          .limit(1000);
      for (final r in rows as List) {
        final row = r as Map<String, dynamic>;
        final id = row['content_id'] as String?;
        if (id == null) continue;
        map[id] = _Progress(
          completed: row['status'] == 'completed',
          quizCompleted: row['quiz_completed_at'] != null,
        );
      }
    } catch (_) {
      // progress is nice-to-have; never block the lessons
    }
    return map;
  }

  static String? _nonEmpty(Object? v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  static String? youTubeId(String? url) {
    if (url == null) return null;
    final patterns = [
      RegExp(r'youtube\.com/watch\?(?:.*&)?v=([A-Za-z0-9_-]{6,})'),
      RegExp(r'youtu\.be/([A-Za-z0-9_-]{6,})'),
      RegExp(r'youtube\.com/(?:embed|shorts|live)/([A-Za-z0-9_-]{6,})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  /// The lesson's References block: its own links first (video, audio, the
  /// links in the lesson notes), then the links staff added in the dashboard
  /// (content_items.reference_links). https only, each link once.
  /// Keep in step with lessonOwnReferences() in the dashboard (src/lib/content.ts).
  static List<Map<String, String>> _references({
    String? videoUrl,
    String? audioUrl,
    String? scriptHtml,
    Object? added,
  }) {
    final out = <Map<String, String>>[];
    final seen = <String>{};
    void add(String title, String? url) {
      final u = url?.trim() ?? '';
      if (!u.toLowerCase().startsWith('https://')) return;
      final key = u.replaceFirst(RegExp(r'/+$'), '').toLowerCase();
      if (!seen.add(key)) return;
      out.add({'title': title.trim(), 'url': u});
    }

    add('Lesson video', videoUrl);
    add('Lesson audio', audioUrl);
    if (scriptHtml != null) {
      final links = html_parser.parseFragment(scriptHtml).querySelectorAll('a');
      for (final a in links) {
        final href = a.attributes['href'];
        final text = a.text.replaceAll(RegExp(r'\s+'), ' ').trim();
        add(text == href?.trim() ? '' : text, href);
      }
    }
    if (added is List) {
      for (final r in added) {
        if (r is Map) add('${r['title'] ?? ''}', r['url']?.toString());
      }
    }
    return out;
  }

  static int _seconds(String? mmss) {
    if (mmss == null) return 0;
    final parts = mmss.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  /// "6 min" from the video + audio estimates, or '' if none were entered.
  static String _durationLabel(String? video, String? audio) {
    final total = _seconds(video) + _seconds(audio);
    if (total <= 0) return '';
    final minutes = (total / 60).ceil();
    return '$minutes min';
  }

  static String _status(String id, _Progress? p) {
    if ((p?.completed ?? false) ||
        TrackingService.instance.hasPending(
          id,
          TrackingEvents.sessionCompleted,
        )) {
      return 'completed';
    }
    if (p != null ||
        TrackingService.instance.hasPending(id, TrackingEvents.sessionOpened)) {
      return 'in_progress';
    }
    return 'available';
  }

  Map<String, dynamic> _toModule(
    Map<String, dynamic> r,
    Map<String, _Progress> progress,
  ) {
    final cat = r['category'];
    final catName = cat is Map ? cat['name'] as String? : null;
    final title = (r['title'] as String?) ?? '';
    final videoUrl = _nonEmpty(r['video_url']);
    final audioUrl = _nonEmpty(r['audio_url']);
    final scriptHtml = _nonEmpty(r['script_html']);
    final id = r['id'] as String;
    return {
      'id': id,
      'groupId': r['group_id'],
      'groupName': r['group_name'],
      'title': title,
      'category': catName ?? 'Other',
      'description': (r['description'] as String?) ?? '',
      'duration': _durationLabel(
        _nonEmpty(r['video_duration']),
        _nonEmpty(r['audio_duration']),
      ),
      'status': _status(id, progress[id]),
      'quizCompleted': (progress[id]?.quizCompleted ?? false) ||
          TrackingService.instance.hasPending(id, TrackingEvents.quizCompleted),
      'imageUrl': _nonEmpty(r['thumbnail_url']) ?? '',
      'semanticLabel': _nonEmpty(r['thumbnail_alt']) ?? title,
      'infographicUrl': _nonEmpty(r['infographic_url']),
      'videoUrl': videoUrl,
      'videoId': youTubeId(videoUrl),
      'videoDuration': _nonEmpty(r['video_duration']),
      'audioUrl': audioUrl,
      'audioDuration': _nonEmpty(r['audio_duration']),
      'kahootUrl': _nonEmpty(r['quiz_url']),
      'scriptHtml': scriptHtml,
      'references': _references(
        videoUrl: videoUrl,
        audioUrl: audioUrl,
        scriptHtml: scriptHtml,
        added: r['reference_links'],
      ),
      'tags': (r['tags'] as List?)?.cast<String>() ?? const <String>[],
    };
  }
}
