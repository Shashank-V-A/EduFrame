import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import '../utils/date_utils.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  static const _planSelect = '''
    SELECT p.*, c.name as class_name, c.subject, c.section
    FROM lesson_plans p
    JOIN classes c ON c.id = p.class_id
  ''';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'eduframe.db');
    final db = await openDatabase(
      path,
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
    await _seedIfEmpty(db);
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');
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
    await db.execute(
      'CREATE INDEX idx_plans_date ON lesson_plans(plan_date)',
    );
    await db.execute(
      'CREATE INDEX idx_plans_topic ON lesson_plans(topic)',
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

  Future<void> updateClass(
    int id,
    String name,
    String subject,
    String section,
  ) async {
    final db = await database;
    await db.update(
      'classes',
      {
        'name': name.trim(),
        'subject': subject.trim(),
        'section': section.trim(),
      },
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
    final rows = await db.rawQuery(
      '$_planSelect WHERE p.plan_date = ? ORDER BY c.name ASC',
      [date],
    );
    return rows.map(LessonPlan.fromMap).toList();
  }

  Future<List<LessonPlan>> getAllPlans() async {
    final db = await database;
    final rows = await db.rawQuery(
      '$_planSelect ORDER BY p.plan_date DESC, c.name ASC',
    );
    return rows.map(LessonPlan.fromMap).toList();
  }

  Future<List<LessonPlan>> searchPlans(String query) async {
    final db = await database;
    final term = '%${query.trim()}%';
    final rows = await db.rawQuery(
      '''$_planSelect
         WHERE p.topic LIKE ? OR p.objectives LIKE ?
            OR p.activities LIKE ? OR p.homework LIKE ?
         ORDER BY p.plan_date DESC''',
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
    return db.insert('lesson_plans', {
      'class_id': data.classId,
      'plan_date': data.planDate,
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
        'plan_date': data.planDate,
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
    var query = '$_planSelect WHERE p.plan_date BETWEEN ? AND ?';
    final args = <Object>[startDate, endDate];
    if (classId != null) {
      query += ' AND p.class_id = ?';
      args.add(classId);
    }
    query += ' ORDER BY p.plan_date ASC, c.name ASC';
    final rows = await db.rawQuery(query, args);
    return rows.map(LessonPlan.fromMap).toList();
  }
}
