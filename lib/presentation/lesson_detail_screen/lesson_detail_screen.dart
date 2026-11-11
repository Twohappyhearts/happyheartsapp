import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../routes/app_routes.dart';
import '../../services/app_language.dart';
import '../../services/current_profile.dart';
import '../../services/lesson_visit_tracker.dart';
import '../../theme/app_theme.dart';
import './widgets/audio_section_widget.dart';
import './widgets/infographic_section_widget.dart';
import './widgets/kahoot_section_widget.dart';
import '../../services/content_service.dart';
import './widgets/lesson_detail_app_bar_widget.dart';
import './widgets/references_section_widget.dart';
import './widgets/script_section_widget.dart';
import './widgets/video_section_widget.dart';

class LessonDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? moduleData;

  const LessonDetailScreen({this.moduleData, super.key});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  // TODO: Replace with [Riverpod/Bloc] for production state management
  bool _isBookmarked = false;

  /// The lesson to show. Comes from the Education list; if the page is opened
  /// without one (e.g. a restored link), the first active session is loaded.
  Map<String, dynamic>? _module;
  bool _loadingFallback = false;
  String? _loadError;
  final CurrentProfile _currentProfile = CurrentProfile.instance;

  /// Measures this visit (time on page, media, notes, quiz, completion).
  LessonVisitTracker? _tracker;
  bool _completed = false;

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadFirstSession() async {
    setState(() {
      _loadingFallback = true;
      _loadError = null;
    });
    try {
      final first = await ContentService.instance.firstSession();
      if (!mounted) return;
      setState(() {
        _module = first;
        _loadingFallback = false;
        if (first == null) _loadError = context.l10n.lessonNoLessonsShort;
      });
      _startTracking();
    } on ContentException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingFallback = false;
        _loadError = e.message;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _module = widget.moduleData;
    if (_module == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadFirstSession());
    } else {
      _startTracking();
    }
    _currentProfile.addListener(_onProfileChanged);
    _currentProfile.load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // TickerMode.valuesOf and ModalRoute.of register dependencies, so this runs
    // again when the patient switches bottom tabs or a route is pushed on top.
    _updateRouteActive();
  }

  @override
  void dispose() {
    _currentProfile.removeListener(_onProfileChanged);
    _tracker?.dispose(); // ends the visit and sends what was measured
    super.dispose();
  }

  // --- Analytics -------------------------------------------------------------

  void _startTracking() {
    final module = _module;
    final id = module?['id'];
    if (module == null || id is! String || _tracker != null) return;
    _completed = module['status'] == 'completed';
    final tracker = LessonVisitTracker(contentId: id);
    _tracker = tracker;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tracker != tracker) return;
      tracker.start(routeActive: _isShownToUser());
    });
  }

  /// True when this lesson is what the patient is looking at.
  ///
  /// * Bottom tabs are an IndexedStack (StatefulShellRoute): hidden tabs stay
  ///   mounted but go_router wraps them in TickerMode(enabled: false).
  /// * ModalRoute.isCurrent is false while another page is pushed on top.
  ///
  /// (The router location can't be used: after `context.push` it still
  /// reports the page the lesson was pushed from.)
  bool _isShownToUser() {
    if (!mounted) return false;
    final tabVisible = TickerMode.valuesOf(context).enabled;
    final isTopRoute = ModalRoute.of(context)?.isCurrent ?? true;
    return tabVisible && isTopRoute;
  }

  void _updateRouteActive() {
    if (!mounted) return;
    _tracker?.setRouteActive(_isShownToUser());
  }

  void _markCompleted() {
    if (_completed) return;
    setState(() => _completed = true);
    _module?['status'] = 'completed';
    _tracker?.sessionCompleted();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.lessonMarked),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.textDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final module = _module;
    if (module == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: SafeArea(
          child: Center(
            child: _loadingFallback
                ? const CircularProgressIndicator(color: AppTheme.primary)
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 40,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _loadError ?? context.l10n.lessonNoneSelected,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadFirstSession,
                          child: Text(context.l10n.retry),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      );
    }
    final infographicUrl = module['infographicUrl'] as String?;
    final videoId = module['videoId'] as String?;
    final kahootUrl = module['kahootUrl'] as String?;
    final scriptHtml = module['scriptHtml'] as String?;
    final audioUrl = module['audioUrl'] as String?;
    final references = <Map<String, String>>[
      for (final r in (module['references'] as List? ?? const []))
        if (r is Map)
          {
            'title': '${r['title'] ?? ''}',
            'url': '${r['url'] ?? ''}',
            'kind': '${r['kind'] ?? 'link'}',
          },
    ];
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      // Any touch or scroll counts as activity (pauses the 10-min idle timer).
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _tracker?.touch(),
        onPointerSignal: (_) => _tracker?.touch(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (_) {
            _tracker?.touch();
            return false;
          },
          child: SafeArea(
            child: Column(
              children: [
                LessonDetailAppBarWidget(
                  isBookmarked: _isBookmarked,
                  // Normally pushed from Education; if not (e.g. restored link), go there.
                  onBack: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.educationHub),
                  onBookmark: () =>
                      setState(() => _isBookmarked = !_isBookmarked),
                  onShare: () {},
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Module title + category
                        _buildModuleHeader(module),
                        const SizedBox(height: 24),

                        // Section 1: Infographic (optional)
                        if (infographicUrl != null) ...[
                          InfographicSectionWidget(
                            infographicUrl: infographicUrl,
                            moduleTitle: module['title'] as String,
                            onFullscreenChanged: (open) =>
                                _tracker?.setInfographicOpen(open),
                            onInteraction: () => _tracker?.touch(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Section 2: Video (optional)
                        if (videoId != null) ...[
                          VideoSectionWidget(
                            videoId: videoId,
                            duration:
                                (module['videoDuration'] as String?) ?? '',
                            onPlayerState: (state) =>
                                _tracker?.onVideoState(state),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Section 2b: Audio (optional, SoundCloud)
                        if (audioUrl != null) ...[
                          AudioSectionWidget(
                            audioUrl: audioUrl,
                            duration:
                                (module['audioDuration'] as String?) ?? '',
                            onPlayerState: (state) =>
                                _tracker?.onAudioState(state),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Section 3: Lesson notes / script (optional)
                        if (scriptHtml != null) ...[
                          // Reading time counts while at least half of the notes
                          // (or 40% of the screen) show lesson notes.
                          VisibilityDetector(
                            key: Key('lesson-notes-${module['id']}'),
                            onVisibilityChanged: (info) {
                              if (!mounted) return;
                              final visible =
                                  info.visibleFraction >= 0.5 ||
                                  info.visibleBounds.height >=
                                      screenHeight * 0.4;
                              _tracker?.setScriptVisible(visible);
                            },
                            child: ScriptSectionWidget(scriptHtml: scriptHtml),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Section 4: Quiz (optional)
                        if (kahootUrl != null) ...[
                          KahootSectionWidget(
                            kahootUrl: kahootUrl,
                            username:
                                _currentProfile.profile?.username ?? '...',
                            quizCompleted: module['quizCompleted'] == true,
                            onQuizStarted: () => _tracker?.quizStarted(),
                            onQuizCompleted: () => _tracker?.quizCompleted(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Section 5: References (the lesson's links + staff-added)
                        if (references.isNotEmpty) ...[
                          ReferencesSectionWidget(references: references),
                          const SizedBox(height: 24),
                        ],

                        // Finish: the lesson counts as completed once tapped.
                        _buildCompleteCard(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _completed
                ? context.l10n.lessonCompletedTitle
                : context.l10n.lessonFinishPrompt,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _completed
                ? context.l10n.lessonCompletedBody
                : context.l10n.lessonFinishBody,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textMedium,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _completed ? null : _markCompleted,
              icon: Icon(
                _completed
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                size: 20,
              ),
              label: Text(
                _completed
                    ? context.l10n.statusCompleted
                    : context.l10n.lessonMarkButton,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.secondaryContainer,
                disabledForegroundColor: const Color(0xFF15803D),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleHeader(Map<String, dynamic> module) {
    final category = module['category'] as String;
    final minutes = module['durationMinutes'] as int?;
    final duration = minutes == null ? '' : context.l10n.minutesShort(minutes);
    final sections = [
      module['infographicUrl'],
      module['videoId'],
      module['audioUrl'],
      module['scriptHtml'],
      module['kahootUrl'],
    ].where((v) => v != null).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryDark,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          module['title'] as String,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          module['description'] as String,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textMedium,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (duration.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: AppTheme.textMedium,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.layers_rounded,
                    size: 13,
                    color: AppTheme.purple,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.l10n.lessonSections(sections),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.purple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
