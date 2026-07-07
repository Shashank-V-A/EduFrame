import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _groqApiKey = 'groq_api_key';
  static const _notificationsEnabled = 'notifications_enabled';

  Future<String?> getGroqApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_groqApiKey);
    if (key == null || key.trim().isEmpty) return null;
    return key.trim();
  }

  Future<void> setGroqApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_groqApiKey, key.trim());
  }

  Future<bool> notificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabled, enabled);
  }
}
