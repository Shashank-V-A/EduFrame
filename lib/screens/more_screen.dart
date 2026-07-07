import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../l10n/app_strings.dart';
import 'classes_screen.dart';
import 'export_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import '../widgets/common.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final palette = AppPalette.of(context);

    return ListView(
      children: [
        ScreenHeader(
          title: s.moreTitle,
          subtitle: s.moreSubtitle,
        ),
        _tile(
          context,
          palette: palette,
          icon: Icons.settings_outlined,
          title: s.moreSettings,
          subtitle: s.moreSettingsHint,
          screen: const SettingsScreen(),
        ),
        _tile(
          context,
          palette: palette,
          icon: Icons.people_outline,
          title: s.moreClasses,
          subtitle: s.moreClassesHint,
          screen: const ClassesScreen(),
        ),
        _tile(
          context,
          palette: palette,
          icon: Icons.description_outlined,
          title: s.moreExport,
          subtitle: s.moreExportHint,
          screen: const ExportScreen(),
        ),
        _tile(
          context,
          palette: palette,
          icon: Icons.search,
          title: s.moreSearch,
          subtitle: s.moreSearchHint,
          screen: const SearchScreen(),
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context, {
    required AppPalette palette,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget screen,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: palette.primary),
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
