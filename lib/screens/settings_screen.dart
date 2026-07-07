import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../constants/theme.dart';
import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../services/theme_service.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _darkMode = false;
  bool _hindiLabels = false;
  GoogleSignInAccount? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      SettingsService.instance.notificationsEnabled(),
      ThemeService.instance.darkModeEnabled(),
      LocaleService.instance.hindiLabelsEnabled(),
    ]);
    if (!mounted) return;
    setState(() {
      _notifications = results[0];
      _darkMode = results[1];
      _hindiLabels = results[2];
      _user = AuthService.instance.currentUser.value;
    });
  }

  Future<void> _setDarkMode(bool enabled) async {
    setState(() => _darkMode = enabled);
    await ThemeService.instance.setDarkMode(enabled);
  }

  Future<void> _setHindiLabels(bool enabled) async {
    setState(() => _hindiLabels = enabled);
    await LocaleService.instance.setHindiLabels(enabled);
  }

  Future<void> _setNotifications(bool enabled) async {
    setState(() => _notifications = enabled);
    await SettingsService.instance.setNotificationsEnabled(enabled);
    await NotificationService.instance.rescheduleFromDatabase();
  }

  Future<void> _logout() async {
    await AuthService.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final palette = AppPalette.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ScreenHeader(
          title: s.settingsTitle,
          subtitle: s.settingsSubtitle,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Signed in account',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: palette.accentSoft,
                      backgroundImage:
                          _user?.photoUrl != null ? NetworkImage(_user!.photoUrl!) : null,
                      child: _user?.photoUrl == null
                          ? Icon(Icons.person, color: palette.primary)
                          : null,
                    ),
                    title: Text(_user?.displayName ?? 'Google account'),
                    subtitle: Text(_user?.email ?? 'Not signed in'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: Text(s.logout),
                  ),
                ],
              ),
            ),
          ),
        ),
        SwitchListTile(
          title: Text(s.darkMode),
          value: _darkMode,
          onChanged: (v) => _setDarkMode(v),
        ),
        SwitchListTile(
          title: Text(s.hindiLabels),
          subtitle: Text(s.hindiLabelsHint),
          value: _hindiLabels,
          onChanged: (v) => _setHindiLabels(v),
        ),
        SwitchListTile(
          title: Text(s.notifications),
          subtitle: const Text('5 minutes before each period + free-period updates'),
          value: _notifications,
          onChanged: (v) => _setNotifications(v),
        ),
      ],
    );
  }
}
