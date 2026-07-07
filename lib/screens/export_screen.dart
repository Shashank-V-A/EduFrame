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
  int _matchCount = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final classes = await DatabaseService.instance.getAllClasses();
    final extent = await DatabaseService.instance.getPlanDateExtent();
    final today = toDateString(DateTime.now());
    final future = addDays(today, 30);

    String start = '${today.substring(0, 7)}-01';
    String end = future;

    if (extent.hasPlans) {
      start = extent.minDate ?? start;
      end = extent.maxDate ?? end;
      if (end.compareTo(today) < 0) end = future;
    }

    if (!mounted) return;
    setState(() {
      _classes = classes;
      _startController.text = start;
      _endController.text = end;
      _loaded = true;
    });
    await _refreshCount();
  }

  @override
  void dispose() {
    _teacherController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _refreshCount() async {
    final plans = await DatabaseService.instance.getPlansInRange(
      _startController.text.trim(),
      _endController.text.trim(),
      classId: _selectedClassId,
    );
    if (!mounted) return;
    setState(() => _matchCount = plans.length);
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
          'Lesson Plans - $classLabel (${_startController.text} to ${_endController.text})';

      await PdfService.exportPlans(
        plans: plans,
        title: title,
        teacherName: _teacherController.text.trim().isEmpty
            ? null
            : _teacherController.text.trim(),
      );

      if (plans.isEmpty && mounted) {
        _showSnack(
          'No plans in this date range. Try "All saved plans" or widen the end date.',
        );
      } else if (mounted) {
        _showSnack('Exported ${plans.length} lesson plan(s).');
      }
    } catch (e) {
      if (mounted) _showSnack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _useAllSavedPlans() async {
    final extent = await DatabaseService.instance.getPlanDateExtent();
    if (!extent.hasPlans) {
      _showSnack('No saved plans yet.');
      return;
    }
    setState(() {
      _startController.text = extent.minDate!;
      _endController.text = extent.maxDate!;
    });
    await _refreshCount();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const ScreenHeader(
          title: 'Export PDF',
          subtitle: 'Submit term plans to your HOD. Includes upcoming plans too.',
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _matchCount == 0
                          ? 'No plans match this date range yet.'
                          : '$_matchCount plan(s) will be included in the PDF.',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _useAllSavedPlans,
                    icon: const Icon(Icons.select_all),
                    label: const Text('Use all saved plans'),
                  ),
                  const SizedBox(height: 12),
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
                    onChanged: (_) => _refreshCount(),
                    decoration: const InputDecoration(
                      labelText: 'From date',
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _endController,
                    onChanged: (_) => _refreshCount(),
                    decoration: const InputDecoration(
                      labelText: 'To date',
                      hintText: 'YYYY-MM-DD (include future dates for tomorrow\'s plans)',
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
                        onSelected: (_) async {
                          setState(() => _selectedClassId = null);
                          await _refreshCount();
                        },
                      ),
                      ..._classes.map(
                        (cls) => ChoiceChip(
                          label: Text(cls.name),
                          selected: _selectedClassId == cls.id,
                          onSelected: (_) async {
                            setState(() => _selectedClassId = cls.id);
                            await _refreshCount();
                          },
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
            'Tip: If you used "Plan for tomorrow", make sure the end date includes that day.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
          ),
        ),
      ],
    );
  }
}
