import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/legal.dart';
import '../constants/theme.dart';
import '../l10n/app_strings.dart';
import '../services/account_data_service.dart';
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

  Future<void> _runBusy(Future<void> Function() action, String success) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  Future<void> _confirmDeleteData() async {
    final s = context.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteMyData),
        content: Text(s.deleteMyDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.deleteConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runBusy(
      () => AccountDataService.instance.deleteAllDataAndSignOut(),
      s.deleteMyData,
    );
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
                    onPressed: _busy ? null : _logout,
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
          onChanged: _busy ? null : (v) => _setDarkMode(v),
        ),
        SwitchListTile(
          title: Text(s.hindiLabels),
          subtitle: Text(s.hindiLabelsHint),
          value: _hindiLabels,
          onChanged: _busy ? null : (v) => _setHindiLabels(v),
        ),
        SwitchListTile(
          title: Text(s.notifications),
          subtitle: const Text('5 minutes before each period + free-period updates'),
          value: _notifications,
          onChanged: _busy ? null : (v) => _setNotifications(v),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            s.backupRestore,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_upload_outlined),
          title: Text(s.backupNow),
          enabled: !_busy,
          onTap: () => _runBusy(
            () => BackupService.instance.uploadToGoogleDrive(),
            s.backupSuccess,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_download_outlined),
          title: Text(s.restoreFromDrive),
          enabled: !_busy,
          onTap: () => _runBusy(
            () async {
              await BackupService.instance.restoreFromGoogleDrive();
              await NotificationService.instance.rescheduleFromDatabase();
            },
            s.restoreSuccess,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.ios_share_outlined),
          title: Text(s.shareBackupFile),
          enabled: !_busy,
          onTap: () => _runBusy(
            () => BackupService.instance.shareBackupFile(),
            s.backupSuccess,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.folder_open_outlined),
          title: Text(s.restoreFromFile),
          enabled: !_busy,
          onTap: () => _runBusy(
            () async {
              await BackupService.instance.pickAndRestore();
              await NotificationService.instance.rescheduleFromDatabase();
            },
            s.restoreSuccess,
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            s.dataSafetySection,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        ListTile(
          leading: Icon(Icons.delete_forever_outlined, color: palette.danger),
          title: Text(s.deleteMyData),
          subtitle: Text(s.deleteMyDataHint),
          enabled: !_busy,
          onTap: _confirmDeleteData,
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            s.legalSection,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(s.privacyPolicy),
          onTap: () => _openUrl(LegalUrls.privacy),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(s.termsOfService),
          onTap: () => _openUrl(LegalUrls.terms),
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
