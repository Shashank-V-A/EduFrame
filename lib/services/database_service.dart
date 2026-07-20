import 'dart:io';

import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import '../utils/date_utils.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;
  String? _activeUserId;

  static const _legacyMigratedKey = 'legacy_db_migrated_to';

  static const _planSelect = '''
    SELECT p.*, c.name as class_name, c.subject, c.section
    FROM lesson_plans p
    JOIN classes c ON c.id = p.class_id
  ''';

  static const _timetableSelect = '''
    SELECT t.*, c.name as class_name, c.subject, c.section
    FROM timetable_slots t
    LEFT JOIN classes c ON c.id = t.class_id
  ''';

  String? get activeUserId => _activeUserId;

  Future<Database> get database async {
    if (_db != null) return _db!;
    throw StateError(
      'Database is not bound to a user. Call bindUser() after Google Sign-In.',
    );
  }

  /// Opens (or switches to) the SQLite file for [userId].
  Future<void> bindUser(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) {
      throw ArgumentError('userId is required');
    }
    if (_activeUserId == id && _db != null) return;

    await _db?.close();
    _db = null;
    _activeUserId = id;
    _db = await _openForUser(id);
  }

  Future<void> unbindUser() async {
    await _db?.close();
    _db = null;
    _activeUserId = null;
  }

  String _safeFileToken(String userId) =>
      userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

  Future<Database> _openForUser(String userId) async {
    final dbPath = await getDatabasesPath();
    final userPath = join(dbPath, 'eduframe_${_safeFileToken(userId)}.db');
    await _maybeMigrateLegacyDb(userId, userPath);

    final db = await openDatabase(
      userPath,
      version: 2,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await _seedIfEmpty(db);
    return db;
  }

  /// One-time copy of pre-scoping `eduframe.db` into the first user's file.
  Future<void> _maybeMigrateLegacyDb(String userId, String userPath) async {
    final userFile = File(userPath);
    if (await userFile.exists()) return;

    final dbPath = await getDatabasesPath();
    final legacy = File(join(dbPath, 'eduframe.db'));
    if (!await legacy.exists()) return;

    final prefs = await SharedPreferences.getInstance();
    final already = prefs.getString(_legacyMigratedKey);
    if (already != null && already.isNotEmpty) return;

    await legacy.copy(userPath);
    await prefs.setString(_legacyMigratedKey, userId);
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createCoreTables(db);
    await _createTimetableTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createTimetableTable(db);
    }
  }

  Future<void> _createCoreTables(Database db) async {
    await db.execute('''
      CREATE TABLE classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        subject TEXT NOT NULL DEFAULT '',
        section TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE lesson_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL,
        plan_date TEXT NOT NULL,
        topic TEXT NOT NULL,
        objectives TEXT NOT NULL DEFAULT '',
        activities TEXT NOT NULL DEFAULT '',
        homework TEXT NOT NULL DEFAULT '',
        materials TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_plans_date ON lesson_plans(plan_date)');
    await db.execute('CREATE INDEX idx_plans_topic ON lesson_plans(topic)');
  }

  Future<void> _createTimetableTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS timetable_slots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER,
        day_of_week INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        room TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_timetable_day ON timetable_slots(day_of_week)',
    );
  }

  Future<void> _seedIfEmpty(Database db) async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM classes');
    final count = Sqflite.firstIntValue(result) ?? 0;
    if (count > 0) return;

    final now = DateTime.now().toIso8601String();
    for (final sample in [
      {'name': 'Class 8-A', 'subject': 'Mathematics', 'section': 'A'},
      {'name': 'Class 9-B', 'subject': 'Mathematics', 'section': 'B'},
    ]) {
      await db.insert('classes', {
        'name': sample['name'],
        'subject': sample['subject'],
        'section': sample['section'],
        'created_at': now,
      });
    }
  }

  Future<List<TeachingClass>> getAllClasses() async {
    final db = await database;
    final rows = await db.query('classes', orderBy: 'name ASC');
    return rows.map(TeachingClass.fromMap).toList();
  }

  Future<int> createClass(String name, String subject, String section) async {
    final db = await database;
    return db.insert('classes', {
      'name': name.trim(),
      'subject': subject.trim(),
      'section': section.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateClass(int id, String name, String subject, String section) async {
    final db = await database;
    await db.update(
      'classes',
      {'name': name.trim(), 'subject': subject.trim(), 'section': section.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteClass(int id) async {
    final db = await database;
    await db.delete('classes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LessonPlan>> getPlansForDate(String date) async {
    final db = await database;
    final normalized = normalizePlanDate(date);
    final rows = await db.rawQuery(
      '$_planSelect WHERE date(p.plan_date) = date(?) ORDER BY c.name ASC',
      [normalized],
    );
    return rows.map(LessonPlan.fromMap).toList();
  }

  Future<List<LessonPlan>> getAllPlans() async {
    final db = await database;
    final rows = await db.rawQuery(
      '$_planSelect ORDER BY date(p.plan_date) DESC, c.name ASC',
    );
    return rows.map(LessonPlan.fromMap).toList();
  }

  Future<PlanDateExtent> getPlanDateExtent() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT MIN(date(plan_date)) as min_date, MAX(date(plan_date)) as max_date, COUNT(*) as count FROM lesson_plans',
    );
    if (rows.isEmpty) return const PlanDateExtent();
    final row = rows.first;
    return PlanDateExtent(
      minDate: row['min_date'] as String?,
      maxDate: row['max_date'] as String?,
      count: (row['count'] as int?) ?? 0,
    );
  }

  Future<List<LessonPlan>> searchPlans(String query) async {
    final db = await database;
    final term = '%${query.trim()}%';
    final rows = await db.rawQuery(
      '''$_planSelect
         WHERE p.topic LIKE ? OR p.objectives LIKE ?
            OR p.activities LIKE ? OR p.homework LIKE ?
         ORDER BY date(p.plan_date) DESC''',
      [term, term, term, term],
    );
    return rows.map(LessonPlan.fromMap).toList();
  }

  Future<LessonPlan?> getPlanById(int id) async {
    final db = await database;
    final rows = await db.rawQuery('$_planSelect WHERE p.id = ?', [id]);
    if (rows.isEmpty) return null;
    return LessonPlan.fromMap(rows.first);
  }

  Future<int> createPlan(PlanFormData data) async {
    if (data.classId == null) throw Exception('Class is required');
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final planDate = normalizePlanDate(data.planDate);
    return db.insert('lesson_plans', {
      'class_id': data.classId,
      'plan_date': planDate,
      'topic': data.topic.trim(),
      'objectives': data.objectives.trim(),
      'activities': data.activities.trim(),
      'homework': data.homework.trim(),
      'materials': data.materials.trim(),
      'notes': data.notes.trim(),
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> updatePlan(int id, PlanFormData data) async {
    if (data.classId == null) throw Exception('Class is required');
    final db = await database;
    await db.update(
      'lesson_plans',
      {
        'class_id': data.classId,
        'plan_date': normalizePlanDate(data.planDate),
        'topic': data.topic.trim(),
        'objectives': data.objectives.trim(),
        'activities': data.activities.trim(),
        'homework': data.homework.trim(),
        'materials': data.materials.trim(),
        'notes': data.notes.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePlan(int id) async {
    final db = await database;
    await db.delete('lesson_plans', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> duplicatePlan(int id, {String? newDate}) async {
    final plan = await getPlanById(id);
    if (plan == null) throw Exception('Plan not found');
    return createPlan(PlanFormData.fromPlan(plan)..planDate = newDate ?? toDateString(DateTime.now()));
  }

  Future<List<LessonPlan>> getPlansInRange(
    String startDate,
    String endDate, {
    int? classId,
  }) async {
    final db = await database;
    final start = normalizePlanDate(startDate);
    final end = normalizePlanDate(endDate);
    var query = '$_planSelect WHERE date(p.plan_date) BETWEEN date(?) AND date(?)';
    final args = <Object>[start, end];
    if (classId != null) {
      query += ' AND p.class_id = ?';
      args.add(classId);
    }
    query += ' ORDER BY date(p.plan_date) ASC, c.name ASC';
    final rows = await db.rawQuery(query, args);
    return rows.map(LessonPlan.fromMap).toList();
  }

  Future<List<TimetableSlot>> getAllTimetableSlots() async {
    final db = await database;
    final rows = await db.rawQuery(
      '$_timetableSelect ORDER BY t.day_of_week ASC, t.start_time ASC',
    );
    return rows.map(TimetableSlot.fromMap).toList();
  }

  Future<List<TimetableSlot>> getTimetableForDay(int dayOfWeek) async {
    final db = await database;
    final rows = await db.rawQuery(
      '$_timetableSelect WHERE t.day_of_week = ? ORDER BY t.start_time ASC',
      [dayOfWeek],
    );
    return rows.map(TimetableSlot.fromMap).toList();
  }

  Future<int> createTimetableSlot({
    int? classId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String room = '',
  }) async {
    final db = await database;
    return db.insert('timetable_slots', {
      'class_id': classId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'room': room.trim(),
    });
  }

  Future<void> updateTimetableSlot({
    required int id,
    int? classId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String room = '',
  }) async {
    final db = await database;
    await db.update(
      'timetable_slots',
      {
        'class_id': classId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'room': room.trim(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTimetableSlot(int id) async {
    final db = await database;
    await db.delete('timetable_slots', where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes all classes, plans, and timetable rows for the bound user.
  Future<void> deleteAllLocalData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('timetable_slots');
      await txn.delete('lesson_plans');
      await txn.delete('classes');
    });
  }

  /// Wipes local tables and removes the user DB file from disk.
  Future<void> wipeUserDatabase() async {
    final userId = _activeUserId;
    await deleteAllLocalData();
    await unbindUser();
    if (userId == null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'eduframe_${_safeFileToken(userId)}.db');
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final extra = File('$path$suffix');
      if (await extra.exists()) {
        await extra.delete();
      }
    }
  }

  Future<void> importAllData({
    required List<Map<String, String>> classes,
    required List<Map<String, String>> plans,
    required List<Map<String, dynamic>> slots,
    bool replace = true,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      if (replace) {
        await txn.delete('timetable_slots');
        await txn.delete('lesson_plans');
        await txn.delete('classes');
      }

      final classNameToId = <String, int>{};
      final existingClasses = await txn.query('classes');
      for (final row in existingClasses) {
        classNameToId[row['name'] as String] = row['id'] as int;
      }

      for (final cls in classes) {
        final name = cls['name']!.trim();
        if (name.isEmpty) continue;
        if (classNameToId.containsKey(name)) continue;
        final id = await txn.insert('classes', {
          'name': name,
          'subject': cls['subject']?.trim() ?? '',
          'section': cls['section']?.trim() ?? '',
          'created_at': cls['created_at'] ?? DateTime.now().toIso8601String(),
        });
        classNameToId[name] = id;
      }

      for (final plan in plans) {
        final className = plan['class_name']?.trim() ?? '';
        var classId = classNameToId[className];
        if (classId == null && className.isNotEmpty) {
          classId = await txn.insert('classes', {
            'name': className,
            'subject': plan['subject']?.trim() ?? '',
            'section': plan['section']?.trim() ?? '',
            'created_at': DateTime.now().toIso8601String(),
          });
          classNameToId[className] = classId;
        }
        if (classId == null) continue;

        final now = DateTime.now().toIso8601String();
        await txn.insert('lesson_plans', {
          'class_id': classId,
          'plan_date': normalizePlanDate(plan['plan_date'] ?? now),
          'topic': plan['topic']?.trim() ?? 'Untitled',
          'objectives': plan['objectives']?.trim() ?? '',
          'activities': plan['activities']?.trim() ?? '',
          'homework': plan['homework']?.trim() ?? '',
          'materials': plan['materials']?.trim() ?? '',
          'notes': plan['notes']?.trim() ?? '',
          'created_at': plan['created_at'] ?? now,
          'updated_at': plan['updated_at'] ?? now,
        });
      }

      for (final slot in slots) {
        final className = slot['class_name'] as String?;
        int? classId;
        if (className != null && className.trim().isNotEmpty) {
          classId = classNameToId[className.trim()];
        }
        await txn.insert('timetable_slots', {
          'class_id': classId,
          'day_of_week': slot['day_of_week'] as int? ?? 1,
          'start_time': slot['start_time'] as String? ?? '09:00',
          'end_time': slot['end_time'] as String? ?? '09:45',
          'room': (slot['room'] as String? ?? '').trim(),
        });
      }
    });
  }
}
