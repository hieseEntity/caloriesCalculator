import '../../core/models/user_profile.dart';

class MacroTargets {
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;

  const MacroTargets({
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });
}

class TdeeCalculationResult {
  final double bmr;
  final double tdee;
  final int targetCalories;
  final MacroTargets macros;

  const TdeeCalculationResult({
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
    required this.macros,
  });
}

/// Phase 1: Mifflin-St Jeor Equation Engine
class TdeeCalculator {
  /// Calculate Basal Metabolic Rate (BMR) using Mifflin-St Jeor formula
  /// Male: 10 * weight (kg) + 6.25 * height (cm) - 5 * age (y) + 5
  /// Female: 10 * weight (kg) + 6.25 * height (cm) - 5 * age (y) - 161
  static double calculateBmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
  }) {
    final base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age);
    return gender == Gender.male ? base + 5.0 : base - 161.0;
  }

  /// Calculate Total Daily Energy Expenditure (TDEE) = BMR * Activity Factor
  static double calculateTdee({
    required double bmr,
    required ActivityLevel activityLevel,
  }) {
    return bmr * activityLevel.factor;
  }

  /// Full calculation returning BMR, TDEE, Adjusted Target, and Macro distributions
  static TdeeCalculationResult calculate(UserProfile profile) {
    final bmr = calculateBmr(
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
      age: profile.age,
      gender: profile.gender,
    );

    final tdee = calculateTdee(
      bmr: bmr,
      activityLevel: profile.activityLevel,
    );

    // Apply deficit or surplus goal
    final adjustedCalories = (tdee + profile.goal.calorieAdjustment).round();
    final targetCalories = adjustedCalories < 1200 ? 1200 : adjustedCalories;

    // Macro breakdown based on standard athletic nutrition:
    // Protein: ~2.0g per kg of bodyweight (4 kcal/g)
    // Fat: ~25% of total calories (9 kcal/g)
    // Carbs: Remainder of calories (4 kcal/g)
    final proteinGrams = (profile.weightKg * 2.0).round();
    final proteinCalories = proteinGrams * 4;

    final fatCalories = (targetCalories * 0.25).round();
    final fatGrams = (fatCalories / 9.0).round();

    final remainingCalories = targetCalories - proteinCalories - fatCalories;
    final carbsCalories = remainingCalories > 0 ? remainingCalories : 0;
    final carbsGrams = (carbsCalories / 4.0).round();

    return TdeeCalculationResult(
      bmr: bmr,
      tdee: tdee,
      targetCalories: targetCalories,
      macros: MacroTargets(
        proteinGrams: proteinGrams,
        carbsGrams: carbsGrams,
        fatGrams: fatGrams,
      ),
    );
  }
}

