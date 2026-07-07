import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../models/models.dart';

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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Class *', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: classes.map((cls) {
            final selected = data.classId == cls.id;
            return ChoiceChip(
              label: Text(cls.name),
              selected: selected,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (_) => onChanged(data..classId = cls.id),
            );
          }).toList(),
        ),
        if (classes.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Add a class first from More > Classes.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
        const SizedBox(height: 16),
        _field('Date *', data.planDate, (v) => onChanged(data..planDate = v)),
        _field(
          'Topic / lesson title *',
          data.topic,
          (v) => onChanged(data..topic = v),
          hint: 'e.g. Quadratic equations — introduction',
        ),
        _area(
          'Learning objectives',
          data.objectives,
          (v) => onChanged(data..objectives = v),
          hint: 'What should students learn by the end of this period?',
        ),
        _area(
          'Materials / resources',
          data.materials,
          (v) => onChanged(data..materials = v),
          hint: 'Textbook pages, charts, worksheets...',
        ),
        _area(
          'Activities & teaching procedure',
          data.activities,
          (v) => onChanged(data..activities = v),
          hint: 'Warm-up, explanation, board work, group activity...',
        ),
        _area(
          'Homework / assignment',
          data.homework,
          (v) => onChanged(data..homework = v),
          hint: 'Exercise numbers, reading, practice problems...',
        ),
        _area(
          'Teacher notes',
          data.notes,
          (v) => onChanged(data..notes = v),
          hint: 'Reminders, differentiation ideas, improvements for next time...',
        ),
        const SizedBox(height: 80),
      ],
    );
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
