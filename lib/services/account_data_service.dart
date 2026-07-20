import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'onboarding_service.dart';

/// Clears local EduFrame data for the signed-in Google user.
class AccountDataService {
  AccountDataService._();
  static final AccountDataService instance = AccountDataService._();

  /// Deletes lesson data for the current user and resets onboarding for them.
  Future<void> deleteLocalDataKeepSignedIn() async {
    await DatabaseService.instance.deleteAllLocalData();
    await OnboardingService.instance.clearForCurrentUser();
    await NotificationService.instance.rescheduleFromDatabase();
  }

  /// Permanently removes the user DB file, clears user onboarding, then signs out.
  Future<void> deleteAllDataAndSignOut() async {
    await NotificationService.instance.cancelAll();
    await DatabaseService.instance.wipeUserDatabase();
    await OnboardingService.instance.clearForCurrentUser();

    final prefs = await SharedPreferences.getInstance();
    final userId = AuthService.instance.currentUserId;
    if (userId != null) {
      await prefs.remove('onboarding_completed_$userId');
    }

    await AuthService.instance.signOut();
  }
}
