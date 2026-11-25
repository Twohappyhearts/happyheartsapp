import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'agent_config.dart';
import 'agent_messages.dart';

/// A failed AI assistant request. [status] is the HTTP status when there was one
/// (401: sign in again; 403: the AI notice must be accepted again).
class AgentApiException implements Exception {
  final String message;
  final int? status;
  const AgentApiException(this.message, [this.status]);

  bool get unauthorized => status == 401;
  bool get forbidden => status == 403;

  @override
  String toString() => 'AgentApiException($status): $message';
}

/// Whether the patient has accepted the current AI notice and Terms of Use.
class AgentConsentStatus {
  final bool agreed;

  /// False for staff and admin accounts: they are not asked.
  final bool required;

  const AgentConsentStatus({required this.agreed, required this.required});

  bool get needsNotice => required && !agreed;

  factory AgentConsentStatus.fromJson(Map<String, dynamic> j) =>
      AgentConsentStatus(
        agreed: j['agreed'] == true,
        required: j['required'] != false,
      );
}

/// The opened reply stream of one turn.
class AgentTurn {
  /// The conversation the turn belongs to (new conversations get one here).
  final String? conversationId;

  /// The id the server gave the patient's message (X-User-Message-Id).
  final String? userMessageId;

  /// SSE `data:` payloads, already decoded (one JSON object per chunk).
  final Stream<Map<String, dynamic>> chunks;

  const AgentTurn({
    required this.conversationId,
    required this.chunks,
    this.userMessageId,
  });
}

