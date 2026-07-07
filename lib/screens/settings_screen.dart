import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../constants/theme.dart';
import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
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
  bool _busy = false;
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

  Future<void> _save() async {
    await SettingsService.instance.setNotificationsEnabled(_notifications);
    await ThemeService.instance.setDarkMode(_darkMode);
    await LocaleService.instance.setHindiLabels(_hindiLabels);
    await NotificationService.instance.rescheduleFromDatabase();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.strings.saveSettings)),
    );
  }

  Future<void> _runBackup(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
          onChanged: (v) => setState(() => _darkMode = v),
        ),
        SwitchListTile(
          title: Text(s.hindiLabels),
          subtitle: Text(s.hindiLabelsHint),
          value: _hindiLabels,
          onChanged: (v) => setState(() => _hindiLabels = v),
        ),
        SwitchListTile(
          title: Text(s.notifications),
          subtitle: const Text('5 minutes before each period + free-period updates'),
          value: _notifications,
          onChanged: (v) => setState(() => _notifications = v),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            s.backupRestore,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        ListTile(
          leading: Icon(Icons.cloud_upload_outlined, color: palette.primary),
          title: Text(s.backupNow),
          enabled: !_busy,
          onTap: () => _runBackup(
            BackupService.instance.uploadToGoogleDrive,
            'Backup uploaded to Google Drive',
          ),
        ),
        ListTile(
          leading: Icon(Icons.cloud_download_outlined, color: palette.primary),
          title: Text(s.restoreBackup),
          enabled: !_busy,
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Restore backup?'),
                content: const Text(
                  'This replaces all current classes, plans, and timetable data with the latest Drive backup.',
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore')),
                ],
              ),
            );
            if (ok == true) {
              await _runBackup(
                BackupService.instance.restoreFromGoogleDrive,
                'Restored from Google Drive',
              );
              await NotificationService.instance.rescheduleFromDatabase();
            }
          },
        ),
        ListTile(
          leading: Icon(Icons.ios_share_outlined, color: palette.primary),
          title: Text(s.shareBackupFile),
          enabled: !_busy,
          onTap: () => _runBackup(
            BackupService.instance.shareBackupFile,
            'Backup file ready to share',
          ),
        ),
        ListTile(
          leading: Icon(Icons.folder_open_outlined, color: palette.primary),
          title: const Text('Import backup file'),
          enabled: !_busy,
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Import backup?'),
                content: const Text('This replaces all current data with the selected backup file.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Import')),
                ],
              ),
            );
            if (ok == true) {
              await _runBackup(
                BackupService.instance.pickAndRestore,
                'Backup imported successfully',
              );
              await NotificationService.instance.rescheduleFromDatabase();
            }
          },
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(s.saveSettings),
          ),
        ),
      ],
    );
  }
}
