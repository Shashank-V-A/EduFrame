import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _teacherController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  List<TeachingClass> _classes = [];
  int? _selectedClassId;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final today = toDateString(DateTime.now());
    _startController.text = '${today.substring(0, 7)}-01';
    _endController.text = today;
    _loadClasses();
  }

  @override
  void dispose() {
    _teacherController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    final classes = await DatabaseService.instance.getAllClasses();
    if (!mounted) return;
    setState(() => _classes = classes);
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final plans = await DatabaseService.instance.getPlansInRange(
        _startController.text.trim(),
        _endController.text.trim(),
        classId: _selectedClassId,
      );

      final classLabel = _selectedClassId == null
          ? 'All classes'
          : _classes.firstWhere((c) => c.id == _selectedClassId).name;

      final title =
          'Lesson Plans — $classLabel (${_startController.text} to ${_endController.text})';

      await PdfService.exportPlans(
        plans: plans,
        title: title,
        teacherName: _teacherController.text.trim().isEmpty
            ? null
            : _teacherController.text.trim(),
      );

      if (plans.isEmpty && mounted) {
        _showSnack('PDF created, but no plans were found in this date range.');
      }
    } catch (e) {
      if (mounted) _showSnack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const ScreenHeader(
          title: 'Export PDF',
          subtitle: 'Submit term plans to your HOD — clean, readable, professional.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _teacherController,
                    decoration: const InputDecoration(
                      labelText: 'Teacher name (optional)',
                      hintText: 'Appears on the cover page',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _startController,
                    decoration: const InputDecoration(
                      labelText: 'From date',
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _endController,
                    decoration: const InputDecoration(
                      labelText: 'To date',
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Class filter', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All classes'),
                        selected: _selectedClassId == null,
                        onSelected: (_) => setState(() => _selectedClassId = null),
                      ),
                      ..._classes.map(
                        (cls) => ChoiceChip(
                          label: Text(cls.name),
                          selected: _selectedClassId == cls.id,
                          onSelected: (_) => setState(() => _selectedClassId = cls.id),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _exporting ? null : _export,
                      icon: const Icon(Icons.share_outlined),
                      label: Text(_exporting ? 'Creating PDF...' : 'Export & share PDF'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Tip: Set the date range to a full term (e.g. April–September) before HOD submission.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
          ),
        ),
      ],
    );
  }
}
