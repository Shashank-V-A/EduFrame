import 'package:intl/intl.dart';

String toDateString(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

String formatDisplayDate(String dateStr) {
  final normalized = normalizePlanDate(dateStr);
  final date = DateTime.parse(normalized);
  return DateFormat('EEE, d MMM yyyy').format(date);
}

String addDays(String dateStr, int days) {
  final date = DateTime.parse(normalizePlanDate(dateStr)).add(Duration(days: days));
  return toDateString(date);
}

String greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning.';
  if (hour < 17) return 'Good afternoon.';
  return 'Good evening.';
}

/// Ensures dates are stored and queried as YYYY-MM-DD.
String normalizePlanDate(String input) {
  final trimmed = input.trim();
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) {
    return trimmed;
  }

  try {
    return toDateString(DateTime.parse(trimmed));
  } catch (_) {
    return toDateString(DateTime.now());
  }
}

/// Next calendar date for a weekday (1=Mon … 7=Sun). Uses today if it matches.
String dateForWeekday(int dayOfWeek) {
  final now = DateTime.now();
  var diff = dayOfWeek - now.weekday;
  if (diff < 0) diff += 7;
  return toDateString(now.add(Duration(days: diff)));
}

String nextMondayDate() {
  final now = DateTime.now();
  var diff = DateTime.monday - now.weekday;
  if (diff <= 0) diff += 7;
  return toDateString(now.add(Duration(days: diff)));
}

DateTime parsePlanDate(String dateStr) => DateTime.parse(normalizePlanDate(dateStr));

String formatTime12h(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length < 2) return hhmm;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  final dt = DateTime(2000, 1, 1, hour, minute);
  return DateFormat('h:mm a').format(dt);
}

String pdfSafe(String text) {
  return text
      .replaceAll('\u2014', '-')
      .replaceAll('\u2013', '-')
      .replaceAll('\u00b7', '|');
}
