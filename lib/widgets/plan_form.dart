import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../utils/class_display.dart';
import '../utils/date_utils.dart';

class PlanForm extends StatelessWidget {
  const PlanForm({
    super.key,
    required this.data,
    required this.classes,
    required this.onChanged,
  });

  final PlanFormData data;
  final List<TeachingClass> classes;
  final ValueChanged<PlanFormData> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final palette = AppPalette.of(context);
    final tomorrow = addDays(toDateString(DateTime.now()), 1);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(s.classLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: classes.map((cls) {
            final selected = data.classId == cls.id;
            return ChoiceChip(
              label: Text(teachingClassLabel(cls)),
              selected: selected,
              selectedColor: palette.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : palette.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (_) => onChanged(data..classId = cls.id),
            );
          }).toList(),
        ),
        if (classes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(s.addClassFirst, style: TextStyle(color: palette.textMuted, fontSize: 13)),
          ),
        const SizedBox(height: 16),
        Text(s.dateLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickDate(context),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.calendar_today_outlined),
            ),
            child: Text(formatDisplayDate(data.planDate)),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: Text(s.tomorrow),
              onPressed: () => onChanged(data..planDate = tomorrow),
            ),
            ActionChip(
              label: Text(s.nextMonday),
              onPressed: () => onChanged(data..planDate = nextMondayDate()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _field(s.topicLabel, data.topic, (v) => onChanged(data..topic = v),
            hint: 'e.g. Quadratic equations — introduction'),
        _area(s.objectivesLabel, data.objectives, (v) => onChanged(data..objectives = v),
            hint: 'What should students learn by the end of this period?'),
        _area(s.materialsLabel, data.materials, (v) => onChanged(data..materials = v),
            hint: 'Textbook pages, charts, worksheets...'),
        _area(s.activitiesLabel, data.activities, (v) => onChanged(data..activities = v),
            hint: 'Warm-up, explanation, board work, group activity...'),
        _area(s.homeworkLabel, data.homework, (v) => onChanged(data..homework = v),
            hint: 'Exercise numbers, reading, practice problems...'),
        _area(s.notesLabel, data.notes, (v) => onChanged(data..notes = v),
            hint: 'Reminders, differentiation ideas, improvements for next time...'),
        const SizedBox(height: 80),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final initial = parsePlanDate(data.planDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
      helpText: context.strings.pickDate,
    );
    if (picked != null) {
      onChanged(data..planDate = toDateString(picked));
    }
  }

  Widget _field(String label, String value, ValueChanged<String> onChanged, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value,
            onChanged: onChanged,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }

  Widget _area(String label, String value, ValueChanged<String> onChanged, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value,
            onChanged: onChanged,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(hintText: hint, alignLabelWithHint: true),
          ),
        ],
      ),
    );
  }
}
