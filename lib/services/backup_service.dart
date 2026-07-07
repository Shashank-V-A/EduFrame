import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import 'auth_service.dart';
import 'database_service.dart';

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const _driveScope = 'https://www.googleapis.com/auth/drive.file';
  static const _backupMime = 'application/json';

  Future<Map<String, dynamic>> exportData() async {
    final db = DatabaseService.instance;
    final classes = await db.getAllClasses();
    final plans = await db.getAllPlans();
    final slots = await db.getAllTimetableSlots();

    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'classes': classes.map(_classToJson).toList(),
      'lesson_plans': plans.map(_planToJson).toList(),
      'timetable_slots': slots.map(_slotToJson).toList(),
    };
  }

  Future<void> importData(Map<String, dynamic> data, {bool replace = true}) async {
    await DatabaseService.instance.importAllData(
      classes: (data['classes'] as List<dynamic>? ?? [])
          .map((e) => _classFromJson(e as Map<String, dynamic>))
          .toList(),
      plans: (data['lesson_plans'] as List<dynamic>? ?? [])
          .map((e) => _planFromJson(e as Map<String, dynamic>))
          .toList(),
      slots: (data['timetable_slots'] as List<dynamic>? ?? [])
          .map((e) => _slotFromJson(e as Map<String, dynamic>))
          .toList(),
      replace: replace,
    );
  }

  Future<File> writeBackupFile() async {
    final data = await exportData();
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().split('T').first;
    final file = File('${dir.path}/eduframe-backup-$stamp.json');
    await file.writeAsString(jsonEncode(data));
    return file;
  }

  Future<void> shareBackupFile() async {
    final file = await writeBackupFile();
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'EduFrame backup',
        text: 'EduFrame lesson plan backup',
      ),
    );
  }

  Future<void> pickAndRestore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) throw Exception('Could not read backup file');

    final text = await File(path).readAsString();
    final data = jsonDecode(text) as Map<String, dynamic>;
    await importData(data, replace: true);
  }

  Future<void> uploadToGoogleDrive() async {
    final token = await AuthService.instance.getAccessToken(scopes: [_driveScope]);
    if (token == null) {
      throw Exception('Sign in with Google to back up to Drive.');
    }

    final file = await writeBackupFile();
    final bytes = await file.readAsBytes();
    final fileName = file.uri.pathSegments.last;

    final metadata = jsonEncode({
      'name': fileName,
      'mimeType': _backupMime,
    });

    final uri = Uri.parse(
      'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart',
    );

    final boundary = 'eduframe_${DateTime.now().millisecondsSinceEpoch}';
    final body = <int>[];
    void write(String s) => body.addAll(utf8.encode(s));

    write('--$boundary\r\n');
    write('Content-Type: application/json; charset=UTF-8\r\n\r\n');
    write('$metadata\r\n');
    write('--$boundary\r\n');
    write('Content-Type: $_backupMime\r\n\r\n');
    body.addAll(bytes);
    write('\r\n--$boundary--');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'multipart/related; boundary=$boundary',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Drive upload failed (${response.statusCode}): ${response.body}');
    }
  }

  Future<void> restoreFromGoogleDrive() async {
    final token = await AuthService.instance.getAccessToken(scopes: [_driveScope]);
    if (token == null) {
      throw Exception('Sign in with Google to restore from Drive.');
    }

    final listUri = Uri.parse(
      "https://www.googleapis.com/drive/v3/files"
      "?q=${Uri.encodeComponent("name contains 'eduframe-backup' and mimeType='application/json' and trashed=false")}"
      '&orderBy=createdTime desc&pageSize=10&fields=files(id,name,createdTime)',
    );

    final listResponse = await http.get(
      listUri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (listResponse.statusCode != 200) {
      throw Exception('Could not list Drive backups (${listResponse.statusCode})');
    }

    final files = (jsonDecode(listResponse.body) as Map<String, dynamic>)['files']
        as List<dynamic>? ?? [];
    if (files.isEmpty) {
      throw Exception('No EduFrame backups found on Google Drive.');
    }

    final latest = files.first as Map<String, dynamic>;
    final fileId = latest['id'] as String;

    final downloadUri = Uri.parse(
      'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
    );
    final downloadResponse = await http.get(
      downloadUri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (downloadResponse.statusCode != 200) {
      throw Exception('Could not download backup (${downloadResponse.statusCode})');
    }

    final data = jsonDecode(downloadResponse.body) as Map<String, dynamic>;
    await importData(data, replace: true);
  }

  Map<String, dynamic> _classToJson(TeachingClass c) => {
        'name': c.name,
        'subject': c.subject,
        'section': c.section,
        'created_at': c.createdAt,
      };

  Map<String, dynamic> _planToJson(LessonPlan p) => {
        'class_name': p.className,
        'subject': p.subject,
        'section': p.section,
        'plan_date': p.planDate,
        'topic': p.topic,
        'objectives': p.objectives,
        'activities': p.activities,
        'homework': p.homework,
        'materials': p.materials,
        'notes': p.notes,
        'created_at': p.createdAt,
        'updated_at': p.updatedAt,
      };

  Map<String, dynamic> _slotToJson(TimetableSlot s) => {
        'class_name': s.classId == null ? null : s.className,
        'subject': s.subject,
        'day_of_week': s.dayOfWeek,
        'start_time': s.startTime,
        'end_time': s.endTime,
        'room': s.room,
      };

  Map<String, String> _classFromJson(Map<String, dynamic> m) => {
        'name': m['name'] as String? ?? '',
        'subject': m['subject'] as String? ?? '',
        'section': m['section'] as String? ?? '',
        'created_at': m['created_at'] as String? ?? DateTime.now().toIso8601String(),
      };

  Map<String, String> _planFromJson(Map<String, dynamic> m) => {
        'class_name': m['class_name'] as String? ?? '',
        'subject': m['subject'] as String? ?? '',
        'section': m['section'] as String? ?? '',
        'plan_date': m['plan_date'] as String? ?? '',
        'topic': m['topic'] as String? ?? '',
        'objectives': m['objectives'] as String? ?? '',
        'activities': m['activities'] as String? ?? '',
        'homework': m['homework'] as String? ?? '',
        'materials': m['materials'] as String? ?? '',
        'notes': m['notes'] as String? ?? '',
        'created_at': m['created_at'] as String? ?? DateTime.now().toIso8601String(),
        'updated_at': m['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      };

  Map<String, dynamic> _slotFromJson(Map<String, dynamic> m) => {
        'class_name': m['class_name'] as String?,
        'subject': m['subject'] as String? ?? '',
        'day_of_week': m['day_of_week'] as int? ?? 1,
        'start_time': m['start_time'] as String? ?? '09:00',
        'end_time': m['end_time'] as String? ?? '09:45',
        'room': m['room'] as String? ?? '',
      };
}
