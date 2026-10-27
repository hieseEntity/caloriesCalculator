import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/daily_summary.dart';
import '../../core/models/food_entry.dart';
import '../../core/services/rollover_service.dart';

class TrackerController extends ChangeNotifier {
  final DatabaseHelper _db;
  final RolloverService _rolloverService;

  String _currentDate = '';
  List<FoodEntry> _todayEntries = [];
  List<DailySummary> _historySummaries = [];
  bool _isLoading = true;

  int _consumedCalories = 0;
  double _consumedProtein = 0.0;
  double _consumedCarbs = 0.0;
  double _consumedFat = 0.0;

  TrackerController({
    required DatabaseHelper databaseHelper,
    required RolloverService rolloverService,
  })  : _db = databaseHelper,
        _rolloverService = rolloverService;

  String get currentDate => _currentDate;
  List<FoodEntry> get todayEntries => _todayEntries;
  List<DailySummary> get historySummaries => _historySummaries;
  bool get isLoading => _isLoading;

  int get consumedCalories => _consumedCalories;
  double get consumedProtein => _consumedProtein;
  double get consumedCarbs => _consumedCarbs;
  double get consumedFat => _consumedFat;

  Future<void> init(int targetCalories) async {
    _isLoading = true;
    notifyListeners();

    // Check for 00:00 / midnight roll-over
    await _rolloverService.checkAndTriggerRollover();
    _currentDate = _rolloverService.getTodayDateString();

    await loadTodayEntries();
    await refreshHistory(targetCalories);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkRollover(int targetCalories) async {
    final rollover = await _rolloverService.checkAndTriggerRollover();
    if (rollover.didRollover) {
      _currentDate = rollover.currentDate;
      await loadTodayEntries();
      await refreshHistory(targetCalories);
      notifyListeners();
    }
  }

  Future<void> loadTodayEntries() async {
    _todayEntries = await _db.getEntriesForDate(_currentDate);
    _recalculateTotals();
  }

  void _recalculateTotals() {
    int totalCals = 0;
    double totalP = 0.0;
    double totalC = 0.0;
    double totalF = 0.0;

    for (final e in _todayEntries) {
      totalCals += e.calories;
      totalP += e.protein;
      totalC += e.carbs;
      totalF += e.fat;
    }

    _consumedCalories = totalCals;
    _consumedProtein = totalP;
    _consumedCarbs = totalC;
    _consumedFat = totalF;
  }

  Future<void> addFoodEntry(FoodEntry entry, int targetCalories) async {
    await _db.insertFoodEntry(entry);
    if (entry.dateString == _currentDate) {
      _todayEntries.insert(0, entry);
      _recalculateTotals();
    }
    await refreshHistory(targetCalories);
    notifyListeners();
  }

  Future<void> deleteFoodEntry(String id, int targetCalories) async {
    await _db.deleteFoodEntry(id);
    _todayEntries.removeWhere((e) => e.id == id);
    _recalculateTotals();
    await refreshHistory(targetCalories);
    notifyListeners();
  }

  Future<void> refreshHistory(int targetCalories) async {
    _historySummaries = await _db.getDailySummaries(targetCalories: targetCalories);
  }
}
