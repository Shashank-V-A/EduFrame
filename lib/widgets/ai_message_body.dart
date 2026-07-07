import 'package:flutter/material.dart';

import '../constants/theme.dart';

/// Renders AI text without raw markdown asterisks, with section headers and bullets.
class AiMessageBody extends StatelessWidget {
  const AiMessageBody({
    super.key,
    required this.text,
    this.selectable = true,
  });

  final String text;
  final bool selectable;

  static String clean(String raw) {
    return raw
        .replaceAll('**', '')
        .replaceAll(RegExp(r'(?<!\w)\*(?!\w)'), '')
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
        .trim();
  }

  static bool _isSectionHeader(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    final withoutColon = trimmed.endsWith(':') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    if (withoutColon.length > 48) return false;
    if (RegExp(r'^[A-Z0-9 /&\-]+$').hasMatch(withoutColon)) return true;
    if (RegExp(r'^[\u0900-\u097F\s/&\-]+$').hasMatch(withoutColon) && trimmed.endsWith(':')) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final cleaned = clean(text);
    final lines = cleaned.split('\n');
    final children = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }

      if (_isSectionHeader(trimmed)) {
        final label = trimmed.endsWith(':') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: palette.primary,
                letterSpacing: 0.4,
              ),
            ),
          ),
        );
        continue;
      }

      final bulletMatch = RegExp(r'^[-•]\s*(.+)$').firstMatch(trimmed);
      if (bulletMatch != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                Expanded(
                  child: _text(bulletMatch.group(1)!, palette, height: 1.45),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _text(trimmed, palette, height: 1.5),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _text(String value, AppPalette palette, {required double height}) {
    final style = TextStyle(fontSize: 15, color: palette.text, height: height);
    if (selectable) {
      return SelectableText(value, style: style);
    }
    return Text(value, style: style);
  }
}
