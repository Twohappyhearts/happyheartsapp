import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './app_language.dart';
import './auth_service.dart';

enum SendState { sent, pending, failed }

class ChatMessage {
  final String id;
  final String? senderId;
  final String senderRole; // 'user' | 'team'
  final String content;
  final DateTime createdAt; // always local time
  final SendState sendState;

  /// Last edit by the sender (null: never edited).
  final DateTime? editedAt;

  /// Deleted: shown as a placeholder; [content] is empty.
  final DateTime? deletedAt;

  /// Who deleted it: 'user' (the patient) or 'team'.
  final String? deletedByRole;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.createdAt,
    this.sendState = SendState.sent,
    this.editedAt,
    this.deletedAt,
    this.deletedByRole,
  });

  bool get isUserMessage => senderRole == 'user';
  bool get isDeleted => deletedAt != null;
  bool get isEdited => editedAt != null;

  ChatMessage copyWith({SendState? sendState, DateTime? createdAt}) =>
      ChatMessage(
        id: id,
        senderId: senderId,
        senderRole: senderRole,
        content: content,
        createdAt: createdAt ?? this.createdAt,
        sendState: sendState ?? this.sendState,
        editedAt: editedAt,
        deletedAt: deletedAt,
        deletedByRole: deletedByRole,
      );

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime? time(String key) {
      final v = json[key];
      return v is String ? DateTime.parse(v).toLocal() : null;
    }

    return ChatMessage(
      id: json['id'] as String,
      senderId: json['sender_id'] as String?,
      senderRole: (json['sender_role'] as String?) ?? 'user',
      content: (json['content'] as String?) ?? '',
      // Server sends UTC; convert to the device's local time for display.
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      editedAt: time('edited_at'),
      deletedAt: time('deleted_at'),
      deletedByRole: json['deleted_by_role'] as String?,
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
      'id, sender_id, sender_role, content, created_at, '
      'edited_at, deleted_at, deleted_by_role';

  /// The sender may edit a message for this long (the database checks again).
  static const Duration editWindow = Duration(minutes: 15);

  SupabaseClient get _client => Supabase.instance.client;

  /// Idempotent: repeated/concurrent calls resolve to the same conversation id.
  Future<String> getOrCreateConversationId() async {
    try {
      final res = await _client.rpc('get_or_create_my_conversation');
      final row = res is List ? (res.isEmpty ? null : res.first) : res;
      if (row is Map && row['id'] != null) return row['id'] as String;
      throw ChatException(appL10n.chatErrorOpen);
    } on PostgrestException catch (e) {
      debugPrint('ChatService.getOrCreateConversationId failed: $e');
      if (e.code == '42501') {
        throw ChatException(appL10n.chatErrorWrongAccount);
      }
      throw ChatException(appL10n.chatErrorOpen);
    } on ChatException {
      rethrow;
    } catch (_) {
      throw ChatException(appL10n.errorServerUnreachable);
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
    } catch (e) {
      debugPrint('ChatService.fetchPage failed: $e');
      throw ChatException(appL10n.chatErrorLoad);
    }
  }

  /// Names of the team members who wrote in this conversation, by sender id:
  /// their Display ID from the dashboard, else their full name. Members with
  /// neither are not in the map (the chat shows "Research Team" for them).
  /// Patients cannot read staff profiles, so this goes through the
  /// chat_staff_names function (migration 20261122000200).
  Future<Map<String, String>> staffNames(String conversationId) async {
    final rows = await _client.rpc(
      'chat_staff_names',
      params: {'p_conversation_id': conversationId},
    );
    final names = <String, String>{};
    for (final r in (rows as List? ?? const [])) {
      if (r is! Map) continue;
      final id = r['sender_id'];
      final name = r['name'];
      if (id is String && name is String && name.trim().isNotEmpty) {
        names[id] = name.trim();
      }
    }
    return names;
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
      throw ChatException(appL10n.chatErrorKept);
    }
  }

  /// Edits your own message in place (same id). The database keeps the
  /// earlier text in chat_message_revisions and refuses after [editWindow].
  Future<ChatMessage> edit(String messageId, String content) async {
    try {
      final res = await _client.rpc(
        'chat_edit_message',
        params: {'p_message_id': messageId, 'p_content': content},
      );
      return ChatMessage.fromJson(_row(res));
    } on PostgrestException catch (e) {
      debugPrint('ChatService.edit failed: $e');
      if (e.code == 'HC001') throw ChatException(appL10n.chatEditTooLate);
      if (e.code == '23514') throw ChatException(appL10n.chatErrorLength);
      throw ChatException(appL10n.chatEditFailed);
    } catch (e) {
      debugPrint('ChatService.edit failed: $e');
      throw ChatException(appL10n.chatEditFailed);
    }
  }

  /// Deletes your own message: it stays in the conversation as a placeholder,
  /// and its text is kept in the history for the research team.
  Future<ChatMessage> delete(String messageId) async {
    try {
      final res = await _client.rpc(
        'chat_delete_message',
        params: {'p_message_id': messageId},
      );
      return ChatMessage.fromJson(_row(res));
    } catch (e) {
      debugPrint('ChatService.delete failed: $e');
      throw ChatException(appL10n.chatDeleteFailed);
    }
  }

  Map<String, dynamic> _row(dynamic res) {
    final row = res is List ? (res.isEmpty ? null : res.first) : res;
    if (row is Map) return Map<String, dynamic>.from(row);
    throw const FormatException('no message returned');
  }

  String _sendMessage(PostgrestException e) {
    debugPrint('ChatService.send failed: $e');
    if (e.code == '42501') return appL10n.chatErrorNoPermission;
    if (e.code == '23514') return appL10n.chatErrorLength;
    return appL10n.chatErrorNotSent;
  }

  /// New messages (INSERT) and edits/deletions (UPDATE, same id) of one
  /// conversation; both are merged by id.
  RealtimeChannel subscribe(
    String conversationId,
    void Function(ChatMessage) onMessage,
    void Function(RealtimeSubscribeStatus status) onStatus,
  ) {
    final uid = AuthService.instance.userId ?? 'anon';
    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'conversation_id',
      value: conversationId,
    );
    void handle(PostgresChangePayload payload) {
      try {
        onMessage(ChatMessage.fromJson(payload.newRecord));
      } catch (_) {}
    }

    final channel = _client
        .channel('chat:$conversationId:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: filter,
          callback: handle,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_messages',
          filter: filter,
          callback: handle,
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
