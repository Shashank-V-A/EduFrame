import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/common.dart';
import '../widgets/plan_card.dart';
import 'plan_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  List<LessonPlan> _results = [];
  bool _searched = false;

  Future<void> _search(String text) async {
    setState(() => _query = text);
    if (text.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    final found = await DatabaseService.instance.searchPlans(text);
    if (!mounted) return;
    setState(() {
      _results = found;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ScreenHeader(
          title: 'Search plans',
          subtitle: 'Find old plans by topic, activity, or homework.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: _search,
            decoration: const InputDecoration(
              hintText: 'Try "quadratic equations" or "group activity"',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _searched && _results.isEmpty
              ? const EmptyState(
                  message: 'No matching plans',
                  hint: 'Try a shorter keyword or different topic.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final plan = _results[index];
                    return PlanCard(
                      plan: plan,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlanDetailScreen(planId: plan.id),
                          ),
                        );
                        if (_query.isNotEmpty) await _search(_query);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
