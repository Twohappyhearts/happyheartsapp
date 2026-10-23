import 'dart:async';

import 'package:flutter/widgets.dart';

import './auth_service.dart';
import './chat_service.dart' show newMessageId;
import './tracking_service.dart';

/// Accumulates "running" time. Paused time is never counted.
class _Span {
  DateTime? _since;
  double _acc = 0;

  bool get running => _since != null;

  void run(bool on, DateTime now) {
    if (on && _since == null) {
      _since = now;
    } else if (!on && _since != null) {
      final secs = now.difference(_since!).inMilliseconds / 1000;
      if (secs > 0) _acc += secs;
      _since = null;
    }
  }

  /// Seconds collected so far, if at least [min]; resets the counter.
  /// Sub-second leftovers are kept and added to the next segment.
  double? take({double min = 1}) {
    if (_acc < min) return null;
    final v = _acc;
    _acc = 0;
    return v;
  }
}

class _RecentVisit {
  final String visitId;
  final DateTime lastActive;
  const _RecentVisit(this.visitId, this.lastActive);
}

/// Measures one stay ("visit") on a lesson page and reports it through
/// [TrackingService].
///
/// Rules (same as agreed for the dashboard Analytics):
///  * A visit starts with `session_opened`. Leaving and coming back to the same
///    lesson within 30 minutes continues the same visit.
///  * Time is only counted while the page is actually in front of the patient:
///    app in the foreground, this lesson is the current route/tab, and the
///    patient interacted in the last 10 minutes (playing media counts).
///  * Each foreground stretch is sent as `session_closed` (value = seconds);
///    the visit's time on page is their sum.
///  * Media time counts only while playing; lesson notes only while at least
///    half of them are on screen; infographic only while full-screen.
class LessonVisitTracker with WidgetsBindingObserver {
  LessonVisitTracker({required this.contentId});

  final String contentId;

  static const Duration resumeWindow = Duration(minutes: 30);
  static const Duration idleTimeout = Duration(minutes: 10);
  static final Map<String, _RecentVisit> _recent = {};

  late String _visitId;
  String? _ownerId;
  bool _started = false;
  bool _disposed = false;

  bool _appForeground = true;
  bool _routeActive = false;
  bool _idle = false;
  DateTime _lastInteraction = DateTime.now();
  DateTime? _inactiveSince;
  Timer? _idleTimer;

  bool _scriptVisible = false;
  bool _infographicOpen = false;
  bool _videoPlaying = false;
  bool _audioPlaying = false;
  bool _completedSent = false;
  bool _quizCompletedSent = false;

  final _page = _Span();
  final _script = _Span();
  final _infographic = _Span();
  final _video = _Span();
  final _audio = _Span();

  String get visitId => _visitId;
  // The full-screen infographic viewer sits on top of the lesson page; while
  // it is open the patient is still in this lesson.
  bool get _active =>
      _started &&
      !_disposed &&
      _appForeground &&
      (_routeActive || _infographicOpen);
  bool get _mediaPlaying => _videoPlaying || _audioPlaying;
  String get _recentKey => '${_ownerId ?? '-'}|$contentId';

  // ---------------------------------------------------------------------------
  // Lifecycle

