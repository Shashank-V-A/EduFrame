import '../models/models.dart';
import 'pdf_service.dart';

class ShareService {
  ShareService._();
  static final ShareService instance = ShareService._();

  Future<void> sharePlan(LessonPlan plan) => PdfService.sharePlan(plan);
}
