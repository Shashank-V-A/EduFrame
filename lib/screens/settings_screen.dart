import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _notifications = true;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final key = await SettingsService.instance.getGroqApiKey();
    final notifications = await SettingsService.instance.notificationsEnabled();
    if (!mounted) return;
    setState(() {
      _apiKeyController.text = key ?? '';
      _notifications = notifications;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await SettingsService.instance.setGroqApiKey(_apiKeyController.text);
    await SettingsService.instance.setNotificationsEnabled(_notifications);
    await NotificationService.instance.rescheduleFromDatabase();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const ScreenHeader(
          title: 'Settings',
          subtitle: 'Connect Groq AI and manage class reminders.',
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Groq API key', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'gsk_...',
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get a free key at console.groq.com. Stored only on this phone.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
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
