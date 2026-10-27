import 'package:flutter_test/flutter_test.dart';
import 'package:calories_calculator/core/models/user_profile.dart';
import 'package:calories_calculator/features/profile/tdee_calculator.dart';

void main() {
  group('Mifflin-St Jeor TDEE Calculator Tests', () {
    test('Calculates male BMR accurately', () {
      final bmr = TdeeCalculator.calculateBmr(
        weightKg: 70.0,
        heightCm: 175.0,
        age: 25,
        gender: Gender.male,
      );
      // 10*70 + 6.25*175 - 5*25 + 5 = 700 + 1093.75 - 125 + 5 = 1673.75
      expect(bmr, closeTo(1673.75, 0.01));
    });

    test('Calculates female BMR accurately', () {
      final bmr = TdeeCalculator.calculateBmr(
        weightKg: 60.0,
        heightCm: 165.0,
        age: 30,
        gender: Gender.female,
      );
      // 10*60 + 6.25*165 - 5*30 - 161 = 600 + 1031.25 - 150 - 161 = 1320.25
      expect(bmr, closeTo(1320.25, 0.01));
    });

    test('Calculates TDEE with activity multiplier and goal adjustments', () {
      const profile = UserProfile(
        age: 25,
        heightCm: 175.0,
        weightKg: 70.0,
        gender: Gender.male,
        activityLevel: ActivityLevel.moderatelyActive, // 1.55
        goal: CalorieGoal.deficitMild, // -250 kcal
      );

      final result = TdeeCalculator.calculate(profile);
      expect(result.bmr, closeTo(1673.75, 0.01));
      // TDEE = 1673.75 * 1.55 = 2594.3125
      expect(result.tdee, closeTo(2594.31, 0.1));
      // Target = 2594 - 250 = 2344
      expect(result.targetCalories, equals(2344));
      // Macros sanity check
      expect(result.macros.proteinGrams, equals(140)); // 70kg * 2
      expect(result.macros.fatGrams, greaterThan(0));
      expect(result.macros.carbsGrams, greaterThan(0));
    });
  });
}