  void start({bool routeActive = true}) {
    if (_started || _disposed) return;
    _ownerId = AuthService.instance.userId;
    final now = DateTime.now();
    final prev = _recent[_recentKey];
    if (prev != null && now.difference(prev.lastActive) <= resumeWindow) {
      _visitId = prev.visitId; // came back quickly: same visit
    } else {
      _visitId = newMessageId();
      _emit(TrackingEvents.sessionOpened);
    }
    _started = true;
    _routeActive = routeActive;
    final life = WidgetsBinding.instance.lifecycleState;
    _appForeground = life == null || life == AppLifecycleState.resumed;
    _lastInteraction = now;
    WidgetsBinding.instance.addObserver(this);
    _idleTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkIdle());
    _sync();
  }

  /// The visit ends: send everything still being measured.
  void dispose() {
    if (_disposed) return;
    if (_started) {
      final now = DateTime.now();
      _stopAll(now, emitInfographic: true);
      _recent[_recentKey] = _RecentVisit(_visitId, now);
      WidgetsBinding.instance.removeObserver(this);
      unawaited(TrackingService.instance.flush());
    }
    _idleTimer?.cancel();
    _disposed = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appForeground = true;
      _lastInteraction = DateTime.now();
      _idle = false;
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _appForeground = false;
    } else {
      return; // `inactive` (control centre, incoming call banner): ignore
    }
    _sync();
  }

  // ---------------------------------------------------------------------------
  // Signals from the lesson page

  /// Any touch / scroll on the page.
  void touch() {
    if (_disposed) return;
    _lastInteraction = DateTime.now();
    if (_idle) {
      _idle = false;
      _sync();
    }
  }

  /// Whether this lesson is the screen currently shown (tab + top route).
  void setRouteActive(bool active) {
    if (_routeActive == active) return;
    _routeActive = active;
    if (active) {
      _lastInteraction = DateTime.now();
      _idle = false;
    }
    _sync();
  }

  void setScriptVisible(bool visible) {
    if (_scriptVisible == visible) return;
    _scriptVisible = visible;
    _sync();
  }

  void setInfographicOpen(bool open) {
    if (_infographicOpen == open) return;
    _lastInteraction = DateTime.now();
    _idle = false;
    _infographicOpen = open;
    _sync();
    if (!open) _emitSpan(_infographic, TrackingEvents.infographicOpened);
  }

  /// YouTube player state: play | playing | buffer | pause | ended.
  void onVideoState(String state) {
    if (_disposed || !_started) return;
    _lastInteraction = DateTime.now();
    _idle = false;
    if (state == 'play') _emit(TrackingEvents.videoPlay);
    _videoPlaying = state == 'play' || state == 'playing';
    _sync();
  }

  /// SoundCloud widget state: play | pause | ended.
  void onAudioState(String state) {
    if (_disposed || !_started) return;
    _lastInteraction = DateTime.now();
    _idle = false;
    if (state == 'play' && !_audioPlaying) _emit(TrackingEvents.audioPlay);
    _audioPlaying = state == 'play' || state == 'playing';
    _sync();
  }

  void quizStarted() {
    touch();
    _emit(TrackingEvents.quizStarted);
  }

  void quizCompleted() {
    touch();
    if (_quizCompletedSent) return;
    _quizCompletedSent = true;
    _emit(TrackingEvents.quizCompleted, value: 1);
    unawaited(TrackingService.instance.flush());
  }

  void sessionCompleted() {
    touch();
    if (_completedSent) return;
    _completedSent = true;
    _emit(TrackingEvents.sessionCompleted);
    unawaited(TrackingService.instance.flush());
  }

  // ---------------------------------------------------------------------------
  // Internals

  void _checkIdle() {
    if (!_active || _idle || _mediaPlaying) return;
    final now = DateTime.now();
    if (now.difference(_lastInteraction) >= idleTimeout) {
      _idle = true;
      // Count up to the last interaction only, not the idle minutes.
      final cutoff = _lastInteraction;
      _page.run(false, cutoff.isAfter(now) ? now : cutoff);
      _script.run(false, cutoff.isAfter(now) ? now : cutoff);
      _infographic.run(false, cutoff.isAfter(now) ? now : cutoff);
      _sync();
    }
  }

  /// Start / stop every span according to the current state.
  void _sync() {
    if (!_started || _disposed) return;
    final now = DateTime.now();
    final active = _active;

    if (!active) {
      _inactiveSince ??= now;
    } else if (_inactiveSince != null) {
      final away = now.difference(_inactiveSince!);
      _inactiveSince = null;
      if (away > resumeWindow) _startNewVisit(now);
    }

    final attentive = active && !_idle;
    final pageWasRunning = _page.running;

    _page.run(attentive, now);
    // The full-screen infographic covers the notes, so they don't count then.
    _script.run(attentive && _scriptVisible && !_infographicOpen, now);
    _infographic.run(attentive && _infographicOpen, now);
    _video.run(active && _videoPlaying, now);
    _audio.run(active && _audioPlaying, now);

    // Segments end -> queue them (infographic is sent when it is closed).
    if (!_page.running) _emitSpan(_page, TrackingEvents.sessionClosed);
    if (!_script.running) _emitSpan(_script, TrackingEvents.scriptRead);
    if (!_video.running) _emitSpan(_video, TrackingEvents.videoWatch);
    if (!_audio.running) _emitSpan(_audio, TrackingEvents.audioListen);

    if (pageWasRunning && !_page.running) {
      _recent[_recentKey] = _RecentVisit(_visitId, now);
      unawaited(TrackingService.instance.flush());
    }
  }

  /// Away for more than 30 minutes with the page still open: new visit.
  void _startNewVisit(DateTime now) {
    _stopAll(now, emitInfographic: true);
    _visitId = newMessageId();
    _completedSent = false;
    _quizCompletedSent = false;
    _emit(TrackingEvents.sessionOpened);
  }

  void _stopAll(DateTime now, {required bool emitInfographic}) {
    for (final s in [_page, _script, _infographic, _video, _audio]) {
      s.run(false, now);
    }
    _emitSpan(_page, TrackingEvents.sessionClosed);
    _emitSpan(_script, TrackingEvents.scriptRead);
    _emitSpan(_video, TrackingEvents.videoWatch);
    _emitSpan(_audio, TrackingEvents.audioListen);
    if (emitInfographic) {
      _emitSpan(_infographic, TrackingEvents.infographicOpened);
    }
  }

  void _emitSpan(_Span span, String eventType) {
    final secs = span.take();
    if (secs != null) _emit(eventType, value: secs);
  }

  void _emit(String eventType, {num? value}) {
    TrackingService.instance.track(
      eventType,
      contentId: contentId,
      visitId: _visitId,
      value: value,
      ownerId: _ownerId,
    );
  }
}
