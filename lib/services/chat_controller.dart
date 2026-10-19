import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './chat_service.dart';

/// Owns all chat state for ONE signed-in account. A new instance is created per
/// account (see ChatScreen); `dispose()` removes the Realtime subscription and
/// every async continuation checks `_alive` + the auth generation so a previous
/// user's data can never land in a new session.
class ChatController extends ChangeNotifier {
  ChatController() : _generation = AuthService.instance.generation;

  final int _generation;
  final ChatService _service = ChatService.instance;

  // id -> message. Single merge point => automatic deduplication.
  final Map<String, ChatMessage> _byId = {};
  String? _conversationId;
  RealtimeChannel? _channel;
  bool _alive = true;
  bool _initializing = false;

  bool isLoading = true;
  bool isLoadingOlder = false;
  bool hasMore = false;
  bool realtimeConnected = false;
  String? error;

  /// Ascending by (createdAt, id): stable ordering.
  List<ChatMessage> get messages {
    final list = _byId.values.toList()
      ..sort((a, b) {
        final c = a.createdAt.compareTo(b.createdAt);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    return list;
  }

  bool get _stale =>
      !_alive ||
      AuthService.instance.generation != _generation ||
      !AuthService.instance.isSignedIn;

  void _notify() {
    if (!_alive) return;
    notifyListeners();
  }

  // ---- Initial load ---------------------------------------------------------

  Future<void> init() async {
    if (_initializing) return;
    _initializing = true;
    isLoading = true;
    error = null;
    _notify();
    try {
      final convId = await _service.getOrCreateConversationId();
      if (_stale) return;
      _conversationId = convId;

      // Subscribe BEFORE the history fetch so nothing is missed in between;
      // anything received is merged by id, so overlap is harmless.
      await _subscribe();
      if (_stale) return;

      final page = await _service.fetchPage(convId);
      if (_stale) return;
      _merge(page.messages);
      hasMore = page.hasMore;
      isLoading = false;
      error = null;
    } on ChatException catch (e) {
      if (_stale) return;
      isLoading = false;
      error = e.message;
    } catch (_) {
      if (_stale) return;
      isLoading = false;
      error = 'Something went wrong loading your conversation.';
    } finally {
      _initializing = false;
      _notify();
    }
  }

  Future<void> _subscribe() async {
    final convId = _conversationId;
    if (convId == null) return;
    await _service.unsubscribe(_channel);
    _channel = _service.subscribe(
      convId,
      (msg) {
        if (_stale) return;
        _merge([msg]);
        _notify();
      },
      (status) {
        if (_stale) return;
        final connected = status == RealtimeSubscribeStatus.subscribed;
        final wasConnected = realtimeConnected;
        realtimeConnected = connected;
        // (Re)connected after a drop: recover anything missed.
        if (connected && !wasConnected && !isLoading) {
          unawaited(resync());
        }
      },
    );
  }

  // ---- Pagination -----------------------------------------------------------

  Future<void> loadOlder() async {
    final convId = _conversationId;
    if (convId == null || isLoadingOlder || !hasMore || isLoading) return;
    final confirmed = messages.where((m) => m.sendState == SendState.sent);
    if (confirmed.isEmpty) return;
    isLoadingOlder = true;
    _notify();
    try {
      final page = await _service.fetchPage(convId, before: confirmed.first);
      if (_stale) return;
      _merge(page.messages);
      hasMore = page.hasMore;
    } catch (_) {
      // Keep existing messages; user can scroll again to retry.
    } finally {
      isLoadingOlder = false;
      _notify();
    }
  }

  // ---- Resync (foreground / reconnect) -----------------------------------------

  Future<void> resync() async {
    final convId = _conversationId;
    if (convId == null || isLoading) return;
    try {
      final confirmed = messages
          .where((m) => m.sendState == SendState.sent)
          .toList();
      if (confirmed.isEmpty) {
        final page = await _service.fetchPage(convId);
        if (_stale) return;
        _merge(page.messages);
        hasMore = page.hasMore;
      } else {
        // Overlap by a few seconds; duplicates are collapsed by id.
        final since = confirmed.last.createdAt.subtract(
          const Duration(seconds: 5),
        );
        final missed = await _service.fetchSince(convId, since);
        if (_stale) return;
        _merge(missed);
      }
      _notify();
    } catch (_) {}
  }

  /// Called when the app returns to the foreground.
  Future<void> onResumed() async {
    if (_conversationId == null) {
      if (error != null) await init();
      return;
    }
    if (!realtimeConnected) {
      try {
        await _subscribe();
      } catch (_) {}
    }
    await resync();
  }

  // ---- Sending ------------------------------------------------------------------

  /// Returns the message id used (so the UI can scroll), or null if rejected.
  Future<String?> send(String rawText) async {
    final text = rawText.trim();
    final convId = _conversationId;
    if (text.isEmpty || convId == null || _stale) return null;
    if (text.length > 4000) {
      error = null;
      return null;
    }
    final id = newMessageId();
    final pending = ChatMessage(
      id: id,
      senderId: AuthService.instance.userId,
      senderRole: 'user',
      content: text,
      createdAt: DateTime.now(),
      sendState: SendState.pending,
    );
    _byId[id] = pending;
    _notify();
    unawaited(_deliver(pending));
    return id;
  }

  /// Retry re-uses the SAME id, so it can never create a duplicate row.
  Future<void> retry(String messageId) async {
    final m = _byId[messageId];
    if (m == null || m.sendState != SendState.failed) return;
    final pending = m.copyWith(sendState: SendState.pending);
    _byId[messageId] = pending;
    _notify();
    await _deliver(pending);
  }

  /// Discards a failed message the user no longer wants to send.
  void discard(String messageId) {
    final m = _byId[messageId];
    if (m != null && m.sendState == SendState.failed) {
      _byId.remove(messageId);
      _notify();
    }
  }

  Future<void> _deliver(ChatMessage pending) async {
    final convId = _conversationId;
    if (convId == null) return;
    try {
      final saved = await _service.send(
        conversationId: convId,
        messageId: pending.id,
        content: pending.content,
      );
      if (_stale) return;
      // Show the saved row immediately; a later Realtime echo merges by id.
      _byId[saved.id] = saved;
    } catch (_) {
      if (_stale) return;
      final current = _byId[pending.id];
      // Only mark failed if Realtime hasn't already delivered the saved row.
      if (current != null && current.sendState == SendState.pending) {
        _byId[pending.id] = current.copyWith(sendState: SendState.failed);
      }
    }
    _notify();
  }

  // ---- Helpers --------------------------------------------------------------------

  void _merge(List<ChatMessage> incoming) {
    // Server copies (from fetch, send response, or Realtime) always replace any
    // local pending/failed copy with the same id.
    for (final m in incoming) {
      _byId[m.id] = m;
    }
  }

  @override
  void dispose() {
    _alive = false;
    final ch = _channel;
    _channel = null;
    if (ch != null) unawaited(_service.unsubscribe(ch));
    _byId.clear();
    super.dispose();
  }
}
