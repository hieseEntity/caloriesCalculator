import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calories_calculator/core/database/database_helper.dart';
import 'package:calories_calculator/core/models/food_entry.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper SQLite Storage Tests', () {
    late DatabaseHelper db;

    setUp(() async {
      db = await DatabaseHelper.createInMemory();
    });

    tearDown(() async {
      await db.close();
    });

    test('Inserts and retrieves food entries by date', () async {
      final entry1 = FoodEntry(
        id: 'entry-1',
        name: 'Oatmeal & Whey',
        calories: 350,
        protein: 30.0,
        carbs: 45.0,
        fat: 6.0,
        timestamp: DateTime.now(),
        dateString: '2026-10-28',
      );

      final entry2 = FoodEntry(
        id: 'entry-2',
        name: 'Chicken Rice Bowl',
        calories: 550,
        protein: 42.0,
        carbs: 60.0,
        fat: 12.0,
        timestamp: DateTime.now(),
        dateString: '2026-10-28',
      );

      await db.insertFoodEntry(entry1);
      await db.insertFoodEntry(entry2);

      final entries = await db.getEntriesForDate('2026-10-28');
      expect(entries.length, equals(2));

      final totalCalories = await db.getDailyTotalCalories('2026-10-28');
      expect(totalCalories, equals(900));
    });

    test('Deletes food entry properly', () async {
      final entry = FoodEntry(
        id: 'entry-del',
        name: 'Snack',
        calories: 150,
        protein: 5.0,
        carbs: 20.0,
        fat: 4.0,
        timestamp: DateTime.now(),
        dateString: '2026-10-28',
      );

      await db.insertFoodEntry(entry);
      var entries = await db.getEntriesForDate('2026-10-28');
      expect(entries.length, equals(1));

      await db.deleteFoodEntry('entry-del');
      entries = await db.getEntriesForDate('2026-10-28');
      expect(entries.isEmpty, isTrue);
    });
  });
}

