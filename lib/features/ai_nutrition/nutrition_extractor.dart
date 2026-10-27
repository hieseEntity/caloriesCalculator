class NutritionExtractionResult {
  final String foodName;
  final String servingSize;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double confidence;
  final String modelUsed;
  final String rawJson;
  final String rawOcrInput;

  const NutritionExtractionResult({
    required this.foodName,
    required this.servingSize,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.confidence,
    required this.modelUsed,
    required this.rawJson,
    required this.rawOcrInput,
  });

  Map<String, dynamic> toJson() {
    return {
      'food_name': foodName,
      'serving_size': servingSize,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  factory NutritionExtractionResult.empty(String ocrInput) {
    return NutritionExtractionResult(
      foodName: 'Food Item',
      servingSize: '1 serving',
      calories: 0,
      protein: 0.0,
      carbs: 0.0,
      fat: 0.0,
      confidence: 0.0,
      modelUsed: 'None',
      rawJson: '{}',
      rawOcrInput: ocrInput,
    );
  }
}

abstract class AiNutritionExtractor {
  Future<NutritionExtractionResult> extractNutrition(String rawOcrText);
}

