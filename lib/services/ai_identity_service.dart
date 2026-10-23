import 'package:supabase_flutter/supabase_flutter.dart';

/// The Botpress (AI assistant) identity saved for the signed-in account in
/// public.ai_identities. Lets the account get its own AI conversation back
/// after switching accounts or devices.
class AiIdentity {
  final String botpressUserId;
  final String botpressUserKey;
  final String? botpressConversationId;

  const AiIdentity({
    required this.botpressUserId,
    required this.botpressUserKey,
    this.botpressConversationId,
  });

  bool sameAs(AiIdentity? other) =>
      other != null &&
      other.botpressUserId == botpressUserId &&
      other.botpressUserKey == botpressUserKey &&
      other.botpressConversationId == botpressConversationId;

  Map<String, dynamic> toWebchatState() => {
    if (botpressConversationId != null)
      'conversationId': botpressConversationId,
    'user': {'userId': botpressUserId, 'userToken': botpressUserKey},
  };

  /// Parses the `state` object Botpress Webchat keeps in localStorage:
  /// {conversationId, user: {userId, userToken}}.
  static AiIdentity? fromWebchatState(Object? state) {
    if (state is! Map) return null;
    final user = state['user'];
    if (user is! Map) return null;
    final id = user['userId'];
    final token = user['userToken'];
    if (id is! String || id.isEmpty || token is! String || token.isEmpty) {
      return null;
    }
    final conv = state['conversationId'];
    return AiIdentity(
      botpressUserId: id,
      botpressUserKey: token,
      botpressConversationId: conv is String && conv.isNotEmpty ? conv : null,
    );
  }
}

class AiIdentityException implements Exception {
  final String message;
  const AiIdentityException(this.message);
  @override
  String toString() => message;
}

class AiIdentityService {
  AiIdentityService._();
  static final AiIdentityService instance = AiIdentityService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Returns the saved identity, or null if this account has none yet.
  /// Throws [AiIdentityException] if it could not be loaded (so the caller
  /// does not start a fresh identity and overwrite a saved one by mistake).
  Future<AiIdentity?> fetchMine() async {
    try {
      final res = await _client.rpc('get_my_ai_identity');
      final row = res is List ? (res.isEmpty ? null : res.first) : res;
      if (row is! Map) return null;
      final id = row['botpress_user_id'];
      final key = row['botpress_user_key'];
      if (id is! String || key is! String) return null;
      final conv = row['botpress_conversation_id'];
      return AiIdentity(
        botpressUserId: id,
        botpressUserKey: key,
        botpressConversationId: conv is String && conv.isNotEmpty ? conv : null,
      );
    } on PostgrestException catch (e) {
      throw AiIdentityException('Could not load your AI assistant: ${e.message}');
    } catch (_) {
      throw const AiIdentityException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }

  Future<void> saveMine(AiIdentity identity) async {
    await _client.rpc(
      'save_my_ai_identity',
      params: {
        'p_botpress_user_id': identity.botpressUserId,
        'p_botpress_user_key': identity.botpressUserKey,
        'p_botpress_conversation_id': identity.botpressConversationId,
      },
    );
  }
}
