import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

/// One broadcast message in the patient's inbox (dashboard: Users > Broadcast
/// Message). Rows come from the inbox_* database functions
/// (migration 20261123000100_broadcast_inbox.sql). Read state is one cursor per
/// person: messages sent after it are unread.
class InboxItem {
  final String id;
  final String content;
  final DateTime createdAt;

  /// Sent after this person's read cursor.
  final bool unread;

  /// The sender's Display ID (else full name); null when neither is set.
  final String? senderName;

  const InboxItem({
    required this.id,
    required this.content,
    required this.createdAt,
    this.unread = false,
    this.senderName,
  });

  factory InboxItem.fromJson(Map<String, dynamic> j) {
    final name = (j['sender_name'] as String?)?.trim();
    return InboxItem(
      id: j['id'].toString(),
      content: (j['content'] as String?) ?? '',
      createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      unread: j['unread'] == true,
      senderName: name == null || name.isEmpty ? null : name,
    );
  }
}

class InboxException implements Exception {
  final String message;
  const InboxException(this.message);
  @override
  String toString() => message;
}

/// The signed-in patient's broadcast inbox, with a live unread count for the
/// ☰ button and the menu: Realtime on new broadcasts (it only delivers the ones
/// addressed to this person, by RLS), and a recount whenever the app comes back
/// to the foreground.
class InboxService extends ChangeNotifier with WidgetsBindingObserver {
  InboxService._();
  static final InboxService instance = InboxService._();

  static const int pageSize = 100;

  SupabaseClient get _client => Supabase.instance.client;

  int _unread = 0;
  int _version = 0;
  bool _started = false;
  int _generation = -1;
  RealtimeChannel? _channel;

  /// Unread broadcasts.
  int get unread => _unread;

  /// Increments when a broadcast arrives; an open inbox screen reloads on it.
  int get version => _version;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    AuthService.instance.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && AuthService.instance.isSignedIn) {
      _version++;
      refreshCount();
    }
  }

  void _onAuthChanged() {
    final auth = AuthService.instance;
    final generation = auth.isSignedIn ? auth.generation : -1;
    if (generation == _generation) return;
    _generation = generation;
    _unsubscribe();
    _unread = 0;
    notifyListeners();
    final uid = auth.userId;
    if (!auth.isSignedIn || uid == null) return;
    _subscribe(uid);
    refreshCount();
  }

  void _subscribe(String uid) {
    _channel = _client
        .channel('inbox:$uid:${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'broadcasts',
          callback: (_) {
            _version++;
            refreshCount();
          },
        );
    _channel!.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) refreshCount();
    });
  }

  void _unsubscribe() {
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      _client.removeChannel(channel).catchError((_) => 'error');
    }
  }

  Future<void> refreshCount() async {
    final generation = _generation;
    try {
      final n = await _client.rpc('inbox_unread_count');
      if (generation != _generation) return;
      _unread = n is num ? n.toInt() : int.tryParse('$n') ?? 0;
      // Also when the count is unchanged: [version] may have moved.
      notifyListeners();
    } catch (e) {
      debugPrint('InboxService.refreshCount failed: $e');
    }
  }

  /// Newest first.
  Future<List<InboxItem>> fetch() async {
    try {
      final rows = await _client.rpc(
        'inbox_list',
        params: {'p_limit': pageSize},
      );
      return (rows as List)
          .whereType<Map>()
          .map((r) => InboxItem.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    } catch (e) {
      debugPrint('InboxService.fetch failed: $e');
      throw const InboxException('load');
    }
  }

  /// Moves the read cursor to [until] (the newest message shown): it and
  /// everything older is read.
  Future<void> markReadUntil(DateTime until) async {
    try {
      await _client.rpc(
        'inbox_mark_read',
        params: {'p_until': until.toUtc().toIso8601String()},
      );
      await refreshCount();
    } catch (e) {
      debugPrint('InboxService.markReadUntil failed: $e');
    }
  }
}
