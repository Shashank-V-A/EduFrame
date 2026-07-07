import 'package:flutter/material.dart';

import '../constants/theme.dart';
import 'ai_assist_screen.dart';
import 'classes_screen.dart';
import 'export_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import '../widgets/common.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const ScreenHeader(
          title: 'More',
          subtitle: 'Classes, export, search, and settings.',
        ),
        _tile(
          context,
          icon: Icons.people_outline,
          title: 'Classes',
          subtitle: 'Manage the classes you teach',
          screen: const ClassesScreen(),
        ),
        _tile(
          context,
          icon: Icons.description_outlined,
          title: 'Export PDF',
          subtitle: 'Share lesson plans with your HOD',
          screen: const ExportScreen(),
        ),
        _tile(
          context,
          icon: Icons.search,
          title: 'Search plans',
          subtitle: 'Find old lessons by keyword',
          screen: const SearchScreen(),
        ),
        _tile(
          context,
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'Groq API key and notifications',
          screen: const SettingsScreen(),
        ),
        _tile(
          context,
          icon: Icons.auto_awesome_outlined,
          title: 'AI Assist',
          subtitle: 'Open the AI tools tab',
          screen: const AiAssistScreen(),
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget screen,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: Text(title)),
              body: screen,
            ),
          ),
        ),
      ),
    );
  }
}
