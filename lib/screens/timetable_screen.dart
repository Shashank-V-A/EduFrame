import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  List<TimetableSlot> _slots = [];
  List<TeachingClass> _classes = [];
  int _selectedDay = DateTime.now().weekday;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      DatabaseService.instance.getAllTimetableSlots(),
      DatabaseService.instance.getAllClasses(),
    ]);
    if (!mounted) return;
    setState(() {
      _slots = results[0] as List<TimetableSlot>;
      _classes = results[1] as List<TeachingClass>;
    });
  }

  List<TimetableSlot> get _daySlots =>
      _slots.where((s) => s.dayOfWeek == _selectedDay).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

  Future<void> _addOrEditSlot({TimetableSlot? existing}) async {
    int? classId = existing?.classId;
    TimeOfDay start = _parseTime(existing?.startTime ?? '09:00');
    TimeOfDay end = _parseTime(existing?.endTime ?? '09:45');
    final roomController = TextEditingController(text: existing?.room ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add period' : 'Edit period'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int?>(
                  initialValue: classId,
                  decoration: const InputDecoration(labelText: 'Class (optional)'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Free / break')),
                    ..._classes.map(
                      (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => classId = v),
                ),
                ListTile(
                  title: const Text('Start time'),
                  subtitle: Text(_formatTimeOfDay(start)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: start);
                    if (picked != null) setDialogState(() => start = picked);
                  },
                ),
                ListTile(
                  title: const Text('End time'),
                  subtitle: Text(_formatTimeOfDay(end)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: end);
                    if (picked != null) setDialogState(() => end = picked);
                  },
                ),
                TextField(
                  controller: roomController,
                  decoration: const InputDecoration(labelText: 'Room (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final startStr = _formatTimeOfDay(start);
    final endStr = _formatTimeOfDay(end);

    if (existing == null) {
      await DatabaseService.instance.createTimetableSlot(
        classId: classId,
        dayOfWeek: _selectedDay,
        startTime: startStr,
        endTime: endStr,
        room: roomController.text,
      );
    } else {
      await DatabaseService.instance.updateTimetableSlot(
        id: existing.id,
        classId: classId,
        dayOfWeek: _selectedDay,
        startTime: startStr,
        endTime: endStr,
        room: roomController.text,
      );
    }

    await NotificationService.instance.rescheduleFromDatabase();
    await _load();
  }

  Future<void> _deleteSlot(TimetableSlot slot) async {
    await DatabaseService.instance.deleteTimetableSlot(slot.id);
    await NotificationService.instance.rescheduleFromDatabase();
    await _load();
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ScreenHeader(
          title: 'Timetable',
          subtitle: 'Weekly schedule with 5-minute class reminders.',
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: List.generate(7, (index) {
              final day = index + 1;
              final selected = day == _selectedDay;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(dayNames[day]!.substring(0, 3)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedDay = day),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _daySlots.isEmpty
                ? ListView(
                    children: const [
                      EmptyState(
                        message: 'No periods for this day',
                        hint: 'Add your school periods to get reminders before each class.',
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _daySlots.length,
                    itemBuilder: (context, index) {
                      final slot = _daySlots[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(slot.className, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            '${formatTime12h(slot.startTime)} - ${formatTime12h(slot.endTime)}'
                            '${slot.subject.isNotEmpty ? ' | ${slot.subject}' : ''}'
                            '${slot.room.isNotEmpty ? ' | Room ${slot.room}' : ''}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _addOrEditSlot(existing: slot);
                              } else if (value == 'delete') {
                                _deleteSlot(slot);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _addOrEditSlot(),
              icon: const Icon(Icons.add),
              label: Text('Add period (${dayNames[_selectedDay]})'),
            ),
          ),
        ),
      ],
    );
  }
}
