import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../services/app_language.dart';
import '../../services/content_service.dart';
import '../../services/survey_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_menu.dart';

/// Progress tab: the patient's real lesson progress (lesson_progress view,
/// derived from the events the app sends), plus an activity calendar.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<Map<String, dynamic>> _modules = const [];
  Map<String, LessonProgress> _progress = const {};
  List<_Activity> _surveyActivities = const [];
  bool _loading = true;
  String? _error;
  bool _wasVisible = false;

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;

  /// The "Lessons" header; the summary cards scroll down to it.
  final GlobalKey _lessonsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load(silent: true); // _loading already starts as true
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Bottom tabs stay alive in an IndexedStack; refresh whenever this tab
    // becomes visible again (e.g. after finishing a lesson).
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible && !_wasVisible && !_loading) _load(silent: true);
    _wasVisible = visible;
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final content = await ContentService.instance.loadEducation();
      final progress = await ContentService.instance.loadMyProgress();
      final surveyActivities = await _loadSurveyActivities();
      if (!mounted) return;
      setState(() {
        _modules = content.sessions;
        _progress = progress;
        _surveyActivities = surveyActivities;
        _loading = false;
        _error = null;
      });
    } on ContentException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (!silent || _modules.isEmpty) _error = e.message;
      });
    }
  }

  /// The summary cards are tappable: they lead to the lesson list below.
  void _scrollToLessons() {
    final target = _lessonsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  /// Opens a lesson inside the Progress tab; back returns here.
  Future<void> _openLesson(Map<String, dynamic> module) async {
    await context.push(AppRoutes.progressLesson, extra: module);
    // Back from the lesson: show the updated status and time.
    if (mounted) _load(silent: true);
  }

  /// Completed REDCap surveys (recorded when the survey redirects back).
  Future<List<_Activity>> _loadSurveyActivities() async {
    final completions = await SurveyService.instance.myCompletions();
    if (completions.isEmpty) return const [];
    var titles = <String, String>{};
    try {
      titles = {
        for (final s in await SurveyService.instance.loadSurveys())
          s.id: s.title,
      };
    } catch (_) {}
    return [
      for (final c in completions)
        _Activity(
          _ActivityKind.survey,
          titles[c.surveyId] ?? '',
          c.completedAt,
          code: c.code,
        ),
    ];
  }

  // --- Derived values ---------------------------------------------------------

  String _statusOf(Map<String, dynamic> m) {
    final p = _progress[m['id']];
    if (p == null) return 'available';
    return p.completed ? 'completed' : 'in_progress';
  }

  int get _completedCount =>
      _modules.where((m) => _statusOf(m) == 'completed').length;

  int get _inProgressCount =>
      _modules.where((m) => _statusOf(m) == 'in_progress').length;

  double get _progressPercent =>
      _modules.isEmpty ? 0 : _completedCount / _modules.length;

  /// Real time spent on the lessons shown here.
  int get _totalSeconds => _modules.fold(
    0,
    (sum, m) => sum + (_progress[m['id']]?.timeOnPageSec ?? 0),
  );

  String _fmtTime(int seconds) =>
      LearningSummary.formatTime(seconds, context.l10n);

  /// Completed lessons and finished quizzes, newest first.
  List<_Activity> get _activities {
    final titles = {
      for (final m in _modules) m['id'] as String: m['title'] as String,
    };
    final list = <_Activity>[];
    for (final p in _progress.values) {
      final title = titles[p.contentId];
      if (title == null) continue; // lesson no longer shown in the app
      if (p.completedAt != null) {
        list.add(_Activity(_ActivityKind.lesson, title, p.completedAt!));
      }
      if (p.quizCompletedAt != null) {
        list.add(_Activity(_ActivityKind.quiz, title, p.quizCompletedAt!));
      }
    }
    list.addAll(_surveyActivities);
    list.sort((a, b) => b.at.compareTo(a.at));
    return list;
  }

  Map<String, dynamic> _withProgress(Map<String, dynamic> m) {
    final p = _progress[m['id']];
    return {
      ...m,
      'status': _statusOf(m),
      'timeSpent': p == null || p.timeOnPageSec < 60
          ? ''
          : _fmtTime(p.timeOnPageSec),
      ..._iconFor(m['category'] as String? ?? ''),
    };
  }

  static Map<String, dynamic> _iconFor(String category) {
    // Keyed by the dashboard's category names (data, not app text).
    switch (category) {
      case 'Heart Health':
        return {
          'icon': Icons.favorite_rounded,
          'iconColor': const Color(0xFFDB2777),
          'iconBg': const Color(0xFFFCE7F3),
        };
      case 'Sleep Health':
        return {
          'icon': Icons.bedtime_rounded,
          'iconColor': const Color(0xFF7C3AED),
          'iconBg': const Color(0xFFEDE9FE),
        };
      case 'Emotional Support & Resources':
        return {
          'icon': Icons.psychology_rounded,
          'iconColor': const Color(0xFF0369A1),
          'iconBg': const Color(0xFFE0F2FE),
        };
      case 'Resources':
        return {
          'icon': Icons.medical_information_rounded,
          'iconColor': const Color(0xFFF59E0B),
          'iconBg': const Color(0xFFFEF3C7),
        };
      default:
        return {
          'icon': Icons.menu_book_rounded,
          'iconColor': const Color(0xFF15803D),
          'iconBg': const Color(0xFFDCFCE7),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppMenuButton(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.l10n.progressCardTitle,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.progressSubtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMedium,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_loading && _modules.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                            ),
                          ),
                        )
                      else if (_error != null)
                        _ErrorBox(message: _error!, onRetry: _load)
                      else ...[
                        // Overall progress card
                        _OverallProgressCard(
                          completedCount: _completedCount,
                          totalCount: _modules.length,
                          progressPercent: _progressPercent,
                          totalMinutes: (_totalSeconds / 60).round(),
                          inProgressCount: _inProgressCount,
                          onTap: _scrollToLessons,
                        ),
                        const SizedBox(height: 24),

                        // Stats row
                        _StatsRow(
                          completedCount: _completedCount,
                          timeSpent: _fmtTime(_totalSeconds),
                          inProgressCount: _inProgressCount,
                          onTap: _scrollToLessons,
                        ),
                        const SizedBox(height: 28),

                        // Activity calendar
                        Text(
                          context.l10n.progressCalendar,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _ActivityCalendar(
                          month: _month,
                          activities: _activities,
                          selectedDay: _selectedDay,
                          onMonthChanged: (m) => setState(() {
                            _month = m;
                            _selectedDay = null;
                          }),
                          onDaySelected: (d) => setState(() {
                            _selectedDay =
                                _selectedDay != null &&
                                    _sameDay(_selectedDay!, d)
                                ? null
                                : d;
                          }),
                        ),
                        const SizedBox(height: 16),
                        _ActivityList(
                          activities: _selectedDay == null
                              ? _activities.take(20).toList()
                              : _activities
                                    .where((a) => _sameDay(a.at, _selectedDay!))
                                    .toList(),
                          selectedDay: _selectedDay,
                          onClearDay: () => setState(() => _selectedDay = null),
                        ),
                        const SizedBox(height: 28),

                        // Module list header
                        Text(
                          context.l10n.progressBreakdown,
                          key: _lessonsKey,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_modules.isEmpty)
                          Text(
                            context.l10n.lessonNoLessonsShort,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMedium,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              // Module list
              if (_error == null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final module = _withProgress(_modules[index]);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ModuleProgressTile(
                          module: module,
                          index: index,
                          onTap: () => _openLesson(_modules[index]),
                        ),
                      );
                    }, childCount: _modules.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _fmtDateTime(AppLocalizations l10n, DateTime d) =>
    '${l10n.monthDayYear(d)} · ${l10n.time(d)}';

enum _ActivityKind { lesson, quiz, survey }

class _Activity {
  final _ActivityKind kind;

  /// Lesson or survey title ('' when the survey is no longer listed).
  final String title;
  final DateTime at;

  /// Survey code, shown when the survey's title is unknown.
  final String code;
  const _Activity(this.kind, this.title, this.at, {this.code = ''});

  String label(AppLocalizations l10n) => switch (kind) {
    _ActivityKind.lesson => l10n.activityCompleted(title),
    _ActivityKind.quiz => l10n.activityQuizFinished(title),
    _ActivityKind.survey => l10n.activityCompleted(
      title.isNotEmpty ? title : l10n.activitySurveyFallback(code),
    ),
  };

  Color get color => switch (kind) {
    _ActivityKind.lesson => AppTheme.primary,
    _ActivityKind.quiz => AppTheme.purple,
    _ActivityKind.survey => AppTheme.secondary,
  };
  Color get bg => switch (kind) {
    _ActivityKind.lesson => AppTheme.primaryContainer,
    _ActivityKind.quiz => AppTheme.purpleContainer,
    _ActivityKind.survey => AppTheme.secondaryContainer,
  };
  IconData get icon => switch (kind) {
    _ActivityKind.lesson => Icons.menu_book_rounded,
    _ActivityKind.quiz => Icons.sports_esports_rounded,
    _ActivityKind.survey => Icons.assignment_turned_in_rounded,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Error box
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 32,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppTheme.textMedium),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity Calendar
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityCalendar extends StatelessWidget {
  final DateTime month; // first day of the shown month
  final List<_Activity> activities;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;

  const _ActivityCalendar({
    required this.month,
    required this.activities,
    required this.selectedDay,
    required this.onMonthChanged,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Sun..Sat initials in the app's language (the grid starts on Sunday).
    final weekdays = MaterialLocalizations.of(context).narrowWeekdays;
    final today = DateTime.now();
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = DateTime(month.year, month.month, 1).weekday % 7; // Sun=0
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();
    final isCurrentMonth =
        month.year == today.year && month.month == today.month;

    // day -> kinds done that day
    final byDay = <int, Set<_ActivityKind>>{};
    for (final a in activities) {
      if (a.at.year == month.year && a.at.month == month.month) {
        byDay.putIfAbsent(a.at.day, () => <_ActivityKind>{}).add(a.kind);
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l10n.calPrevMonth,
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppTheme.textMedium,
                onPressed: () =>
                    onMonthChanged(DateTime(month.year, month.month - 1)),
              ),
              Expanded(
                child: Text(
                  l10n.monthYear(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.calNextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
                color: isCurrentMonth
                    ? AppTheme.borderColor
                    : AppTheme.textMedium,
                onPressed: isCurrentMonth
                    ? null
                    : () =>
                          onMonthChanged(DateTime(month.year, month.month + 1)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final d in weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var r = 0; r < rows; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _dayCell(
                      l10n,
                      r * 7 + c - leading + 1,
                      daysInMonth,
                      today,
                      byDay,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 4,
            children: [
              _LegendDot(color: AppTheme.primary, label: l10n.legendLesson),
              _LegendDot(color: AppTheme.purple, label: l10n.legendQuiz),
              _LegendDot(color: AppTheme.secondary, label: l10n.legendSurvey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayCell(
    AppLocalizations l10n,
    int day,
    int daysInMonth,
    DateTime today,
    Map<int, Set<_ActivityKind>> byDay,
  ) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 44);
    final date = DateTime(month.year, month.month, day);
    final kinds = byDay[day] ?? const <_ActivityKind>{};
    final isToday = _sameDay(date, today);
    final isSelected = selectedDay != null && _sameDay(date, selectedDay!);
    return Semantics(
      button: true,
      label: [
        l10n.monthDayLong(date),
        if (kinds.contains(_ActivityKind.lesson)) l10n.calLessonDone,
        if (kinds.contains(_ActivityKind.quiz)) l10n.calQuizDone,
        if (kinds.contains(_ActivityKind.survey)) l10n.calSurveyDone,
      ].join(', '),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onDaySelected(date),
        child: Container(
          height: 44,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary
                : isToday
                ? AppTheme.primaryContainer
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isToday || isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (kinds.contains(_ActivityKind.lesson))
                    _dot(isSelected ? Colors.white : AppTheme.primary),
                  if (kinds.contains(_ActivityKind.quiz))
                    _dot(isSelected ? Colors.white70 : AppTheme.purple),
                  if (kinds.contains(_ActivityKind.survey))
                    _dot(isSelected ? Colors.white : AppTheme.secondary),
                  if (kinds.isEmpty) const SizedBox(height: 6),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _dot(Color color) => Container(
    width: 6,
    height: 6,
    margin: const EdgeInsets.symmetric(horizontal: 1.5),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMedium),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity List
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityList extends StatelessWidget {
  final List<_Activity> activities;
  final DateTime? selectedDay;
  final VoidCallback onClearDay;

  const _ActivityList({
    required this.activities,
    required this.selectedDay,
    required this.onClearDay,
  });

  @override
  Widget build(BuildContext context) {
    final day = selectedDay;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                day == null
                    ? l10n.activityRecent
                    : l10n.activityOnDay(l10n.monthDay(day)),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            if (day != null)
              TextButton(
                onPressed: onClearDay,
                child: Text(l10n.activityShowAll),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (activities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Text(
              day == null ? l10n.activityEmpty : l10n.activityEmptyDay,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMedium),
            ),
          )
        else
          for (final a in activities)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: a.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(a.icon, size: 18, color: a.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.label(l10n),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _fmtDateTime(l10n, a.at),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppTheme.secondary,
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overall Progress Card
// ─────────────────────────────────────────────────────────────────────────────

class _OverallProgressCard extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final double progressPercent;
  final int totalMinutes;
  final int inProgressCount;
  final VoidCallback onTap;

  const _OverallProgressCard({
    required this.completedCount,
    required this.totalCount,
    required this.progressPercent,
    required this.totalMinutes,
    required this.inProgressCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.overallTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.overallCount(completedCount, totalCount),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${(progressPercent * 100).round()}%',
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            progressPercent >= 1.0
                ? l10n.overallAllDone
                : inProgressCount > 0
                ? l10n.overallKeepGoing
                : l10n.overallStart,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 10,
              backgroundColor: Colors.white.withAlpha(40),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int completedCount;
  final String timeSpent;
  final int inProgressCount;
  final VoidCallback onTap;

  const _StatsRow({
    required this.completedCount,
    required this.timeSpent,
    required this.inProgressCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            iconColor: AppTheme.secondary,
            iconBg: AppTheme.secondaryContainer,
            value: '$completedCount',
            label: context.l10n.statusCompleted,
            onTap: onTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.timer_rounded,
            iconColor: AppTheme.primary,
            iconBg: AppTheme.primaryContainer,
            value: timeSpent,
            label: context.l10n.statTimeSpent,
            onTap: onTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.play_circle_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFFFEF3C7),
            value: '$inProgressCount',
            label: context.l10n.statusInProgress,
            onTap: onTap,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: _buildCard(),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 8),
          // "2h 15m" must fit a third of the screen even with large text.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Module Progress Tile
// ─────────────────────────────────────────────────────────────────────────────

class _ModuleProgressTile extends StatelessWidget {
  final Map<String, dynamic> module;
  final int index;
  final VoidCallback onTap;

  const _ModuleProgressTile({
    required this.module,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = module['status'] as String;
    final isCompleted = status == 'completed';
    final isInProgress = status == 'in_progress';

    Color statusColor;
    Color statusBg;
    String statusLabel;
    IconData statusIcon;

    if (isCompleted) {
      statusColor = AppTheme.secondary;
      statusBg = AppTheme.secondaryContainer;
      statusLabel = context.l10n.statusCompleted;
      statusIcon = Icons.check_circle_rounded;
    } else if (isInProgress) {
      statusColor = AppTheme.primary;
      statusBg = AppTheme.primaryContainer;
      statusLabel = context.l10n.statusInProgress;
      statusIcon = Icons.play_circle_rounded;
    } else {
      statusColor = AppTheme.textLight;
      statusBg = AppTheme.surfaceVariantLight;
      statusLabel = context.l10n.statusNotStarted;
      statusIcon = Icons.radio_button_unchecked_rounded;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: _buildTile(
          context,
          isCompleted: isCompleted,
          isInProgress: isInProgress,
          statusColor: statusColor,
          statusBg: statusBg,
          statusLabel: statusLabel,
          statusIcon: statusIcon,
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required bool isCompleted,
    required bool isInProgress,
    required Color statusColor,
    required Color statusBg,
    required String statusLabel,
    required IconData statusIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? AppTheme.secondaryContainer
              : isInProgress
              ? AppTheme.primaryContainer
              : AppTheme.borderColor,
          width: isCompleted || isInProgress ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Module number badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: module['iconBg'] as Color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                module['icon'] as IconData,
                size: 18,
                color: module['iconColor'] as Color,
              ),
            ),
            const SizedBox(width: 12),

            // Title + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module['title'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      for (final part in [
                        if (module['durationMinutes'] is int)
                          context.l10n.minutesShort(
                            module['durationMinutes'] as int,
                          ),
                        if ((module['timeSpent'] as String? ?? '').isNotEmpty)
                          context.l10n.timeSpentSuffix(
                            module['timeSpent'] as String,
                          ),
                      ]) ...[
                        Text(
                          part,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppTheme.textLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          module['category'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Shows the row opens the lesson (mirrors in RTL languages).
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
