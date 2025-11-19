
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/reminder.dart';
import '../models/medication_record.dart';

class DatabaseHelper {
  static Database? _database;
  static const String dbName = 'medication.db';
  static const int dbVersion = 3;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amPm TEXT NOT NULL,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        repeatHour INTEGER NOT NULL,
        repeatMinute INTEGER NOT NULL,
        isEnabled INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        currentSnoozeCount INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE medication_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reminderId INTEGER NOT NULL,
        scheduledTime TEXT NOT NULL,
        takenAt TEXT,
        status TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (reminderId) REFERENCES reminders (id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE reminders 
        ADD COLUMN currentSnoozeCount INTEGER DEFAULT 0
      ''');
      print('✅ DB 업그레이드: currentSnoozeCount 컬럼 추가');
    }
  }

  // ========== Reminder CRUD ==========

  static Future<int> insertReminder(Reminder reminder) async {
    final db = await database;
    return await db.insert('reminders', reminder.toMap());
  }

  static Future<List<Reminder>> getAllReminders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Reminder.fromMap(maps[i]));
  }

  static Future<List<Reminder>> getEnabledReminders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      where: 'isEnabled = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Reminder.fromMap(maps[i]));
  }

  static Future<Reminder?> getReminderById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Reminder.fromMap(maps.first);
  }

  static Future<int> updateReminder(Reminder reminder) async {
    final db = await database;
    return await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  static Future<int> deleteReminder(int id) async {
    final db = await database;
    return await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 🔥 스누즈 카운트 업데이트
  static Future<void> updateSnoozeCount(int reminderId, int count) async {
    final db = await database;
    await db.update(
      'reminders',
      {'currentSnoozeCount': count},
      where: 'id = ?',
      whereArgs: [reminderId],
    );
  }

  // 🔥 스누즈 카운트 리셋
  static Future<void> resetSnoozeCount(int reminderId) async {
    await updateSnoozeCount(reminderId, 0);
  }

  // ========== MedicationRecord CRUD ==========

  // 🔥 기존 insertRecord 메서드 수정
  static Future<int> insertRecord(MedicationRecord record) async {
    final db = await database;

    return await db.insert(
      'medication_records',
      {
        'medicineName': record.medicineName,
        'scheduledTime': record.takenAt?.toIso8601String(), // 🔥 Null-safe 연산자 추가!
        'takenAt': record.takenAt?.toIso8601String(), // 🔥 Null-safe 연산자 추가!
        'note': record.note,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 🔥 새로운 insertMedicationRecord 메서드 (이미 있는지 확인 후 추가)
  static Future<int> insertMedicationRecord({
    required int reminderId,
    required DateTime scheduledTime,
    DateTime? takenAt,
    required String status,
    String? note,
  }) async {
    final db = await database;

    return await db.insert(
      'medication_records',
      {
        'reminderId': reminderId,
        'scheduledTime': scheduledTime.toIso8601String(), // 🔥 Non-null이므로 안전!
        'takenAt': takenAt?.toIso8601String(), // 🔥 Null-safe 연산자!
        'status': status,
        'note': note,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<MedicationRecord>> getMedicationRecords({
    int? reminderId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (reminderId != null) {
      whereClause = 'reminderId = ?';
      whereArgs.add(reminderId);
    }

    if (startDate != null && endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'scheduledTime BETWEEN ? AND ?';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'medication_records',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'scheduledTime DESC',
    );

    return List.generate(maps.length, (i) => MedicationRecord.fromMap(maps[i]));
  }

  static Future<int> deleteMedicationRecord(int id) async {
    final db = await database;
    return await db.delete(
      'medication_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== 통계 ==========

  static Future<Map<String, int>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = 'scheduledTime BETWEEN ? AND ?';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery('''
      SELECT 
        status,
        COUNT(*) as count
      FROM medication_records
      ${whereClause.isEmpty ? '' : 'WHERE $whereClause'}
      GROUP BY status
    ''', whereArgs);

    final stats = <String, int>{
      'taken': 0,
      'skipped': 0,
      'auto_skipped': 0,
    };

    for (var row in result) {
      final status = row['status'] as String;
      final count = row['count'] as int;
      stats[status] = count;
    }

    return stats;
  }
}
