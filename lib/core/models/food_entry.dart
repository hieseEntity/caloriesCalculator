class FoodEntry {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime timestamp;
  final String dateString; // 'YYYY-MM-DD' for grouping and roll-over
  final String? imagePath;
  final String? rawOcrText;

  const FoodEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.timestamp,
    required this.dateString,
    this.imagePath,
    this.rawOcrText,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'timestamp': timestamp.toIso8601String(),
      'dateString': dateString,
      'imagePath': imagePath,
      'rawOcrText': rawOcrText,
    };
  }

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    return FoodEntry(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Meal',
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      dateString: map['dateString'] as String? ?? '',
      imagePath: map['imagePath'] as String?,
      rawOcrText: map['rawOcrText'] as String?,
    );
  }

  FoodEntry copyWith({
    String? id,
    String? name,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    DateTime? timestamp,
    String? dateString,
    String? imagePath,
    String? rawOcrText,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      timestamp: timestamp ?? this.timestamp,
      dateString: dateString ?? this.dateString,
      imagePath: imagePath ?? this.imagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
    );
  }
}

