import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../utils/date_utils.dart';
import '../widgets/app_logo.dart';
import '../widgets/common.dart';
import '../widgets/plan_card.dart';
import 'plan_detail_screen.dart';
import 'plan_new_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  List<LessonPlan> _todayPlans = [];
  List<LessonPlan> _tomorrowPlans = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final today = toDateString(DateTime.now());
      final tomorrow = addDays(today, 1);
      final results = await Future.wait([
        DatabaseService.instance.getPlansForDate(today),
        DatabaseService.instance.getPlansForDate(tomorrow),
      ]);
      if (!mounted) return;
      setState(() {
        _todayPlans = results[0];
        _tomorrowPlans = results[1];
      });
    } catch (e) {
      debugPrint('Failed to load plans: $e');
    }
  }

  Future<void> _openNew(String date) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlanNewScreen(initialDate: date)),
    );
    await _load();
  }

  Future<void> _openPlan(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlanDetailScreen(planId: id)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final today = toDateString(DateTime.now());
    final tomorrow = addDays(today, 1);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppLogo(size: 52, borderRadius: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final palette = AppPalette.of(context);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.appTitle,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: palette.primary,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.greetingSubtitle(greeting()),
                            style: TextStyle(
                              fontSize: 15,
                              color: palette.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openNew(tomorrow),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(s.planForTomorrow),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openNew(today),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(s.planForToday),
                  ),
                ),
              ],
            ),
          ),
          _section(
            'Tomorrow · ${formatDisplayDate(tomorrow)}',
            _tomorrowPlans,
            s.noPlansTomorrow,
            s.noPlansTomorrowHint,
            s.planNow,
            () => _openNew(tomorrow),
          ),
          _section(
            'Today · ${formatDisplayDate(today)}',
            _todayPlans,
            s.nothingToday,
            s.addPlanToday,
            s.planNow,
            () => _openNew(today),
          ),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    List<LessonPlan> plans,
    String empty,
    String hint,
    String actionLabel,
    VoidCallback onAction,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (plans.isEmpty)
            EmptyState(
              message: empty,
              hint: hint,
              actionLabel: actionLabel,
              onAction: onAction,
            )
          else
            ...plans.map(
              (plan) => PlanCard(plan: plan, onTap: () => _openPlan(plan.id)),
            ),
        ],
      ),
    );
  }
}