/// Client of the AI assistant API on the dashboard server (/api/agent/*),
/// the same API the web chat uses. Every request carries the patient's
/// Supabase access token (Authorization: Bearer).
class AgentApi {
  AgentApi._();
  static final AgentApi instance = AgentApi._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      // A reply can take a while to start (searching sources); the stream
      // itself has no overall limit.
      receiveTimeout: const Duration(seconds: 90),
      // Error statuses are read and turned into AgentApiException below.
      validateStatus: (_) => true,
    ),
  );

  GoTrueClient get _auth => Supabase.instance.client.auth;

  Future<Map<String, String>> _headers({bool refresh = false}) async {
    var session = _auth.currentSession;
    if (session != null && (refresh || session.isExpired)) {
      try {
        session = (await _auth.refreshSession()).session ?? session;
      } catch (_) {
        // Keep the old token; the server answers 401 if it is no good.
      }
    }
    final token = session?.accessToken;
    if (token == null) throw const AgentApiException('Not signed in.', 401);
    return {'Authorization': 'Bearer $token'};
  }

  static String _errorOf(Object? body, int status) {
    if (body is Map && body['error'] is String) return body['error'] as String;
    return 'Request failed ($status).';
  }

  /// A JSON request; retried once with a refreshed token after a 401.
  Future<Map<String, dynamic>> _json(
    String method,
    Uri uri, {
    Object? body,
  }) async {
    for (var attempt = 0; ; attempt++) {
      final Response<dynamic> res;
      try {
        res = await _dio.requestUri<dynamic>(
          uri,
          data: body,
          options: Options(
            method: method,
            headers: await _headers(refresh: attempt > 0),
            responseType: ResponseType.json,
          ),
        );
      } on DioException catch (e) {
        throw AgentApiException(e.message ?? 'Could not reach the server.');
      }
      final status = res.statusCode ?? 0;
      if (status == 401 && attempt == 0) continue;
      final data = res.data is String
          ? (jsonDecode(res.data as String) as Object?)
          : res.data;
      if (status < 200 || status >= 300 || data is! Map) {
        throw AgentApiException(_errorOf(data, status), status);
      }
      return Map<String, dynamic>.from(data);
    }
  }

  Future<AgentConsentStatus> consent() async => AgentConsentStatus.fromJson(
    await _json('GET', AgentConfig.apiUri('consent')),
  );

  /// The patient ticked "I understand and agree" and pressed Continue.
  Future<AgentConsentStatus> acceptConsent() async =>
      AgentConsentStatus.fromJson(
        await _json('POST', AgentConfig.apiUri('consent')),
      );

  Future<List<AgentConversation>> conversations() async {
    final body = await _json('GET', AgentConfig.apiUri('conversations'));
    return (body['conversations'] as List? ?? const [])
        .whereType<Map>()
        .map((c) => AgentConversation.fromJson(Map<String, dynamic>.from(c)))
        .toList();
  }

  /// The latest messages of a conversation, oldest first.
  Future<List<AgentMessage>> messages(
    String conversationId, {
    int limit = 100,
  }) async {
    final body = await _json(
      'GET',
      AgentConfig.apiUri(
        'conversations/${Uri.encodeComponent(conversationId)}/messages',
        {'limit': '$limit'},
      ),
    );
    return (body['messages'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => AgentMessage.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> deleteConversation(String conversationId) async {
    await _json(
      'DELETE',
      AgentConfig.apiUri(
        'conversations/${Uri.encodeComponent(conversationId)}',
      ),
    );
  }

  /// Shows another version of a message (one of its siblingIds): the branch
  /// under it becomes the one on screen. Returns that branch.
  Future<List<AgentMessage>> switchBranch(
    String conversationId,
    String messageId,
  ) async {
    final body = await _json(
      'POST',
      AgentConfig.apiUri(
        'conversations/${Uri.encodeComponent(conversationId)}/branch',
      ),
      body: {'messageId': messageId},
    );
    return (body['messages'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => AgentMessage.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// The patient's trial ratings of the answers in a conversation.
  Future<List<AgentAnswerRating>> ratings(String conversationId) async {
    final body = await _json(
      'GET',
      AgentConfig.apiUri(
        'conversations/${Uri.encodeComponent(conversationId)}/ratings',
      ),
    );
    return (body['ratings'] as List? ?? const [])
        .whereType<Map>()
        .map((r) => AgentAnswerRating.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  /// Changes the patient's rating of one answer. [change] holds only the
  /// fields to change: 'usability' / 'safety' (null clears the score) and
  /// 'comment'. Returns the rating as saved, or null when both scores are now
  /// empty (the server deleted it).
  Future<AgentAnswerRating?> saveRating(
    String messageId,
    Map<String, Object?> change,
  ) async {
    final body = await _json(
      'POST',
      AgentConfig.apiUri('ratings'),
      body: {'messageId': messageId, ...change},
    );
    final rating = body['rating'];
    return rating is Map
        ? AgentAnswerRating.fromJson(Map<String, dynamic>.from(rating))
        : null;
  }

  /// Short-lived link (about 10 minutes) to a cited knowledge-base document.
  Future<Uri> documentUrl(String documentId) async {
    final body = await _json(
      'GET',
      AgentConfig.apiUri('sources/${Uri.encodeComponent(documentId)}'),
    );
    final url = Uri.tryParse((body['url'] as String?) ?? '');
    if (url == null) throw const AgentApiException('No link.');
    return url;
  }

  /// Starts one turn with the patient's new message, or with a new version
  /// of message [editOf] (a new branch from there). The reply streams back as
  /// UI message chunks (see AgentMessageAssembler).
  Future<AgentTurn> startTurn({
    String? conversationId,
    required String message,
    String? editOf,
    CancelToken? cancelToken,
  }) async {
    final body = <String, dynamic>{
      'conversationId': ?conversationId,
      'message': message,
      'editOf': ?editOf,
    };
    for (var attempt = 0; ; attempt++) {
      final Response<ResponseBody> res;
      try {
        res = await _dio.postUri<ResponseBody>(
          AgentConfig.apiUri('chat'),
          data: body,
          cancelToken: cancelToken,
          options: Options(
            headers: {
              ...await _headers(refresh: attempt > 0),
              'Accept': 'text/event-stream',
              // Uncompressed: a gzipped stream is held back by the server until
              // a large block is full, so the answer came in a few bursts.
              'Accept-Encoding': 'identity',
            },
            responseType: ResponseType.stream,
          ),
        );
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) rethrow;
        throw AgentApiException(e.message ?? 'Could not reach the server.');
      }
      final status = res.statusCode ?? 0;
      final stream = res.data?.stream;
      if (status == 200 && stream != null) {
        return AgentTurn(
          conversationId:
              res.headers.value('x-conversation-id') ?? conversationId,
          userMessageId: res.headers.value('x-user-message-id'),
          chunks: _sse(stream),
        );
      }
      // Not a stream: read the JSON body.
      Object? json;
      if (stream != null) {
        try {
          final text = await utf8.decodeStream(stream);
          json = text.isEmpty ? null : jsonDecode(text);
        } catch (_) {
          json = null;
        }
      }
      if (status == 401 && attempt == 0) continue;
      throw AgentApiException(_errorOf(json, status), status);
    }
  }

  /// Server-sent events → JSON chunks. Lines look like `data: {...}`; the
  /// stream ends with `data: [DONE]`. The UTF-8 decoder is streaming, so a
  /// character split across two network packets is decoded correctly.
  static Stream<Map<String, dynamic>> _sse(Stream<List<int>> bytes) async* {
    final lines = bytes
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty) continue;
      if (payload == '[DONE]') break;
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map) yield Map<String, dynamic>.from(decoded);
      } catch (_) {
        // Not JSON: skip it.
      }
    }
  }
}
