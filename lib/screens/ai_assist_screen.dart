import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../models/plan_draft.dart';
import '../services/database_service.dart';
import '../services/groq_service.dart';
import '../utils/ai_result_parser.dart';
import '../utils/class_display.dart';
import '../widgets/common.dart';
import 'plan_new_screen.dart';

enum _AiTool { activities, homework, differentiation, explain }

class AiAssistScreen extends StatefulWidget {
  const AiAssistScreen({super.key});

  @override
  State<AiAssistScreen> createState() => _AiAssistScreenState();
}

class _AiAssistScreenState extends State<AiAssistScreen> {
  final _topicController = TextEditingController();
  final _classController = TextEditingController();
  final _subjectController = TextEditingController();
  List<TeachingClass> _classes = [];
  bool _loading = false;
  String? _result;
  _AiTool? _lastTool;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _classController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    final classes = await DatabaseService.instance.getAllClasses();
    if (mounted) setState(() => _classes = classes);
  }

  Future<void> _run(_AiTool tool, Future<String> Function() task) async {
    if (_topicController.text.trim().isEmpty) {
      _snack('Enter a topic first.');
      return;
    }
    setState(() {
      _loading = true;
      _result = null;
      _lastTool = tool;
    });
    try {
      final text = await task();
      setState(() => _result = text);
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  int? _matchClassId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();

    for (final cls in _classes) {
      final label = teachingClassLabel(cls).toLowerCase();
      if (label == lower) return cls.id;
      if (cls.name.toLowerCase() == lower) return cls.id;

      final section = cls.section.trim();
      if (section.isNotEmpty) {
        final variants = [
          '${cls.name}-$section',
          '${cls.name} $section',
          '${cls.name}-sec $section',
          '${cls.name} · sec $section',
          formatClassLabel(cls.name, section),
        ];
        for (final variant in variants) {
          if (variant.toLowerCase() == lower) return cls.id;
        }
      }
    }
    return null;
  }

  PlanDraft _buildDraftFromResult() {
    final result = _result ?? '';
    final parsed = AiResultParser.parse(result);
    final topic = _topicController.text.trim();
    final className = _classController.text.trim();
    final subject = _subjectController.text.trim();

    var objectives = parsed.objectives;
    var materials = parsed.materials;
    var activities = parsed.activities;
    var homework = parsed.homework;
    var notes = parsed.notes;

    if (!parsed.hasStructuredContent) {
      switch (_lastTool) {
        case _AiTool.activities:
          activities = result;
        case _AiTool.homework:
          homework = result;
        case _AiTool.differentiation:
          notes = result;
        case _AiTool.explain:
          objectives = result;
        case null:
          break;
      }
    }

    if (notes.isEmpty && _lastTool == _AiTool.differentiation) {
      notes = result;
    }

    final extraNotes = <String>[
      if (subject.isNotEmpty) 'Subject: $subject',
      if (className.isNotEmpty && _matchClassId(className) == null) 'Class: $className',
    ];
    if (extraNotes.isNotEmpty) {
      final prefix = extraNotes.join('\n');
      notes = notes.isEmpty ? prefix : '$prefix\n\n$notes';
    }

    return PlanDraft(
      classId: _matchClassId(className),
      topic: topic,
      objectives: objectives,
      materials: materials,
      activities: activities,
      homework: homework,
      notes: notes,
    );
  }

  Future<void> _createPlanWithAi() async {
    if (_result == null || _result!.isEmpty) return;
    final draft = _buildDraftFromResult();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlanNewScreen(draft: draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final palette = AppPalette.of(context);
    final className =
        _classController.text.trim().isEmpty ? 'Class' : _classController.text.trim();
    final subject =
        _subjectController.text.trim().isEmpty ? 'Subject' : _subjectController.text.trim();

    return ListView(
      children: [
        ScreenHeader(
          title: s.aiTitle,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _topicController,
                    decoration: const InputDecoration(
                      labelText: 'Topic',
                      hintText: 'e.g. Quadratic equations',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _classController,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      hintText: 'e.g. 2 · Sec B',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      hintText: 'e.g. Mathematics',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _toolButton(
          'Suggest activities',
          'Get a practical 40-minute lesson flow',
          Icons.lightbulb_outline,
          () => _run(
            _AiTool.activities,
            () => GroqService.instance.suggestActivities(
              topic: _topicController.text.trim(),
              className: className,
              subject: subject,
            ),
          ),
        ),
        _toolButton(
          'Suggest homework',
          'Specific exercises teachers can assign',
          Icons.assignment_outlined,
          () => _run(
            _AiTool.homework,
            () => GroqService.instance.suggestHomework(
              topic: _topicController.text.trim(),
              className: className,
              subject: subject,
            ),
          ),
        ),
        _toolButton(
          'Differentiation tips',
          'Help struggling and advanced students',
          Icons.people_outline,
          () => _run(
            _AiTool.differentiation,
            () => GroqService.instance.differentiationTips(
              topic: _topicController.text.trim(),
              className: className,
            ),
          ),
        ),
        _toolButton(
          'Explain topic simply',
          'How to teach this clearly tomorrow',
          Icons.school_outlined,
          () => _run(
            _AiTool.explain,
            () => GroqService.instance.explainTopicSimply(
              topic: _topicController.text.trim(),
              className: className,
              subject: subject,
            ),
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_result != null) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: palette.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(_result!, style: const TextStyle(height: 1.5)),
              ),
            ),
          ),
          if (_lastTool == _AiTool.activities)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: _createPlanWithAi,
                icon: const Icon(Icons.note_add_outlined),
                label: Text(s.createPlanWithAi),
              ),
            ),
        ],
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'AI assists your planning. Always review before teaching.',
            style: TextStyle(fontSize: 13, color: palette.textMuted, height: 1.4),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _toolButton(String title, String subtitle, IconData icon, VoidCallback onTap) {
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: palette.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: _loading ? null : onTap,
        ),
      ),
    );
  }
}
