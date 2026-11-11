import 'package:flutter/material.dart';

import '../../services/app_language.dart';
import '../../services/current_profile.dart';
import '../../services/survey_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_menu.dart';
import './assessment_webview_screen.dart';

/// The active REDCap links managed on the dashboard (Survey Management),
/// listed by placement:
///  - [SurveyPlacement.resource]: the Resources tab (bottom navigation)
///  - [SurveyPlacement.survey]: Survey, opened from the side menu
/// Each opens in a web view with the patient's username as REDCap's
/// participant_code.
class AssessmentsScreen extends StatefulWidget {
  final SurveyPlacement placement;

  /// Opened as its own page (from the side menu): back button instead of ☰.
  final bool standalone;

  const AssessmentsScreen({
    super.key,
    this.placement = SurveyPlacement.resource,
    this.standalone = false,
  });

  @override
  State<AssessmentsScreen> createState() => _AssessmentsScreenState();
}

class _AssessmentsScreenState extends State<AssessmentsScreen> {
  static const _sectionOrder = [
    'Emotional Assessment',
    'Basic Needs Assessment',
  ];

  /// Group key for links without a section (no heading is shown for it).
  static const _noSection = '';

  List<SurveyLink> _surveys = const [];
  Map<String, DateTime> _lastCompleted = const {};
  bool _loading = true;
  String? _error;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final surveys = await SurveyService.instance.loadSurveys(
        placement: widget.placement,
      );
      final completions = await SurveyService.instance.myCompletions();
      final last = <String, DateTime>{};
      for (final c in completions) {
        final id = c.surveyId;
        if (id != null && !last.containsKey(id)) last[id] = c.completedAt;
      }
      if (!mounted) return;
      setState(() {
        _surveys = surveys;
        _lastCompleted = last;
        _loading = false;
        _error = null;
      });
    } on SurveyException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _openAssessment(SurveyLink survey) async {
    if (_opening) return;
    _opening = true;
    try {
      final profile = CurrentProfile.instance;
      if (profile.profile == null) await profile.load(force: true);
      final username = profile.profile?.username;
      if (!mounted) return;
      if (username == null || username.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.assessUsernameError),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AssessmentWebViewScreen(
            title: survey.title,
            url: survey.personalizedUrl(username),
          ),
        ),
      );
      if (completed == true && mounted) _load();
    } finally {
      _opening = false;
    }
  }

  /// Sections in a fixed order: the two from the app design, then any other
  /// section staff typed, then surveys without a section.
  List<MapEntry<String, List<SurveyLink>>> get _sections {
    final groups = <String, List<SurveyLink>>{};
    for (final s in _surveys) {
      groups.putIfAbsent(s.category ?? _noSection, () => []).add(s);
    }
    final keys = groups.keys.toList()
      ..sort((a, b) {
        int rank(String k) {
          final i = _sectionOrder.indexOf(k);
          if (i >= 0) return i;
          return k == _noSection ? 1000 : 100;
        }

        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.compareTo(b);
      });
    return [for (final k in keys) MapEntry(k, groups[k]!)];
  }

  static ({IconData icon, Color color, Color bg}) _sectionStyle(String name) {
    switch (name) {
      case 'Emotional Assessment':
        return (
          icon: Icons.psychology_rounded,
          color: const Color(0xFF7C3AED),
          bg: const Color(0xFFEDE9FE),
        );
      case 'Basic Needs Assessment':
        return (
          icon: Icons.assignment_rounded,
          color: const Color(0xFF0369A1),
          bg: const Color(0xFFE0F2FE),
        );
      default:
        return (
          icon: Icons.fact_check_rounded,
          color: const Color(0xFF475569),
          bg: const Color(0xFFF1F5F9),
        );
    }
  }

  static ({IconData icon, Color color, Color bg}) _cardStyle(SurveyLink s) {
    final key = '${s.code} ${s.title}'.toUpperCase();
    if (key.contains('FOOD')) {
      return (
        icon: Icons.restaurant_rounded,
        color: const Color(0xFF15803D),
        bg: const Color(0xFFDCFCE7),
      );
    }
    if (key.contains('EMA') || key.contains('MOOD')) {
      return (
        icon: Icons.monitor_heart_rounded,
        color: const Color(0xFF7C3AED),
        bg: const Color(0xFFEDE9FE),
      );
    }
    if (key.contains('MENTAL') || key.contains('WELL')) {
      return (
        icon: Icons.favorite_rounded,
        color: const Color(0xFFDB2777),
        bg: const Color(0xFFFCE7F3),
      );
    }
    if (key.contains('FOLLOW')) {
      return (
        icon: Icons.event_repeat_rounded,
        color: const Color(0xFFD97706),
        bg: const Color(0xFFFEF3C7),
      );
    }
    return (
      icon: Icons.assignment_rounded,
      color: const Color(0xFF0369A1),
      bg: const Color(0xFFE0F2FE),
    );
  }

  static ({Color color, Color bg}) _frequencyStyle(String f) {
    switch (f.toLowerCase()) {
      case 'daily':
        return (color: const Color(0xFF15803D), bg: const Color(0xFFDCFCE7));
      case 'weekly':
      case 'monthly':
        return (color: const Color(0xFF7C3AED), bg: const Color(0xFFEDE9FE));
      case 'one time':
        return (color: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7));
      default:
        return (color: const Color(0xFF0369A1), bg: const Color(0xFFE0F2FE));
    }
  }

  bool get _isSurvey => widget.placement == SurveyPlacement.survey;

  String get _title =>
      _isSurvey ? context.l10n.menuAssessments : context.l10n.navResources;

  String get _subtitle => _isSurvey
      ? context.l10n.assessSubtitleSurvey
      : context.l10n.assessSubtitleResources;

  String get _emptyMessage => _isSurvey
      ? context.l10n.assessEmptySurvey
      : context.l10n.assessEmptyResources;

  List<Widget> _buildContent() {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        ),
      ];
    }
    if (_error != null) {
      return [
        _MessageBox(
          icon: Icons.cloud_off_rounded,
          message: _error!,
          actionLabel: context.l10n.retry,
          onAction: () {
            setState(() => _loading = true);
            _load();
          },
        ),
      ];
    }
    if (_surveys.isEmpty) {
      return [
        _MessageBox(
          icon: _isSurvey
              ? Icons.assignment_outlined
              : Icons.library_books_outlined,
          message: _emptyMessage,
        ),
      ];
    }
    final widgets = <Widget>[];
    for (final section in _sections) {
      // Links without a section are listed without a heading.
      if (section.key != _noSection) {
        final st = _sectionStyle(section.key);
        widgets.add(
          _SectionHeader(
            icon: st.icon,
            iconColor: st.color,
            iconBg: st.bg,
            title: section.key,
          ),
        );
        widgets.add(const SizedBox(height: 12));
      }
      for (final survey in section.value) {
        final cs = _cardStyle(survey);
        final fs = _frequencyStyle(survey.frequency ?? '');
        final done = _lastCompleted[survey.id];
        widgets.add(
          _AssessmentCard(
            icon: cs.icon,
            iconColor: cs.color,
            iconBg: cs.bg,
            title: survey.title,
            description: survey.description,
            frequency: survey.frequency,
            frequencyColor: fs.color,
            frequencyBg: fs.bg,
            duration: survey.duration,
            completedLabel: done == null
                ? null
                : context.l10n.assessLastCompleted(context.l10n.monthDay(done)),
            buttonLabel: context.l10n.assessStart,
            onTap: () => _openAssessment(survey),
          ),
        );
        widgets.add(const SizedBox(height: 12));
      }
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
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
                          if (widget.standalone)
                            const _BackButton()
                          else
                            const AppMenuButton(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _title,
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
                        _subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMedium,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(_buildContent()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.back,
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariantLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppTheme.textDark,
          ),
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageBox({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppTheme.textLight),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppTheme.textMedium),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Assessment Card
// ─────────────────────────────────────────────────────────────────────────────

class _AssessmentCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;
  final String? frequency;
  final Color frequencyColor;
  final Color frequencyBg;
  final String? duration;
  final String? completedLabel;
  final String buttonLabel;
  final VoidCallback onTap;

  const _AssessmentCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.frequency,
    required this.frequencyColor,
    required this.frequencyBg,
    required this.duration,
    this.completedLabel,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMedium,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Badges (wrap onto a second line with large text)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Frequency badge
                        if (frequency != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: frequencyBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              frequency!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: frequencyColor,
                              ),
                            ),
                          ),
                        ],
                        // Duration badge
                        if (duration != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: AppTheme.textLight,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                duration!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMedium,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (completedLabel != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Color(0xFF15803D),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              completedLabel!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    // Start button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: Text(buttonLabel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
