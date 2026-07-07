import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF7F3EB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF0EBE0);
  static const border = Color(0xFFE2D9C8);
  static const text = Color(0xFF1E2A32);
  static const textSecondary = Color(0xFF5C6B73);
  static const textMuted = Color(0xFF8A9499);
  static const primary = Color(0xFF2C4A6E);
  static const accent = Color(0xFFC17F3A);
  static const accentSoft = Color(0xFFF5E6D3);
  static const danger = Color(0xFFB54A4A);

  // Dark palette
  static const backgroundDark = Color(0xFF121820);
  static const surfaceDark = Color(0xFF1A2430);
  static const surfaceMutedDark = Color(0xFF243040);
  static const borderDark = Color(0xFF3A4A5C);
  static const textDark = Color(0xFFE8EDF2);
  static const textSecondaryDark = Color(0xFFB0BAC4);
  static const textMutedDark = Color(0xFF7A8794);
  static const primaryDark = Color(0xFF7EB3E8);
  static const accentSoftDark = Color(0xFF3D3020);
}

ThemeData buildAppTheme({bool dark = false}) {
  final bg = dark ? AppColors.backgroundDark : AppColors.background;
  final surface = dark ? AppColors.surfaceDark : AppColors.surface;
  final primary = dark ? AppColors.primaryDark : AppColors.primary;
  final border = dark ? AppColors.borderDark : AppColors.border;
  final fill = dark ? AppColors.surfaceMutedDark : AppColors.surface;
  final accentSoft = dark ? AppColors.accentSoftDark : AppColors.accentSoft;
  final textSecondary = dark ? AppColors.textSecondaryDark : AppColors.textSecondary;

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: primary,
      surface: surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: primary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: primary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: dark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: accentSoft,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primary);
        }
        return TextStyle(fontSize: 12, color: textSecondary);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: dark ? AppColors.backgroundDark : Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        backgroundColor: accentSoft,
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? AppColors.surfaceMutedDark : AppColors.primary,
      contentTextStyle: TextStyle(color: dark ? AppColors.textDark : Colors.white),
    ),
  );
}

ThemeData buildLightTheme() => buildAppTheme(dark: false);
ThemeData buildDarkTheme() => buildAppTheme(dark: true);

/// Theme-aware color helpers for widgets that used static AppColors.
class AppPalette {
  AppPalette(this.dark);

  final bool dark;

  Color get text => dark ? AppColors.textDark : AppColors.text;
  Color get textSecondary => dark ? AppColors.textSecondaryDark : AppColors.textSecondary;
  Color get textMuted => dark ? AppColors.textMutedDark : AppColors.textMuted;
  Color get primary => dark ? AppColors.primaryDark : AppColors.primary;
  Color get border => dark ? AppColors.borderDark : AppColors.border;
  Color get surface => dark ? AppColors.surfaceDark : AppColors.surface;
  Color get accentSoft => dark ? AppColors.accentSoftDark : AppColors.accentSoft;
  Color get danger => AppColors.danger;

  static AppPalette of(BuildContext context) {
    return AppPalette(Theme.of(context).brightness == Brightness.dark);
  }
}
