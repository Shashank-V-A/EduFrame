import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/groq_service.dart';
import '../services/share_service.dart';
import '../utils/ai_result_parser.dart';
import '../utils/class_display.dart';
import '../utils/date_utils.dart';
import '../widgets/plan_form.dart';
class PlanDetailScreen extends StatefulWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final int planId;

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  LessonPlan? _plan;
  PlanFormData? _form;
  List<TeachingClass> _classes = [];
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      DatabaseService.instance.getPlanById(widget.planId),
      DatabaseService.instance.getAllClasses(),
    ]);
    if (!mounted) return;
    final plan = results[0] as LessonPlan?;
    if (plan == null) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _plan = plan;
      _form = PlanFormData.fromPlan(plan);
      _classes = results[1] as List<TeachingClass>;
    });
  }

  Future<void> _aiImprove() async {
    final plan = _plan;
    if (plan == null) return;

    setState(() => _saving = true);
    try {
      final result = await GroqService.instance.improveLessonPlan(
        topic: plan.topic,
        className: plan.className,
        subject: plan.subject,
        objectives: plan.objectives,
        activities: plan.activities,
        homework: plan.homework,
      );
      if (!mounted) return;
      final parsed = AiResultParser.parse(result);
      await _showAiApplyDialog(parsed, fullText: result);
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showAiApplyDialog(AiParsedSections parsed, {required String fullText}) async {
    final s = context.strings;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI suggestions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SelectableText(
                parsed.hasStructuredContent ? fullText : fullText,
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 16),
              if (parsed.objectives.isNotEmpty)
                OutlinedButton(
                  onPressed: () {
                    _applyAiField(objectives: parsed.objectives);
                    Navigator.pop(context);
                  },
                  child: Text(s.applyObjectives),
                ),
              if (parsed.activities.isNotEmpty)
                OutlinedButton(
                  onPressed: () {
                    _applyAiField(activities: parsed.activities);
                    Navigator.pop(context);
                  },
                  child: Text(s.applyActivities),
                ),
              if (parsed.homework.isNotEmpty)
                OutlinedButton(
                  onPressed: () {
                    _applyAiField(homework: parsed.homework);
                    Navigator.pop(context);
                  },
                  child: Text(s.applyHomework),
                ),
              if (!parsed.hasStructuredContent)
                OutlinedButton(
                  onPressed: () {
                    _applyAiField(notes: fullText);
                    Navigator.pop(context);
                  },
                  child: Text(s.applyNotes),
                ),
              ElevatedButton(
                onPressed: () {
                  _applyAiField(
                    objectives: parsed.objectives.isNotEmpty ? parsed.objectives : null,
                    activities: parsed.activities.isNotEmpty ? parsed.activities : null,
                    homework: parsed.homework.isNotEmpty ? parsed.homework : null,
                    notes: !parsed.hasStructuredContent ? fullText : null,
                  );
                  Navigator.pop(context);
                },
                child: Text(s.useInPlan),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _applyAiField({
    String? objectives,
    String? activities,
    String? homework,
    String? notes,
  }) {
    final form = _form;
    if (form == null) return;

    setState(() {
      if (objectives != null && objectives.isNotEmpty) {
        form.objectives = _mergeField(form.objectives, objectives);
      }
      if (activities != null && activities.isNotEmpty) {
        form.activities = _mergeField(form.activities, activities);
      }
      if (homework != null && homework.isNotEmpty) {
        form.homework = _mergeField(form.homework, homework);
      }
      if (notes != null && notes.isNotEmpty) {
        form.notes = _mergeField(form.notes, notes);
      }
      _editing = true;
    });
    _snack('Applied to plan. Review and save.');
  }

  String _mergeField(String existing, String incoming) {
    if (existing.trim().isEmpty) return incoming.trim();
    return '${existing.trim()}\n\n$incoming'.trim();
  }

  Future<void> _save() async {
    final form = _form;
    if (form == null) return;
    if (form.classId == null || form.topic.trim().isEmpty) {
      _snack('Class and topic are required.');
      return;
    }

    setState(() => _saving = true);
    try {
      await DatabaseService.instance.updatePlan(widget.planId, form);
      setState(() => _editing = false);
      await _load();
    } catch (e) {
      _snack('Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _duplicate() async {
    final tomorrow = addDays(toDateString(DateTime.now()), 1);
    final newId = await DatabaseService.instance.duplicatePlan(
      widget.planId,
      newDate: tomorrow,
    );
    if (!mounted) return;
    _snack('Copied for ${formatDisplayDate(tomorrow)}.');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PlanDetailScreen(planId: newId)),
    );
  }

  Future<void> _delete() async {
    final palette = AppPalette.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this plan?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: palette.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseService.instance.deletePlan(widget.planId);
      if (mounted) Navigator.pop(context);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final palette = AppPalette.of(context);

    if (_plan == null || _form == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_editing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit lesson plan')),
        body: PlanForm(
          data: _form!,
          classes: _classes,
          onChanged: (data) => setState(() => _form = data),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving...' : 'Save changes'),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _editing = false;
                    _form = PlanFormData.fromPlan(_plan!);
                  }),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final plan = _plan!;
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson plan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: palette.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.topic,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatDisplayDate(plan.planDate)} · ${lessonPlanClassLabel(plan)} · ${plan.subject}',
                    style: TextStyle(color: palette.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          _block('Learning objectives', plan.objectives, palette),
          _block('Materials / resources', plan.materials, palette),
          _block('Activities & procedure', plan.activities, palette),
          _block('Homework / assignment', plan.homework, palette),
          _block('Teacher notes', plan.notes, palette),
          Text(
            'Last updated ${DateTime.parse(plan.updatedAt).toLocal()}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: palette.textMuted),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => ShareService.instance.sharePlan(plan),
            icon: const Icon(Icons.share_outlined),
            label: Text(s.sharePlan),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _saving ? null : _aiImprove,
            icon: const Icon(Icons.smart_toy_outlined),
            label: const Text('AI: Improve this plan'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => setState(() => _editing = true),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit plan'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _duplicate,
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Duplicate for another day'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _delete,
            style: ElevatedButton.styleFrom(backgroundColor: palette.danger),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _block(String title, String value, AppPalette palette) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 15, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
