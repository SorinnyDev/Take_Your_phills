
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/reminder.dart';

class DatabaseHelper {
  static Database? _database;
  static const String tableName = 'reminders';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // DB 초기화
  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'medication.db');
    
    print('📁 Database path: $path');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // 테이블 생성
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName(
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
    print('✅ Database table created');
  }

  // 알림 추가
  static Future<int> insertReminder(Reminder reminder) async {
    final db = await database;
    final id = await db.insert(tableName, reminder.toMap());
    print('✅ Reminder inserted with id: $id');
    return id;
  }

  // 모든 알림 가져오기
  static Future<List<Reminder>> getAllReminders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    print('📊 Found ${maps.length} reminders');
    return List.generate(maps.length, (i) => Reminder.fromMap(maps[i]));
  }

  // 알림 수정
  static Future<int> updateReminder(Reminder reminder) async {
    final db = await database;
    return await db.update(
      tableName,
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  // 알림 삭제
  static Future<int> deleteReminder(int id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 디버깅용: 모든 데이터 출력
  static Future<void> printAllData() async {
    final reminders = await getAllReminders();
    print('📊 Total reminders: ${reminders.length}');
    for (var reminder in reminders) {
      print('  - ${reminder.title} at ${reminder.amPm} ${reminder.hour}:${reminder.minute}');
    }
  }
}
