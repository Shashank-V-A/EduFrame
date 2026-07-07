import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';
import '../utils/date_utils.dart';

class PdfService {
  static Future<void> exportPlans({
    required List<LessonPlan> plans,
    required String title,
    String? teacherName,
  }) async {
    final doc = pw.Document();
    final safeTitle = pdfSafe(title);

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(40)),
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                safeTitle,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#2C4A6E'),
                ),
              ),
              if (teacherName != null && teacherName.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 6),
                  child: pw.Text(
                    'Prepared by ${pdfSafe(teacherName)}',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4, bottom: 16),
                child: pw.Text(
                  'Generated from EduFrame | ${pdfSafe(DateTime.now().toLocal().toString())}',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                ),
              ),
              pw.Divider(color: PdfColor.fromHex('#2C4A6E'), thickness: 2),
            ],
          ),
          if (plans.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 24),
              child: pw.Text(
                'No lesson plans found for this period.',
                style: pw.TextStyle(
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600,
                ),
              ),
            )
          else
            ...plans.map(_planSection),
          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Text(
              'EduFrame - your plans, organized.',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: 'eduframe-lesson-plans.pdf');
  }

  static pw.Widget _planSection(LessonPlan plan) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            pdfSafe(plan.topic),
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            pdfSafe(
              '${formatDisplayDate(plan.planDate)} | ${plan.className} | ${plan.subject}',
            ),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 10),
          if (plan.objectives.isNotEmpty) _field('Learning objectives', plan.objectives),
          if (plan.materials.isNotEmpty) _field('Materials / resources', plan.materials),
          if (plan.activities.isNotEmpty) _field('Activities & procedure', plan.activities),
          if (plan.homework.isNotEmpty) _field('Homework / assignment', plan.homework),
          if (plan.notes.isNotEmpty) _field('Teacher notes', plan.notes),
        ],
      ),
    );
  }

  static pw.Widget _field(String title, String body) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#2C4A6E'),
            ),
          ),
          pw.Text(pdfSafe(body), style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
