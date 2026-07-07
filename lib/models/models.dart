import '../utils/date_utils.dart';

class TeachingClass {
  final int id;
  final String name;
  final String subject;
  final String section;
  final String createdAt;

  const TeachingClass({
    required this.id,
    required this.name,
    required this.subject,
    required this.section,
    required this.createdAt,
  });

  factory TeachingClass.fromMap(Map<String, Object?> map) {
    return TeachingClass(
      id: map['id'] as int,
      name: map['name'] as String,
      subject: map['subject'] as String? ?? '',
      section: map['section'] as String? ?? '',
      createdAt: map['created_at'] as String,
    );
  }
}

class LessonPlan {
  final int id;
  final int classId;
  final String planDate;
  final String topic;
  final String objectives;
  final String activities;
  final String homework;
  final String materials;
  final String notes;
  final String createdAt;
  final String updatedAt;
  final String className;
  final String subject;
  final String section;

  const LessonPlan({
    required this.id,
    required this.classId,
    required this.planDate,
    required this.topic,
    required this.objectives,
    required this.activities,
    required this.homework,
    required this.materials,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.className,
    required this.subject,
    required this.section,
  });

  factory LessonPlan.fromMap(Map<String, Object?> map) {
    return LessonPlan(
      id: map['id'] as int,
      classId: map['class_id'] as int,
      planDate: map['plan_date'] as String,
      topic: map['topic'] as String,
      objectives: map['objectives'] as String? ?? '',
      activities: map['activities'] as String? ?? '',
      homework: map['homework'] as String? ?? '',
      materials: map['materials'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      className: map['class_name'] as String,
      subject: map['subject'] as String? ?? '',
      section: map['section'] as String? ?? '',
    );
  }
}

class TimetableSlot {
  final int id;
  final int? classId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String room;
  final String className;
  final String subject;

  const TimetableSlot({
    required this.id,
    this.classId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.className,
    required this.subject,
  });

  factory TimetableSlot.fromMap(Map<String, Object?> map) {
    return TimetableSlot(
      id: map['id'] as int,
      classId: map['class_id'] as int?,
      dayOfWeek: map['day_of_week'] as int,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      room: map['room'] as String? ?? '',
      className: map['class_name'] as String? ?? 'Free period',
      subject: map['subject'] as String? ?? '',
    );
  }

  String get dayLabel => dayNames[dayOfWeek] ?? 'Day $dayOfWeek';
}

class PlanFormData {
  int? classId;
  String planDate;
  String topic;
  String objectives;
  String activities;
  String homework;
  String materials;
  String notes;

  PlanFormData({
    this.classId,
    required this.planDate,
    this.topic = '',
    this.objectives = '',
    this.activities = '',
    this.homework = '',
    this.materials = '',
    this.notes = '',
  });

  factory PlanFormData.empty({String? date}) {
    return PlanFormData(
      planDate: date ?? toDateString(DateTime.now()),
    );
  }

  factory PlanFormData.fromPlan(LessonPlan plan) {
    return PlanFormData(
      classId: plan.classId,
      planDate: plan.planDate,
      topic: plan.topic,
      objectives: plan.objectives,
      activities: plan.activities,
      homework: plan.homework,
      materials: plan.materials,
      notes: plan.notes,
    );
  }
}

class PlanDateExtent {
  final String? minDate;
  final String? maxDate;
  final int count;

  const PlanDateExtent({this.minDate, this.maxDate, this.count = 0});

  bool get hasPlans => count > 0;
}

const dayNames = {
  1: 'Monday',
  2: 'Tuesday',
  3: 'Wednesday',
  4: 'Thursday',
  5: 'Friday',
  6: 'Saturday',
  7: 'Sunday',
};
