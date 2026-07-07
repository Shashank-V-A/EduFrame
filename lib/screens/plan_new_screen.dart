import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/plan_draft.dart';
import '../services/database_service.dart';
import '../widgets/plan_form.dart';

class PlanNewScreen extends StatefulWidget {
  const PlanNewScreen({
    super.key,
    this.initialDate,
    this.draft,
  });

  final String? initialDate;
  final PlanDraft? draft;

  @override
  State<PlanNewScreen> createState() => _PlanNewScreenState();
}

class _PlanNewScreenState extends State<PlanNewScreen> {
  late PlanFormData _form;
  List<TeachingClass> _classes = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    _form = PlanFormData.empty(date: widget.initialDate ?? draft?.planDate);
    if (draft != null) {
      _form.classId = draft.classId;
      if (draft.planDate != null) _form.planDate = draft.planDate!;
      _form.topic = draft.topic;
      _form.objectives = draft.objectives;
      _form.activities = draft.activities;
      _form.homework = draft.homework;
      _form.materials = draft.materials;
      _form.notes = draft.notes;
    }
    _load();
  }

  Future<void> _load() async {
    final classes = await DatabaseService.instance.getAllClasses();
    if (!mounted) return;
    setState(() {
      _classes = classes;
      if (_form.classId == null && classes.length == 1) {
        _form.classId = classes.first.id;
      }
    });
  }

  Future<void> _save() async {
    if (_form.classId == null) {
      _snack('Choose which class this plan is for.');
      return;
    }
    if (_form.topic.trim().isEmpty) {
      _snack('Add a lesson topic so you can find it later.');
      return;
    }

    setState(() => _saving = true);
    try {
      final id = await DatabaseService.instance.createPlan(_form);
      if (!mounted) return;
      Navigator.pop(context, id);
    } catch (e) {
      _snack('Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New lesson plan')),
      body: PlanForm(
        data: _form,
        classes: _classes,
        onChanged: (data) => setState(() => _form = data),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving...' : 'Save lesson plan'),
          ),
        ),
      ),
    );
  }
}
