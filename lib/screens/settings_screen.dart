import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../constants/theme.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  GoogleSignInAccount? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notifications = await SettingsService.instance.notificationsEnabled();
    if (!mounted) return;
    setState(() {
      _notifications = notifications;
      _user = AuthService.instance.currentUser.value;
    });
  }

  Future<void> _save() async {
    await SettingsService.instance.setNotificationsEnabled(_notifications);
    await NotificationService.instance.rescheduleFromDatabase();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  Future<void> _logout() async {
    await AuthService.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const ScreenHeader(
          title: 'Settings',
          subtitle: 'Manage your Google account and class reminders.',
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
                      backgroundColor: AppColors.accentSoft,
                      backgroundImage:
                          _user?.photoUrl != null ? NetworkImage(_user!.photoUrl!) : null,
                      child: _user?.photoUrl == null
                          ? const Icon(Icons.person, color: AppColors.primary)
                          : null,
                    ),
                    title: Text(_user?.displayName ?? 'Google account'),
                    subtitle: Text(_user?.email ?? 'Not signed in'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'AI uses the app build configuration. Teachers do not need to enter an API key.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Log out'),
                  ),
                ],
              ),
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Class reminders'),
          subtitle: const Text('5 minutes before each period + free-period updates'),
          value: _notifications,
          onChanged: (v) => setState(() => _notifications = v),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save settings'),
          ),
        ),
      ],
    );
  }
}
