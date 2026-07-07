import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/models.dart';
import '../utils/class_display.dart';
import '../utils/date_utils.dart';
import 'database_service.dart';
import 'settings_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;

    tz_data.initializeTimeZones();
    final timeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone.identifier));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _plugin.initialize(settings: initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _ready = true;
  }

  Future<void> requestPermissions() async {
    await Permission.notification.request();
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  Future<void> rescheduleFromDatabase() async {
    if (!await SettingsService.instance.notificationsEnabled()) {
      await _plugin.cancelAll();
      return;
    }

    await init();
    await requestPermissions();
    await _plugin.cancelAll();

    final slots = await DatabaseService.instance.getAllTimetableSlots();
    if (slots.isEmpty) return;

    final now = DateTime.now();
    var notificationId = 1000;

    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
      final daySlots = slots.where((s) => s.dayOfWeek == date.weekday).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      for (var i = 0; i < daySlots.length; i++) {
        final slot = daySlots[i];
        final start = _combine(date, slot.startTime);
        final remindAt = start.subtract(const Duration(minutes: 5));

        if (remindAt.isAfter(now)) {
          await _schedule(
            id: notificationId++,
            when: remindAt,
            title: 'Class in 5 minutes',
            body: '${timetableSlotLabel(slot)} (${slot.subject}) at ${formatTime12h(slot.startTime)}'
                '${slot.room.isNotEmpty ? ' - Room ${slot.room}' : ''}',
          );
        }

        if (i < daySlots.length - 1) {
          final end = _combine(date, slot.endTime);
          final next = daySlots[i + 1];
          final gapMinutes = _combine(date, next.startTime).difference(end).inMinutes;

          if (gapMinutes >= 15 && end.isAfter(now)) {
            await _schedule(
              id: notificationId++,
              when: end,
              title: 'Free period',
              body: 'Next class: ${timetableSlotLabel(next)} at ${formatTime12h(next.startTime)}',
            );
          }
        } else {
          final end = _combine(date, slot.endTime);
          if (end.isAfter(now)) {
            final tomorrowSlots = _nextDayFirstSlot(slots, date.weekday);
            if (tomorrowSlots != null) {
              await _schedule(
                id: notificationId++,
                when: end,
                title: 'No more classes today',
                body: 'Next class: ${timetableSlotLabel(tomorrowSlots)} on ${tomorrowSlots.dayLabel} at ${formatTime12h(tomorrowSlots.startTime)}',
              );
            }
          }
        }
      }
    }
  }

  TimetableSlot? _nextDayFirstSlot(List<TimetableSlot> slots, int fromWeekday) {
    for (var offset = 1; offset <= 7; offset++) {
      final day = ((fromWeekday - 1 + offset) % 7) + 1;
      final daySlots = slots.where((s) => s.dayOfWeek == day).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      if (daySlots.isNotEmpty) return daySlots.first;
    }
    return null;
  }

  DateTime _combine(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Future<void> _schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    final scheduled = tz.TZDateTime.from(when, tz.local);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'eduframe_timetable',
          'Class reminders',
          channelDescription: 'Reminders before classes and free-period updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
