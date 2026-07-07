import 'package:intl/intl.dart';

String toDateString(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

String formatDisplayDate(String dateStr) {
  final date = DateTime.parse(dateStr);
  return DateFormat('EEE, d MMM yyyy').format(date);
}

String addDays(String dateStr, int days) {
  final date = DateTime.parse(dateStr).add(Duration(days: days));
  return toDateString(date);
}

String greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning.';
  if (hour < 17) return 'Good afternoon.';
  return 'Good evening.';
}
