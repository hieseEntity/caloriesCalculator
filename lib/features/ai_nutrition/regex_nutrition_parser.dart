import 'nutrition_extractor.dart';

/// Heuristic / Regex Nutrition Parser
/// Provides instantaneous fallback parsing for standard FDA / EU / Asian nutrition fact labels
class RegexNutritionParser {
  static NutritionExtractionResult parse(String rawOcrText) {
    if (rawOcrText.trim().isEmpty) {
      return NutritionExtractionResult.empty(rawOcrText);
    }

    final lines = rawOcrText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // 1. Food name heuristic: first uppercase or non-generic title line
    String foodName = 'Food Item';
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (!lower.contains('nutrition') &&
          !lower.contains('serving') &&
          !lower.contains('amount') &&
          !lower.contains('facts') &&
          !lower.contains('percent') &&
          !lower.contains('calories') &&
          line.length > 3) {
        foodName = _cleanFoodName(line);
        break;
      }
    }

    // 2. Serving size
    String servingSize = '1 serving';
    final servingRegex = RegExp(r'serving\s*size[:\s]+([^\n\r,]+)', caseSensitive: false);
    final servingMatch = servingRegex.firstMatch(rawOcrText);
    if (servingMatch != null) {
      servingSize = servingMatch.group(1)?.trim() ?? '1 serving';
    }

    // 3. Calories: matches "Calories: 250", "Calories 250", "Energy 380 kcal", "Calories per serving 210"
    int calories = 0;
    final caloriesRegex = RegExp(r'(?:calories|energy|cal)[^\d\n]*?(\d+)(?:\s*kcal)?', caseSensitive: false);
    final caloriesMatch = caloriesRegex.firstMatch(rawOcrText);
    if (caloriesMatch != null) {
      calories = int.tryParse(caloriesMatch.group(1) ?? '0') ?? 0;
    }

    // 4. Protein: matches "Protein: 20g", "Protein 12g", "Protein 12.5 g"
    double protein = 0.0;
    final proteinRegex = RegExp(r'protein[^\d\n]*?(\d+(?:\.\d+)?)\s*g?', caseSensitive: false);
    final proteinMatch = proteinRegex.firstMatch(rawOcrText);
    if (proteinMatch != null) {
      protein = double.tryParse(proteinMatch.group(1) ?? '0') ?? 0.0;
    }

    // 5. Total Carbohydrate / Carbs
    double carbs = 0.0;
    final carbsRegex = RegExp(r'(?:total\s+carbohydrate|carbohydrates|carbs?)[^\d\n]*?(\d+(?:\.\d+)?)\s*g?', caseSensitive: false);
    final carbsMatch = carbsRegex.firstMatch(rawOcrText);
    if (carbsMatch != null) {
      carbs = double.tryParse(carbsMatch.group(1) ?? '0') ?? 0.0;
    }

    // 6. Total Fat
    double fat = 0.0;
    final fatRegex = RegExp(r'(?:total\s+fat|fats?)[^\d\n]*?(\d+(?:\.\d+)?)\s*g?', caseSensitive: false);
    final fatMatch = fatRegex.firstMatch(rawOcrText);
    if (fatMatch != null) {
      fat = double.tryParse(fatMatch.group(1) ?? '0') ?? 0.0;
    }

    double confidence = 0.5;
    if (calories > 0) confidence += 0.2;
    if (protein > 0) confidence += 0.1;
    if (carbs > 0) confidence += 0.1;
    if (fat > 0) confidence += 0.1;

    final rawJson = '''
{
  "food_name": "$foodName",
  "serving_size": "$servingSize",
  "calories": $calories,
  "protein": $protein,
  "carbs": $carbs,
  "fat": $fat
}
''';

    return NutritionExtractionResult(
      foodName: foodName,
      servingSize: servingSize,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      confidence: confidence.clamp(0.0, 1.0),
      modelUsed: 'Heuristic Label Extractor',
      rawJson: rawJson.trim(),
      rawOcrInput: rawOcrText,
    );
  }

  static String _cleanFoodName(String text) {
    var cleaned = text.replaceAll(RegExp(r'[^a-zA-Z0-9\s-]'), '').trim();
    if (cleaned.length > 30) {
      cleaned = cleaned.substring(0, 30);
    }
    return cleaned.isNotEmpty ? cleaned : 'Food Item';
  }
}

