import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../models/models.dart';
import '../utils/class_display.dart';
import '../utils/date_utils.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan, required this.onTap});

  final LessonPlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Card(
      color: palette.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      plan.topic.isEmpty ? 'Untitled lesson' : plan.topic,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: palette.accentSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      lessonPlanClassLabel(plan),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${formatDisplayDate(plan.planDate)} · ${plan.subject}',
                style: TextStyle(fontSize: 13, color: palette.textSecondary),
              ),
              if (plan.objectives.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  plan.objectives,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: palette.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
