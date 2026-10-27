import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/food_entry.dart';
import '../models/daily_summary.dart';

class DatabaseHelper {
  static DatabaseHelper instance = DatabaseHelper._init();
  Database? _database;

  DatabaseHelper._init({Database? db}) : _database = db;

  factory DatabaseHelper.withDatabase(Database db) {
    return DatabaseHelper._init(db: db);
  }

  static Future<DatabaseHelper> createInMemory() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final helper = DatabaseHelper._init();
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: helper._createDB,
      ),
    );
    return DatabaseHelper.withDatabase(db);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('calories_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Enable FFI for desktop platforms and unit test runners
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final dbPath = await databaseFactoryFfi.getDatabasesPath();
      final path = filePath == inMemoryDatabasePath ? inMemoryDatabasePath : p.join(dbPath, filePath);
      return await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDB,
        ),
      );
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE food_entries (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        calories INTEGER NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        timestamp TEXT NOT NULL,
        dateString TEXT NOT NULL,
        imagePath TEXT,
        rawOcrText TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_food_entries_date ON food_entries (dateString)
    ''');
  }

  Future<int> insertFoodEntry(FoodEntry entry) async {
    final db = await database;
    return await db.insert(
      'food_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FoodEntry>> getEntriesForDate(String dateString) async {
    final db = await database;
    final maps = await db.query(
      'food_entries',
      where: 'dateString = ?',
      whereArgs: [dateString],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => FoodEntry.fromMap(m)).toList();
  }

  Future<List<FoodEntry>> getAllEntries() async {
    final db = await database;
    final maps = await db.query(
      'food_entries',
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => FoodEntry.fromMap(m)).toList();
  }

  Future<int> deleteFoodEntry(String id) async {
    final db = await database;
    return await db.delete(
      'food_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateFoodEntry(FoodEntry entry) async {
    final db = await database;
    return await db.update(
      'food_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> getDailyTotalCalories(String dateString) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(calories) as total FROM food_entries WHERE dateString = ?',
      [dateString],
    );
    final total = result.first['total'];
    return (total as num?)?.toInt() ?? 0;
  }

  Future<List<DailySummary>> getDailySummaries({required int targetCalories, int limit = 30}) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        dateString,
        COUNT(*) as entryCount,
        SUM(calories) as totalCalories,
        SUM(protein) as totalProtein,
        SUM(carbs) as totalCarbs,
        SUM(fat) as totalFat
      FROM food_entries
      GROUP BY dateString
      ORDER BY dateString DESC
      LIMIT ?
    ''', [limit]);

    return result.map((row) {
      return DailySummary(
        dateString: row['dateString'] as String,
        entryCount: (row['entryCount'] as num?)?.toInt() ?? 0,
        totalCalories: (row['totalCalories'] as num?)?.toInt() ?? 0,
        targetCalories: targetCalories,
        totalProtein: (row['totalProtein'] as num?)?.toDouble() ?? 0.0,
        totalCarbs: (row['totalCarbs'] as num?)?.toDouble() ?? 0.0,
        totalFat: (row['totalFat'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('food_entries');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
