class DailySummary {
  final String dateString;
  final int totalCalories;
  final int targetCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final int entryCount;

  const DailySummary({
    required this.dateString,
    required this.totalCalories,
    required this.targetCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.entryCount,
  });

  int get remainingCalories => targetCalories - totalCalories;
  double get progress => targetCalories > 0 ? (totalCalories / targetCalories).clamp(0.0, 1.5) : 0.0;
}

