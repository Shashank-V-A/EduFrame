import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../utils/date_utils.dart';

class ShareService {
  ShareService._();
  static final ShareService instance = ShareService._();

  String formatPlanText(LessonPlan plan) {
    final buffer = StringBuffer()
      ..writeln('EduFrame - Lesson Plan')
      ..writeln('${formatDisplayDate(plan.planDate)} | ${plan.className} | ${plan.subject}')
      ..writeln()
      ..writeln('Topic: ${plan.topic}');

    void section(String title, String value) {
      if (value.trim().isEmpty) return;
      buffer
        ..writeln()
        ..writeln('$title:')
        ..writeln(value.trim());
    }

    section('Objectives', plan.objectives);
    section('Materials', plan.materials);
    section('Activities', plan.activities);
    section('Homework', plan.homework);
    section('Notes', plan.notes);

    return buffer.toString().trim();
  }

  Future<void> sharePlan(LessonPlan plan) async {
    await SharePlus.instance.share(
      ShareParams(text: formatPlanText(plan), subject: plan.topic),
    );
  }

  Future<void> sharePlanWhatsApp(LessonPlan plan) async {
    await SharePlus.instance.share(
      ShareParams(text: formatPlanText(plan), subject: plan.topic),
    );
  }
}
