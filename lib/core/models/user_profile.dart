enum Gender { male, female }

enum ActivityLevel {
  sedentary(1.2, 'Sedentary (Little or no exercise)'),
  lightlyActive(1.375, 'Lightly Active (Exercise 1-3 days/week)'),
  moderatelyActive(1.55, 'Moderately Active (Exercise 3-5 days/week)'),
  veryActive(1.725, 'Very Active (Hard exercise 6-7 days/week)'),
  extraActive(1.9, 'Extra Active (Very hard exercise & physical job)');

  final double factor;
  final String label;
  const ActivityLevel(this.factor, this.label);
}

enum CalorieGoal {
  deficitExtreme(-500, 'Weight Loss (-500 kcal/day)'),
  deficitMild(-250, 'Mild Weight Loss (-250 kcal/day)'),
  maintenance(0, 'Maintain Weight (0 kcal/day)'),
  surplusMild(250, 'Mild Muscle Gain (+250 kcal/day)'),
  surplusExtreme(500, 'Muscle Gain (+500 kcal/day)');

  final int calorieAdjustment;
  final String label;
  const CalorieGoal(this.calorieAdjustment, this.label);
}

class UserProfile {
  final int age;
  final double heightCm;
  final double weightKg;
  final Gender gender;
  final ActivityLevel activityLevel;
  final CalorieGoal goal;

  const UserProfile({
    this.age = 25,
    this.heightCm = 175.0,
    this.weightKg = 70.0,
    this.gender = Gender.male,
    this.activityLevel = ActivityLevel.moderatelyActive,
    this.goal = CalorieGoal.maintenance,
  });

  UserProfile copyWith({
    int? age,
    double? heightCm,
    double? weightKg,
    Gender? gender,
    ActivityLevel? activityLevel,
    CalorieGoal? goal,
  }) {
    return UserProfile(
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'gender': gender.name,
      'activityLevel': activityLevel.name,
      'goal': goal.name,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      age: json['age'] as int? ?? 25,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 175.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 70.0,
      gender: Gender.values.firstWhere(
        (g) => g.name == json['gender'],
        orElse: () => Gender.male,
      ),
      activityLevel: ActivityLevel.values.firstWhere(
        (a) => a.name == json['activityLevel'],
        orElse: () => ActivityLevel.moderatelyActive,
      ),
      goal: CalorieGoal.values.firstWhere(
        (g) => g.name == json['goal'],
        orElse: () => CalorieGoal.maintenance,
      ),
    );
  }
}

