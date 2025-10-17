
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/reminder.dart';
import '../models/medication_record.dart';

class DatabaseHelper {
  static Database? _database;
  static const String reminderTable = 'reminders';
  static const String recordTable = 'medication_records';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'reminders.db');

    return await openDatabase(
      path,
      version: 1, // 🔥 개발 중에는 1로 고정!
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // reminders 테이블
    await db.execute('''
      CREATE TABLE $reminderTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amPm TEXT NOT NULL,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        repeatHour INTEGER NOT NULL,
        repeatMinute INTEGER NOT NULL,
        isEnabled INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // medication_records 테이블
    await db.execute('''
      CREATE TABLE $recordTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine_name TEXT NOT NULL,
        taken_at TEXT NOT NULL,
        note TEXT
      )
    ''');

    print('✅ Tables created successfully');
  }

  // ========== Reminder 관련 메서드 ==========
  
  static Future<int> insertReminder(Reminder reminder) async {
    final db = await database;
    final id = await db.insert(reminderTable, reminder.toMap());
    print('✅ Reminder inserted with id: $id');
    return id;
  }

  static Future<List<Reminder>> getAllReminders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      reminderTable,
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Reminder.fromMap(maps[i]));
  }

  static Future<int> updateReminder(Reminder reminder) async {
    final db = await database;
    return await db.update(
      reminderTable,
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  static Future<int> deleteReminder(int id) async {
    final db = await database;
    return await db.delete(
      reminderTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== MedicationRecord 관련 메서드 ==========
  
  static Future<int> insertRecord(MedicationRecord record) async {
    final db = await database;
    final id = await db.insert(recordTable, record.toMap());
    print('✅ Medication record inserted with id: $id');
    return id;
  }

  static Future<List<MedicationRecord>> getAllRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      recordTable,
      orderBy: 'taken_at DESC',
    );
    return List.generate(maps.length, (i) => MedicationRecord.fromMap(maps[i]));
  }

  static Future<List<MedicationRecord>> getRecordsByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    
    final List<Map<String, dynamic>> maps = await db.query(
      recordTable,
      where: 'taken_at >= ? AND taken_at < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'taken_at DESC',
    );
    return List.generate(maps.length, (i) => MedicationRecord.fromMap(maps[i]));
  }

  static Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete(
      recordTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 디버깅용
  static Future<void> printAllData() async {
    final db = await database;
    final reminders = await db.query(reminderTable);
    final records = await db.query(recordTable);
    
    print('═══════════════════════════════════');
    print('📊 DATABASE STATUS');
    print('═══════════════════════════════════');
    print('📋 Reminders: ${reminders.length} items');
    for (var reminder in reminders) {
      print('  - ${reminder['title']} (${reminder['amPm']} ${reminder['hour']}:${reminder['minute']})');
    }
    print('───────────────────────────────────');
    print('💊 Records: ${records.length} items');
    for (var record in records) {
      print('  - ${record['medicine_name']} at ${record['taken_at']}');
    }
    print('═══════════════════════════════════');
  }
}
