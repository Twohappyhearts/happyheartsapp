import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './chat_service.dart' show newMessageId;
import './supabase_service.dart';

/// Event names accepted by public.tracking_events (see the CHECK constraint in
/// supabase/migrations/20261021000100_tracking_analytics.sql).
class TrackingEvents {
  TrackingEvents._();
  static const sessionOpened = 'session_opened';
  static const sessionClosed = 'session_closed'; // value = seconds
  static const videoPlay = 'video_play';
  static const videoWatch = 'video_watch'; // value = seconds
  static const audioPlay = 'audio_play';
  static const audioListen = 'audio_listen'; // value = seconds
  static const infographicOpened = 'infographic_opened'; // value = seconds
  static const scriptRead = 'script_read'; // value = seconds
  static const quizStarted = 'quiz_started';
  static const quizCompleted = 'quiz_completed'; // value = 1
  static const sessionCompleted = 'session_completed';
}

enum _SendResult { sent, retryLater, accountRejected }

class PendingEvent {
  final String contentId;
  final DateTime at;
  final num? value;
  const PendingEvent({required this.contentId, required this.at, this.value});
}

/// Outbox for engagement events.
///
/// `track()` only appends to a local queue (memory + shared_preferences), so the
/// UI never waits for the network and nothing is lost offline or if the app is
/// killed. `flush()` sends queued events in batches of up to 100 rows:
///   * every 15 seconds,
///   * when the app goes to the background / comes back,
///   * when a lesson visit ends, and when the signed-in account changes.
///
/// Every event gets a client-generated UUID and is sent with
/// `upsert(onConflict: 'id', ignoreDuplicates: true)`, so a retry after a lost
/// response can never create duplicates. Events are removed from the queue only
/// after the server accepted them. Each event remembers which account produced
/// it (`owner`, never sent) and is only sent while that account is signed in —
/// the server sets user_id from the JWT, so this keeps accounts separate.
class TrackingService with WidgetsBindingObserver {
  TrackingService._();
  static final TrackingService instance = TrackingService._();

  static const String _prefsKey = 'hh_tracking_outbox_v1';
  static const int maxQueued = 1000;
  static const int _batchSize = 100;
  static const Duration flushInterval = Duration(seconds: 15);

  /// Longest single timed segment we accept (4 hours).
  static const int maxSegmentSeconds = 4 * 60 * 60;

  final List<Map<String, dynamic>> _queue = [];
  final Set<String> _rejectedAccounts = {};
  SharedPreferences? _prefs;
  Timer? _timer;
  bool _started = false;
  bool _flushing = false;
  bool _flushAgain = false;

