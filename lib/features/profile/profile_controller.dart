import 'package:flutter/foundation.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/preferences_service.dart';
import 'tdee_calculator.dart';

class ProfileController extends ChangeNotifier {
  final PreferencesService _prefs;
  late UserProfile _profile;
  late TdeeCalculationResult _tdeeResult;

  ProfileController(this._prefs) {
    _profile = _prefs.getProfile();
    _recalculate();
  }

  UserProfile get profile => _profile;
  TdeeCalculationResult get tdeeResult => _tdeeResult;

  void _recalculate() {
    _tdeeResult = TdeeCalculator.calculate(_profile);
  }

  Future<void> updateProfile({
    int? age,
    double? heightCm,
    double? weightKg,
    Gender? gender,
    ActivityLevel? activityLevel,
    CalorieGoal? goal,
  }) async {
    _profile = _profile.copyWith(
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      gender: gender,
      activityLevel: activityLevel,
      goal: goal,
    );

    _recalculate();
    await _prefs.saveProfile(_profile);
    notifyListeners();
  }
}

