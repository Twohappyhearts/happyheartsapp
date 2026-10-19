import 'package:flutter/foundation.dart';

import './auth_service.dart';
import './profile_service.dart';

/// In-memory holder for the signed-in user's profile, shared by Profile,
/// Education Hub greeting and the Kahoot username. Cleared on account change.
class CurrentProfile extends ChangeNotifier {
  CurrentProfile._() {
    AuthService.instance.addListener(_onAuthChanged);
  }
  static final CurrentProfile instance = CurrentProfile._();

  UserProfile? _profile;
  String? _error;
  bool _loading = false;
  int _loadedGeneration = -1;

  UserProfile? get profile => _profile;
  String? get error => _error;
  bool get isLoading => _loading;

  void _onAuthChanged() {
    final auth = AuthService.instance;
    if (auth.generation != _loadedGeneration) {
      // Account changed or signed out: drop old account data immediately.
      _profile = null;
      _error = null;
      _loading = false;
      _loadedGeneration = -1;
      notifyListeners();
    }
  }

  Future<void> load({bool force = false}) async {
    final auth = AuthService.instance;
    if (!auth.isSignedIn) return;
    if (_loading) return;
    if (!force && _profile != null && _loadedGeneration == auth.generation) {
      return;
    }

    final gen = auth.generation;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final p = await ProfileService.instance.loadMine();
      if (auth.generation != gen) return; // stale result, discard
      _profile = p;
      _loadedGeneration = gen;
    } catch (e) {
      if (auth.generation != gen) return;
      _profile = null;
      _error = e.toString();
    } finally {
      if (auth.generation == gen) {
        _loading = false;
        notifyListeners();
      } else {
        _loading = false;
      }
    }
  }

  Future<void> updateFullName(String name) async {
    final auth = AuthService.instance;
    final gen = auth.generation;
    final p = await ProfileService.instance.updateFullName(name);
    if (auth.generation != gen) return;
    _profile = p;
    notifyListeners();
  }
}
