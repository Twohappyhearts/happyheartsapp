import 'dart:async';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';

enum SendState { sent, pending, failed }

class ChatMessage {
  final String id;
  final String? senderId;
  final String senderRole; // 'user' | 'team'
  final String content;
  final DateTime createdAt; // always local time
  final SendState sendState;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.createdAt,
    this.sendState = SendState.sent,
  });

  bool get isUserMessage => senderRole == 'user';

  ChatMessage copyWith({SendState? sendState, DateTime? createdAt}) =>
      ChatMessage(
        id: id,
        senderId: senderId,
        senderRole: senderRole,
        content: content,
        createdAt: createdAt ?? this.createdAt,
        sendState: sendState ?? this.sendState,
      );

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['sender_id'] as String?,
      senderRole: (json['sender_role'] as String?) ?? 'user',
      content: json['content'] as String,
      // Server sends UTC; convert to the device's local time for display.
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}

class ChatException implements Exception {
  final String message;
  const ChatException(this.message);
  @override
  String toString() => message;
}

/// Generates RFC-4122 v4 UUIDs on the client so a retry re-uses the same
/// message id (primary key) and can never create a duplicate row.
String newMessageId() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
      '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
}

class ChatPage {
  final List<ChatMessage> messages; // ascending (oldest first)
  final bool hasMore;
  const ChatPage(this.messages, this.hasMore);
}

/// Data access for the patient's single shared "Research Team" conversation.
class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  static const int pageSize = 30;
  static const String _columns =
      'id, sender_id, sender_role, content, created_at';

  SupabaseClient get _client => Supabase.instance.client;

  /// Idempotent: repeated/concurrent calls resolve to the same conversation id.
  Future<String> getOrCreateConversationId() async {
    try {
      final res = await _client.rpc('get_or_create_my_conversation');
      final row = res is List ? (res.isEmpty ? null : res.first) : res;
      if (row is Map && row['id'] != null) return row['id'] as String;
      throw const ChatException('Could not open your conversation.');
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw const ChatException(
          'This account cannot use patient chat. Please sign in with a patient account.',
        );
      }
      throw ChatException('Could not open your conversation: ${e.message}');
    } on ChatException {
      rethrow;
    } catch (_) {
      throw const ChatException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }

  /// Newest-first keyset pagination. [before] is the created_at of the oldest
  /// message already loaded; ties are impossible to skip because the cursor is
  /// the (created_at, id) pair.
  Future<ChatPage> fetchPage(
    String conversationId, {
    ChatMessage? before,
  }) async {
    try {
      var q = _client
          .from('chat_messages')
          .select(_columns)
          .eq('conversation_id', conversationId);
      if (before != null) {
        final ts = before.createdAt.toUtc().toIso8601String();
        q = q.or('created_at.lt.$ts,and(created_at.eq.$ts,id.lt.${before.id})');
      }
      final rows = await q
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(pageSize);
      final list = (rows as List)
          .map((r) => ChatMessage.fromJson(r as Map<String, dynamic>))
          .toList()
          .reversed
          .toList();
      return ChatPage(list, rows.length >= pageSize);
    } on PostgrestException catch (e) {
      throw ChatException('Could not load messages: ${e.message}');
    } catch (_) {
      throw const ChatException(
        'Could not load messages. Check your connection and try again.',
      );
    }
  }

  /// Messages created after [after] (used to recover anything missed while
  /// disconnected or backgrounded).
  Future<List<ChatMessage>> fetchSince(
    String conversationId,
    DateTime after,
  ) async {
    final rows = await _client
        .from('chat_messages')
        .select(_columns)
        .eq('conversation_id', conversationId)
        .gte('created_at', after.toUtc().toIso8601String())
        .order('created_at', ascending: true)
        .order('id', ascending: true)
        .limit(200);
    return (rows as List)
        .map((r) => ChatMessage.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Inserts with a client-supplied stable id. A duplicate-key error on retry
  /// means the first attempt actually succeeded, so we fetch and return it.
  Future<ChatMessage> send({
    required String conversationId,
    required String messageId,
    required String content,
  }) async {
    try {
      final row = await _client
          .from('chat_messages')
          .insert({
            'id': messageId,
            'conversation_id': conversationId,
            'content': content,
          })
          .select(_columns)
          .single();
      return ChatMessage.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        final existing = await _client
            .from('chat_messages')
            .select(_columns)
            .eq('id', messageId)
            .maybeSingle();
        if (existing != null) return ChatMessage.fromJson(existing);
      }
      throw ChatException(_sendMessage(e));
    } catch (_) {
      throw const ChatException(
        'Could not reach the server. Your message was kept - tap retry.',
      );
    }
  }

  String _sendMessage(PostgrestException e) {
    if (e.code == '42501') {
      return 'You do not have permission to send messages in this conversation.';
    }
    if (e.code == '23514') {
      return 'Messages must be 1-4000 characters.';
    }
    return 'Message not sent: ${e.message}';
  }

  RealtimeChannel subscribe(
    String conversationId,
    void Function(ChatMessage) onInsert,
    void Function(RealtimeSubscribeStatus status) onStatus,
  ) {
    final uid = AuthService.instance.userId ?? 'anon';
    final channel = _client
        .channel('chat:$conversationId:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            try {
              onInsert(ChatMessage.fromJson(payload.newRecord));
            } catch (_) {}
          },
        );
    channel.subscribe((status, [error]) => onStatus(status));
    return channel;
  }

  Future<void> unsubscribe(RealtimeChannel? channel) async {
    if (channel == null) return;
    try {
      await _client.removeChannel(channel);
    } catch (_) {}
  }
}
