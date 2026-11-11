import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './app_language.dart';
import './chat_service.dart' show newMessageId;

/// Status of an "I need assistance" request, as shown on the staff dashboard
/// (Alerts): NEW -> ACK (a team member has seen it) -> RESOLVED.
enum AssistanceStatus { newRequest, acknowledged, resolved }

class AssistanceRequest {
  final String id;
  final String message;
  final AssistanceStatus status;
  final DateTime createdAt; // local time
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;

  const AssistanceRequest({
    required this.id,
    required this.message,
    required this.status,
    required this.createdAt,
    this.acknowledgedAt,
    this.resolvedAt,
  });

  bool get isOpen => status != AssistanceStatus.resolved;

  static DateTime? _time(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  factory AssistanceRequest.fromJson(Map<String, dynamic> json) {
    final s = json['status'] as String?;
    return AssistanceRequest(
      id: json['id'] as String,
      message: (json['message'] as String?) ?? '',
      status: s == 'RESOLVED'
          ? AssistanceStatus.resolved
          : s == 'ACK'
          ? AssistanceStatus.acknowledged
          : AssistanceStatus.newRequest,
      createdAt: _time(json['created_at']) ?? DateTime.now(),
      acknowledgedAt: _time(json['acknowledged_at']),
      resolvedAt: _time(json['resolved_at']),
    );
  }
}

class AssistanceException implements Exception {
  final String message;
  const AssistanceException(this.message);
  @override
  String toString() => message;
}

/// Patient side of assistance requests (public.assistance_requests).
/// The database assigns patient, status and timestamps; the app only sends
/// an id (for safe retries) and the message.
class AssistanceService {
  AssistanceService._();
  static final AssistanceService instance = AssistanceService._();

  static const int maxLength = 2000;

  // Patient-visible columns only (staff notes live in a staff-only table).
  static const String _columns =
      'id, message, status, created_at, acknowledged_at, resolved_at';

  SupabaseClient get _client => Supabase.instance.client;

  /// A new id for one request. Reuse it when retrying the same request so a
  /// retry after a timeout can never create a duplicate alert.
  String newRequestId() => newMessageId();

  Future<AssistanceRequest> submit({
    required String requestId,
    required String message,
  }) async {
    final text = message.trim();
    if (text.isEmpty) {
      throw AssistanceException(appL10n.assistErrorEmpty);
    }
    if (text.length > maxLength) {
      throw AssistanceException(appL10n.assistErrorTooLong(maxLength));
    }
    try {
      final row = await _client
          .from('assistance_requests')
          .insert({'id': requestId, 'message': text})
          .select(_columns)
          .single();
      return AssistanceRequest.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Duplicate id: the first attempt went through. Return that row.
        final existing = await _client
            .from('assistance_requests')
            .select(_columns)
            .eq('id', requestId)
            .maybeSingle();
        if (existing != null) return AssistanceRequest.fromJson(existing);
      }
      throw AssistanceException(_describe(e));
    } on AssistanceException {
      rethrow;
    } catch (_) {
      throw AssistanceException(appL10n.assistErrorOffline);
    }
  }

  /// This account's requests, newest first (RLS limits rows to the caller).
  Future<List<AssistanceRequest>> fetchMine({int limit = 100}) async {
    try {
      final rows = await _client
          .from('assistance_requests')
          .select(_columns)
          .order('created_at', ascending: false)
          .limit(limit);
      return (rows as List)
          .map((r) => AssistanceRequest.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('AssistanceService.fetchMine failed: $e');
      throw AssistanceException(appL10n.assistErrorLoad);
    }
  }

  String _describe(PostgrestException e) {
    debugPrint('AssistanceService.submit failed: $e');
    final l10n = appL10n;
    if (e.code == '42501') return l10n.assistErrorNotParticipant;
    if (e.code == '23514') return l10n.assistErrorLength(maxLength);
    if (e.hint == 'rate_limited' || e.message.contains('too many requests')) {
      return l10n.assistErrorRateLimited;
    }
    return l10n.assistErrorNotSent;
  }
}
