import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './app_language.dart';
import './auth_service.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String username;
  final String? email;
  final String? phone;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.username,
    this.email,
    this.phone,
  });

  /// Stored as "+digits" / digits; shown as (949) 555-0100 for US numbers.
  String? get phoneDisplay {
    final p = phone;
    if (p == null || p.isEmpty) return null;
    final us10 = RegExp(r'^(\d{3})(\d{3})(\d{4})$').firstMatch(p);
    if (us10 != null) {
      return '(${us10[1]}) ${us10[2]}-${us10[3]}';
    }
    final us11 = RegExp(r'^\+?1(\d{3})(\d{3})(\d{4})$').firstMatch(p);
    if (us11 != null) {
      return '+1 (${us11[1]}) ${us11[2]}-${us11[3]}';
    }
    return p;
  }

  String get displayName => fullName.trim().isNotEmpty ? fullName : username;

  String get firstName {
    final n = displayName.trim();
    return n.isEmpty ? username : n.split(RegExp(r'\s+')).first;
  }

  String get initial {
    final n = displayName.trim();
    return n.isEmpty ? '?' : n.substring(0, 1).toUpperCase();
  }
}

class ProfileException implements Exception {
  final String message;
  final bool missing;
  const ProfileException(this.message, {this.missing = false});
  @override
  String toString() => message;
}

/// Loads/updates the signed-in user's profile. Results are only returned if the
/// account is still the same one that started the request.
class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<UserProfile> loadMine() async {
    final auth = AuthService.instance;
    final uid = auth.userId;
    final gen = auth.generation;
    if (uid == null) throw ProfileException(appL10n.profileErrorSignIn);

    try {
      final row = await _client
          .from('profiles')
          .select('id, full_name, username, phone')
          .eq('id', uid)
          .maybeSingle();

      if (auth.generation != gen) {
        throw ProfileException(appL10n.profileErrorSessionChanged);
      }
      if (row == null) {
        throw ProfileException(appL10n.profileErrorMissing, missing: true);
      }
      return UserProfile(
        id: row['id'] as String,
        fullName: (row['full_name'] as String?) ?? '',
        username: row['username'] as String,
        email: auth.email,
        phone: row['phone'] as String?,
      );
    } on PostgrestException catch (e) {
      debugPrint('ProfileService.loadMine failed: $e');
      if (e.code == '42501') {
        throw ProfileException(appL10n.profileErrorPermission);
      }
      throw ProfileException(appL10n.profileErrorLoad);
    } on ProfileException {
      rethrow;
    } catch (_) {
      throw ProfileException(appL10n.profileErrorLoad);
    }
  }

  Future<UserProfile> updateFullName(String fullName) async {
    final auth = AuthService.instance;
    final uid = auth.userId;
    if (uid == null) throw ProfileException(appL10n.profileErrorSignIn);
    final name = fullName.trim();
    if (name.isEmpty) throw ProfileException(appL10n.profileErrorNameEmpty);
    try {
      await _client.from('profiles').update({'full_name': name}).eq('id', uid);
    } catch (e) {
      debugPrint('ProfileService.updateFullName failed: $e');
      throw ProfileException(appL10n.profileErrorSaveName);
    }
    return loadMine();
  }
}
