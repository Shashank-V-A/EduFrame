import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/common.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _sectionController = TextEditingController();
  List<TeachingClass> _classes = [];
  int? _editingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final classes = await DatabaseService.instance.getAllClasses();
    if (!mounted) return;
    setState(() => _classes = classes);
  }

  void _resetForm() {
    _nameController.clear();
    _subjectController.clear();
    _sectionController.clear();
    setState(() => _editingId = null);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Enter a class name like "Class 8-A".');
      return;
    }

    if (_editingId != null) {
      await DatabaseService.instance.updateClass(
        _editingId!,
        name,
        _subjectController.text,
        _sectionController.text,
      );
    } else {
      await DatabaseService.instance.createClass(
        name,
        _subjectController.text,
        _sectionController.text,
      );
    }

    _resetForm();
    await _load();
  }

  void _startEdit(TeachingClass cls) {
    setState(() {
      _editingId = cls.id;
      _nameController.text = cls.name;
      _subjectController.text = cls.subject;
      _sectionController.text = cls.section;
    });
  }

  Future<void> _confirmDelete(TeachingClass cls) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${cls.name}?'),
        content: const Text('All lesson plans for this class will also be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await DatabaseService.instance.deleteClass(cls.id);
      if (_editingId == cls.id) _resetForm();
      await _load();
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const ScreenHeader(
            title: 'Classes',
            subtitle: 'Set up the classes you teach. Edit these anytime.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingId != null ? 'Edit class' : 'Add a class',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: 'Class name (e.g. Class 10-A)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _subjectController,
                      decoration: const InputDecoration(hintText: 'Subject (e.g. Mathematics)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _sectionController,
                      decoration: const InputDecoration(hintText: 'Section (optional)'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(_editingId != null ? 'Save changes' : 'Add class'),
                      ),
                    ),
                    if (_editingId != null)
                      TextButton(onPressed: _resetForm, child: const Text('Cancel')),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('Your classes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          ..._classes.map((cls) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  title: Text(cls.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    [cls.subject, cls.section].where((s) => s.isNotEmpty).join(' · ').isEmpty
                        ? 'No subject set'
                        : [cls.subject, cls.section].where((s) => s.isNotEmpty).join(' · '),
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      TextButton(onPressed: () => _startEdit(cls), child: const Text('Edit')),
                      TextButton(
                        onPressed: () => _confirmDelete(cls),
                        child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
