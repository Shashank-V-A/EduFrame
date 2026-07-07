/// Optional prefill when opening the plan editor from AI or timetable.
class PlanDraft {
  const PlanDraft({
    this.classId,
    this.planDate,
    this.topic = '',
    this.objectives = '',
    this.activities = '',
    this.homework = '',
    this.materials = '',
    this.notes = '',
  });

  final int? classId;
  final String? planDate;
  final String topic;
  final String objectives;
  final String activities;
  final String homework;
  final String materials;
  final String notes;

  bool get isEmpty =>
      classId == null &&
      planDate == null &&
      topic.isEmpty &&
      objectives.isEmpty &&
      activities.isEmpty &&
      homework.isEmpty &&
      materials.isEmpty &&
      notes.isEmpty;
}
