import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../l10n/app_strings.dart';
import '../models/plan_draft.dart';
import '../services/groq_service.dart';
import '../utils/ai_result_parser.dart';
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
  bool _loading = false;
  String? _result;
  _AiTool? _lastTool;

  @override
  void dispose() {
    _topicController.dispose();
    _classController.dispose();
    _subjectController.dispose();
    super.dispose();
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

  PlanDraft _buildDraftFromResult() {
    final parsed = AiResultParser.parse(_result ?? '');
    final topic = _topicController.text.trim();
    final className = _classController.text.trim();
    final subject = _subjectController.text.trim();

    var draft = PlanDraft(
      topic: topic,
      notes: className.isNotEmpty ? 'Class: $className' : '',
    );

    switch (_lastTool) {
      case _AiTool.activities:
        draft = PlanDraft(
          topic: topic,
          activities: parsed.hasStructuredContent ? parsed.activities : _result ?? '',
          notes: draft.notes,
        );
      case _AiTool.homework:
        draft = PlanDraft(
          topic: topic,
          homework: parsed.hasStructuredContent ? parsed.homework : _result ?? '',
          notes: draft.notes,
        );
      case _AiTool.differentiation:
        draft = PlanDraft(
          topic: topic,
          notes: _result ?? '',
        );
      case _AiTool.explain:
        draft = PlanDraft(
          topic: topic,
          objectives: parsed.objectives.isNotEmpty ? parsed.objectives : _result ?? '',
          notes: '${subject.isNotEmpty ? 'Subject: $subject\n' : ''}${draft.notes}'.trim(),
        );
      case null:
        break;
    }

    return draft;
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
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ScreenHeader(
          title: s.aiTitle,
          subtitle: s.aiSubtitle,
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
                      hintText: 'e.g. Class 10-A',
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
