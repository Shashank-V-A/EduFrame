import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';
import '../widgets/plan_card.dart';
import 'plan_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<LessonPlan>>{};
    for (final plan in _plans) {
      grouped.putIfAbsent(plan.planDate, () => []).add(plan);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          const ScreenHeader(
            title: 'All plans',
            subtitle: "Browse every lesson you've written — reuse and refine.",
          ),
          if (_plans.isEmpty)
            const EmptyState(
              message: 'Your notebook is empty',
              hint: "Start with tomorrow's classes from the Today tab.",
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
                        color: AppColors.textSecondary,
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