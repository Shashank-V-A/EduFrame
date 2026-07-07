import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  LocaleService._();
  static final LocaleService instance = LocaleService._();

  static const _hindiLabelsKey = 'hindi_labels';

  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final hindi = prefs.getBool(_hindiLabelsKey) ?? false;
    locale.value = hindi ? const Locale('hi') : const Locale('en');
  }

  Future<void> setHindiLabels(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hindiLabelsKey, enabled);
    locale.value = enabled ? const Locale('hi') : const Locale('en');
  }

  Future<bool> hindiLabelsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hindiLabelsKey) ?? false;
  }
}
