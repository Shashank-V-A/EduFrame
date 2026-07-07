import '../models/models.dart';

/// e.g. "10 · Sec A"
String formatClassLabel(String name, String section) {
  final trimmedSection = section.trim();
  if (trimmedSection.isEmpty) return name;
  return '$name · Sec $trimmedSection';
}

String teachingClassLabel(TeachingClass cls) => formatClassLabel(cls.name, cls.section);

String teachingClassWithSubject(TeachingClass cls) {
  final label = teachingClassLabel(cls);
  final subject = cls.subject.trim();
  if (subject.isEmpty) return label;
  return '$label · $subject';
}

String lessonPlanClassLabel(LessonPlan plan) =>
    formatClassLabel(plan.className, plan.section);

String timetableSlotLabel(TimetableSlot slot) =>
    formatClassLabel(slot.className, slot.section);
