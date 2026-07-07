import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../services/groq_service.dart';
import '../widgets/common.dart';

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

  @override
  void dispose() {
    _topicController.dispose();
    _classController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String> Function() task) async {
    if (_topicController.text.trim().isEmpty) {
      _snack('Enter a topic first.');
      return;
    }
    setState(() {
      _loading = true;
      _result = null;
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const ScreenHeader(
          title: 'AI Assist',
          subtitle: 'Groq-powered help that supports your planning - you stay in control.',
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
          () => _run(() => GroqService.instance.suggestActivities(
                topic: _topicController.text.trim(),
                className: _classController.text.trim().isEmpty ? 'Class' : _classController.text.trim(),
                subject: _subjectController.text.trim().isEmpty ? 'Subject' : _subjectController.text.trim(),
              )),
        ),
        _toolButton(
          'Suggest homework',
          'Specific exercises teachers can assign',
          Icons.assignment_outlined,
          () => _run(() => GroqService.instance.suggestHomework(
                topic: _topicController.text.trim(),
                className: _classController.text.trim().isEmpty ? 'Class' : _classController.text.trim(),
                subject: _subjectController.text.trim().isEmpty ? 'Subject' : _subjectController.text.trim(),
              )),
        ),
        _toolButton(
          'Differentiation tips',
          'Help struggling and advanced students',
          Icons.people_outline,
          () => _run(() => GroqService.instance.differentiationTips(
                topic: _topicController.text.trim(),
                className: _classController.text.trim().isEmpty ? 'Class' : _classController.text.trim(),
              )),
        ),
        _toolButton(
          'Explain topic simply',
          'How to teach this clearly tomorrow',
          Icons.school_outlined,
          () => _run(() => GroqService.instance.explainTopicSimply(
                topic: _topicController.text.trim(),
                className: _classController.text.trim().isEmpty ? 'Class' : _classController.text.trim(),
                subject: _subjectController.text.trim().isEmpty ? 'Subject' : _subjectController.text.trim(),
              )),
        ),
        if (_loading) const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        if (_result != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(_result!, style: const TextStyle(height: 1.5)),
              ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'AI assists your planning. Always review before teaching. Add your Groq API key in More > Settings.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _toolButton(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: _loading ? null : onTap,
        ),
      ),
    );
  }
}
