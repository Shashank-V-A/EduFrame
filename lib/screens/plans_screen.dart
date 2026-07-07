import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';
import '../widgets/plan_card.dart';
import 'plan_detail_screen.dart';
import 'plan_new_screen.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  List<LessonPlan> _plans = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plans = await DatabaseService.instance.getAllPlans();
    if (!mounted) return;
    setState(() => _plans = plans);
  }

  Future<void> _planTomorrow() async {
    final tomorrow = addDays(toDateString(DateTime.now()), 1);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlanNewScreen(initialDate: tomorrow)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final grouped = <String, List<LessonPlan>>{};
    for (final plan in _plans) {
      grouped.putIfAbsent(plan.planDate, () => []).add(plan);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          ScreenHeader(
            title: s.allPlans,
            subtitle: "Browse every lesson you've written — reuse and refine.",
          ),
          if (_plans.isEmpty)
            EmptyState(
              message: s.emptyNotebook,
              hint: s.startFromToday,
              actionLabel: s.planForTomorrow,
              onAction: _planTomorrow,
            )
          else
            ...grouped.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatDisplayDate(entry.key).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...entry.value.map(
                      (plan) => PlanCard(
                        plan: plan,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlanDetailScreen(planId: plan.id),
                            ),
                          );
                          await _load();
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
