import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

class OnboardingService {
  OnboardingService._();
  static final OnboardingService instance = OnboardingService._();

  static const _completedKey = 'onboarding_completed';

  String _key() {
    final userId = AuthService.instance.currentUserId;
    if (userId == null || userId.isEmpty) return _completedKey;
    return '${_completedKey}_$userId';
  }

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final scoped = prefs.getBool(_key());
    if (scoped != null) return scoped;
    // Migrate legacy device-wide flag for the first signed-in user.
    return prefs.getBool(_completedKey) ?? false;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(), true);
  }

  Future<void> clearForCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key());
  }
}
