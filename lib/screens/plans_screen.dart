import 'package:flutter/material.dart';

import '../constants/theme.dart';
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
  bool _showSearch = false;
  String _query = '';
  List<LessonPlan> _searchResults = [];
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plans = await DatabaseService.instance.getAllPlans();
    if (!mounted) return;
    setState(() => _plans = plans);
    if (_query.isNotEmpty) await _search(_query);
  }

  Future<void> _search(String text) async {
    setState(() => _query = text);
    if (text.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searched = false;
      });
      return;
    }
    final found = await DatabaseService.instance.searchPlans(text);
    if (!mounted) return;
    setState(() {
      _searchResults = found;
      _searched = true;
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _query = '';
        _searchResults = [];
        _searched = false;
      }
    });
  }

  Future<void> _planTomorrow() async {
    final tomorrow = addDays(toDateString(DateTime.now()), 1);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlanNewScreen(initialDate: tomorrow)),
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

  Widget _buildGroupedPlans() {
    final grouped = <String, List<LessonPlan>>{};
    for (final plan in _plans) {
      grouped.putIfAbsent(plan.planDate, () => []).add(plan);
    }

    if (_plans.isEmpty) {
      final s = context.strings;
      return EmptyState(
        message: s.emptyNotebook,
        hint: s.startFromToday,
        actionLabel: s.planForTomorrow,
        onAction: _planTomorrow,
      );
    }

    return Column(
      children: grouped.entries.map((entry) {
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
                  onTap: () => _openPlan(plan.id),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchResults() {
    final s = context.strings;

    if (!_searched) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          s.plansSearchPrompt,
          style: TextStyle(color: AppPalette.of(context).textMuted, height: 1.4),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return EmptyState(
        message: s.plansSearchEmpty,
        hint: s.plansSearchEmptyHint,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _searchResults
            .map(
              (plan) => PlanCard(
                plan: plan,
                onTap: () => _openPlan(plan.id),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final palette = AppPalette.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 4, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.allPlans,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: palette.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.allPlansSubtitle,
                        style: TextStyle(
                          fontSize: 15,
                          color: palette.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: s.plansSearch,
                  onPressed: _toggleSearch,
                  icon: Icon(_showSearch ? Icons.close : Icons.search),
                ),
              ],
            ),
          ),
          if (_showSearch) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: s.plansSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _search(''),
                        ),
                ),
              ),
            ),
            _buildSearchResults(),
          ] else
            _buildGroupedPlans(),
        ],
      ),
    );
  }
}