  int get pendingCount => _queue.length;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    AuthService.instance.addListener(_onAuthChanged);
    _timer = Timer.periodic(flushInterval, (_) => flush());
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      final restored = <Map<String, dynamic>>[];
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map && e['id'] is String && e['owner'] is String) {
              restored.add(Map<String, dynamic>.from(e));
            }
          }
        }
      }
      // Events tracked while we were still loading go after the restored ones.
      _queue.insertAll(0, restored);
      _trim();
      _prefs = prefs;
      _save();
    } catch (_) {
      // Storage unavailable: keep working in memory only.
    }
    unawaited(flush());
  }

  /// Queue one event. Returns immediately; never throws.
  void track(
    String eventType, {
    required String contentId,
    required String visitId,
    num? value,
    Map<String, dynamic>? metadata,
    String? ownerId,
    DateTime? at,
  }) {
    final owner = ownerId ?? AuthService.instance.userId;
    if (owner == null || _rejectedAccounts.contains(owner)) return;
    num? v = value;
    if (v != null) {
      if (v.isNaN || v < 0) v = 0;
      if (v > maxSegmentSeconds) v = maxSegmentSeconds;
      v = (v * 10).round() / 10; // one decimal is plenty
    }
    _queue.add({
      'id': newMessageId(),
      'owner': owner,
      'content_id': contentId,
      'visit_id': visitId,
      'event_type': eventType,
      'value': v,
      'metadata': metadata ?? const <String, dynamic>{},
      'occurred_at': (at ?? DateTime.now()).toUtc().toIso8601String(),
    });
    _trim();
    _save();
  }

  /// True while an event of this type for this lesson is still waiting to be
  /// sent for the signed-in account (used so "Completed" shows instantly).
  bool hasPending(String contentId, String eventType) {
    final uid = AuthService.instance.userId;
    if (uid == null) return false;
    return _queue.any(
      (e) =>
          e['owner'] == uid &&
          e['content_id'] == contentId &&
          e['event_type'] == eventType,
    );
  }

  /// Events of [eventType] still waiting to be sent for the signed-in account
  /// (so screens can show progress made offline / in the last few seconds).
  List<PendingEvent> pendingEvents(String eventType) {
    final uid = AuthService.instance.userId;
    if (uid == null) return const [];
    return _queue
        .where((e) => e['owner'] == uid && e['event_type'] == eventType)
        .map(
          (e) => PendingEvent(
            contentId: e['content_id'] as String,
            at:
                DateTime.tryParse(e['occurred_at'] as String? ?? '')
                    ?.toLocal() ??
                DateTime.now(),
            value: e['value'] as num?,
          ),
        )
        .toList();
  }

  /// Send everything queued for the signed-in account. Safe to call any time.
  Future<void> flush() async {
    if (_flushing) {
      _flushAgain = true;
      return;
    }
    if (!SupabaseService.isConfigured) return;
    final uid = AuthService.instance.userId;
    if (uid == null) return;
    _flushing = true;
    try {
      do {
        _flushAgain = false;
        await _drain(uid);
      } while (_flushAgain && AuthService.instance.userId == uid);
    } finally {
      _flushing = false;
    }
  }

  Future<void> _drain(String uid) async {
    while (AuthService.instance.userId == uid) {
      final batch = _queue
          .where((e) => e['owner'] == uid)
          .take(_batchSize)
          .toList();
      if (batch.isEmpty) return;
      final result = await _send(batch);
      if (result == _SendResult.retryLater) return; // keep for next time
      if (result == _SendResult.accountRejected) {
        // Not a patient account (e.g. staff testing the app): the server will
        // never record these, so stop collecting for this account.
        _rejectedAccounts.add(uid);
        _queue.removeWhere((e) => e['owner'] == uid);
        _save();
        return;
      }
      final ids = batch.map((e) => e['id']).toSet();
      _queue.removeWhere((e) => ids.contains(e['id']));
      _save();
    }
  }

  Future<_SendResult> _send(List<Map<String, dynamic>> batch) async {
    try {
      await Supabase.instance.client
          .from('tracking_events')
          .upsert(
            batch.map(_toRow).toList(),
            onConflict: 'id',
            ignoreDuplicates: true,
          );
      return _SendResult.sent;
    } on PostgrestException catch (e) {
      final code = e.code ?? '';
      if (code == '42501') return _SendResult.accountRejected;
      if (code.startsWith('22') || code.startsWith('23')) {
        // Invalid data (e.g. the lesson was deleted). Send rows one by one so a
        // single bad row is dropped without losing the valid ones.
        if (batch.length == 1) return _SendResult.sent; // drop it
        for (final row in batch) {
          final r = await _send([row]);
          if (r != _SendResult.sent) return r;
        }
        return _SendResult.sent;
      }
      return _SendResult.retryLater; // auth refresh, server hiccup, ...
    } catch (_) {
      return _SendResult.retryLater; // offline / timeout
    }
  }

  static Map<String, dynamic> _toRow(Map<String, dynamic> e) => {
    'id': e['id'],
    'content_id': e['content_id'],
    'visit_id': e['visit_id'],
    'event_type': e['event_type'],
    'value': e['value'],
    'metadata': e['metadata'] ?? const <String, dynamic>{},
    'occurred_at': e['occurred_at'],
  };

  void _trim() {
    if (_queue.length > maxQueued) {
      _queue.removeRange(0, _queue.length - maxQueued); // drop the oldest
    }
  }

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      unawaited(prefs.setString(_prefsKey, jsonEncode(_queue)));
    } catch (_) {}
  }

  void _onAuthChanged() {
    // A different account may have events waiting from an earlier session.
    if (AuthService.instance.isSignedIn) unawaited(flush());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.resumed) {
      unawaited(flush());
    }
  }

  /// Stops timers and observers (tests only; the service lives for the app).
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    AuthService.instance.removeListener(_onAuthChanged);
  }
}
