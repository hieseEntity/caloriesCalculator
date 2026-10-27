import 'nutrition_extractor.dart';

/// Heuristic & Arithmetic Nutrition Parser
/// Calculates total cumulative nutrients from single-item labels, multi-item receipts, or meal combos.
class RegexNutritionParser {
  static NutritionExtractionResult parse(String rawOcrText) {
    if (rawOcrText.trim().isEmpty) {
      return NutritionExtractionResult.empty(rawOcrText);
    }

    final lines = rawOcrText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // 1. Food title heuristic
    String foodName = 'Food Item';
    final nonGenericLines = <String>[];
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (!lower.contains('nutrition') &&
          !lower.contains('serving') &&
          !lower.contains('amount') &&
          !lower.contains('facts') &&
          !lower.contains('percent') &&
          !lower.contains('calories') &&
          !lower.contains('total') &&
          !lower.contains('daily') &&
          line.length > 3) {
        nonGenericLines.add(_cleanFoodName(line));
      }
    }

    if (nonGenericLines.isNotEmpty) {
      if (nonGenericLines.length == 1) {
        foodName = nonGenericLines.first;
      } else if (nonGenericLines.length > 1) {
        foodName = nonGenericLines.take(2).join(' + ');
      }
    }

    // 2. Serving size & servings per container multiplier
    String servingSize = '1 serving';
    final servingRegex = RegExp(r'serving\s*size[:\s]+([^\n\r,]+)', caseSensitive: false);
    final servingMatch = servingRegex.firstMatch(rawOcrText);
    if (servingMatch != null) {
      servingSize = servingMatch.group(1)?.trim() ?? '1 serving';
    }

    int servingMultiplier = 1;
    final containerServingsRegex = RegExp(
      r'(?:servings?\s+per\s+container|about\s+(\d+)\s+servings?)[:\s]*(\d+)?',
      caseSensitive: false,
    );
    final containerMatch = containerServingsRegex.firstMatch(rawOcrText);
    if (containerMatch != null) {
      final s = containerMatch.group(1) ?? containerMatch.group(2);
      if (s != null) {
        servingMultiplier = int.tryParse(s) ?? 1;
      }
    }

    // 3. Multi-item Calorie Detection & Summation
    final caloriesRegex = RegExp(
      r'(?:calories|energy|cal)[^\d\n]*?(\d+)(?:\s*kcal)?',
      caseSensitive: false,
    );
    final calorieMatches = caloriesRegex.allMatches(rawOcrText).toList();

    int totalCalories = 0;
    final List<int> individualCalories = [];
    for (final m in calorieMatches) {
      final val = int.tryParse(m.group(1) ?? '0') ?? 0;
      if (val > 0) {
        individualCalories.add(val);
      }
    }

    // 4. Multi-item Macronutrient Detection & Summation
    // Protein
    final proteinRegex = RegExp(
      r'(?:protein)[^\d\n]*?(\d+(?:\.\d+)?)\s*g?',
      caseSensitive: false,
    );
    final proteinMatches = proteinRegex.allMatches(rawOcrText).toList();
    double totalProtein = 0.0;
    for (final m in proteinMatches) {
      totalProtein += double.tryParse(m.group(1) ?? '0') ?? 0.0;
    }

    // Carbohydrates
    final carbsRegex = RegExp(
      r'(?:total\s+carbohydrate|carbohydrates|carbs?)[^\d\n]*?(\d+(?:\.\d+)?)\s*g?',
      caseSensitive: false,
    );
    final carbsMatches = carbsRegex.allMatches(rawOcrText).toList();
    double totalCarbs = 0.0;
    for (final m in carbsMatches) {
      totalCarbs += double.tryParse(m.group(1) ?? '0') ?? 0.0;
    }

    // Total Fat
    final fatRegex = RegExp(
      r'(?:total\s+fat|fats?)[^\d\n]*?(\d+(?:\.\d+)?)\s*g?',
      caseSensitive: false,
    );
    final fatMatches = fatRegex.allMatches(rawOcrText).toList();
    double totalFat = 0.0;
    for (final m in fatMatches) {
      totalFat += double.tryParse(m.group(1) ?? '0') ?? 0.0;
    }

    // 5. Calculate cumulative total or single item
    String calculationNotes = '';
    if (individualCalories.length > 1) {
      // Multiple items found: calculate sum
      totalCalories = individualCalories.reduce((a, b) => a + b);
      calculationNotes = 'Summed ${individualCalories.length} items: '
          '${individualCalories.join(" + ")} = $totalCalories kcal';
    } else if (individualCalories.length == 1) {
      totalCalories = individualCalories.first;
      calculationNotes = 'Extracted single item: $totalCalories kcal';
      if (servingMultiplier > 1) {
        calculationNotes += ' ($servingMultiplier servings/container available)';
      }
    }

    // 6. Atwater Calorie Calculation fallback if calories not explicit
    if (totalCalories == 0 && (totalProtein > 0 || totalCarbs > 0 || totalFat > 0)) {
      totalCalories = ((totalProtein * 4) + (totalCarbs * 4) + (totalFat * 9)).round();
      calculationNotes = 'Calculated via Atwater formula: '
          '(${totalProtein.toInt()}g P × 4) + (${totalCarbs.toInt()}g C × 4) + (${totalFat.toInt()}g F × 9) = $totalCalories kcal';
    }

    double confidence = 0.5;
    if (totalCalories > 0) confidence += 0.25;
    if (totalProtein > 0) confidence += 0.1;
    if (totalCarbs > 0) confidence += 0.1;
    if (totalFat > 0) confidence += 0.05;

    final rawJson = '''
{
  "food_name": "$foodName",
  "serving_size": "$servingSize",
  "calories": $totalCalories,
  "protein": $totalProtein,
  "carbs": $totalCarbs,
  "fat": $totalFat,
  "calculation_notes": "$calculationNotes"
}
''';

    return NutritionExtractionResult(
      foodName: foodName,
      servingSize: servingSize,
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      confidence: confidence.clamp(0.0, 1.0),
      modelUsed: 'Heuristic & Arithmetic Extractor',
      rawJson: rawJson.trim(),
      rawOcrInput: rawOcrText,
      calculationNotes: calculationNotes,
    );
  }

  static String _cleanFoodName(String text) {
    var cleaned = text.replaceAll(RegExp(r'[^a-zA-Z0-9\s-]'), '').trim();
    if (cleaned.length > 35) {
      cleaned = cleaned.substring(0, 35);
    }
    return cleaned.isNotEmpty ? cleaned : 'Food Item';
  }
}
