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
        className: lessonPlanClassLabel(plan),
        subject: plan.subject,
        objectives: plan.objectives,
        materials: plan.materials,
        activities: plan.activities,
        homework: plan.homework,
        notes: plan.notes,
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
              if (parsed.materials.isNotEmpty)
                OutlinedButton(
                  onPressed: () {
                    _applyAiField(materials: parsed.materials);
                    Navigator.pop(context);
                  },
                  child: Text(s.applyMaterials),
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
              if (parsed.notes.isNotEmpty)
                OutlinedButton(
                  onPressed: () {
                    _applyAiField(notes: parsed.notes);
                    Navigator.pop(context);
                  },
                  child: Text(s.applyNotes),
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
                    materials: parsed.materials.isNotEmpty ? parsed.materials : null,
                    activities: parsed.activities.isNotEmpty ? parsed.activities : null,
                    homework: parsed.homework.isNotEmpty ? parsed.homework : null,
                    notes: parsed.notes.isNotEmpty
                        ? parsed.notes
                        : (!parsed.hasStructuredContent ? fullText : null),
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
    String? materials,
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
      if (materials != null && materials.isNotEmpty) {
        form.materials = _mergeField(form.materials, materials);
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

  Future<void> _sharePlan() async {
    final plan = _plan;
    if (plan == null) return;
    try {
      await ShareService.instance.sharePlan(plan);
    } catch (e) {
      _snack('Could not share plan: $e');
    }
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
    final plan = _plan;
    if (plan == null) return;

    final tomorrow = addDays(toDateString(DateTime.now()), 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: parsePlanDate(tomorrow),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
      helpText: context.strings.duplicatePickDate,
    );
    if (picked == null) return;

    final newDate = toDateString(picked);
    try {
      final newId = await DatabaseService.instance.duplicatePlan(
        widget.planId,
        newDate: newDate,
      );
      if (!mounted) return;
      _snack(context.strings.duplicateSuccess(formatDisplayDate(newDate)));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PlanDetailScreen(planId: newId)),
      );
    } catch (e) {
      _snack('Could not duplicate: $e');
    }
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
          const SizedBox(height: 20),
          _actionPanel(s, palette),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _actionPanel(AppStrings s, AppPalette palette) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _actionTile(
                    icon: Icons.ios_share_rounded,
                    label: s.sharePlan,
                    palette: palette,
                    onTap: _sharePlan,
                  ),
                ),
                Expanded(
                  child: _actionTile(
                    icon: Icons.smart_toy_outlined,
                    label: s.aiImprovePlan,
                    palette: palette,
                    onTap: _saving ? null : _aiImprove,
                  ),
                ),
                Expanded(
                  child: _actionTile(
                    icon: Icons.copy_all_outlined,
                    label: s.duplicatePlan,
                    palette: palette,
                    onTap: _duplicate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.icon(
                onPressed: () => setState(() => _editing = true),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(s.editPlan),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _delete,
              style: TextButton.styleFrom(
                foregroundColor: palette.danger,
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              child: Text(s.deletePlan),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required AppPalette palette,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: palette.primary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
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
