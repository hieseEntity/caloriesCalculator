import 'package:flutter_test/flutter_test.dart';
import 'package:calories_calculator/features/ai_nutrition/prompt_templates.dart';
import 'package:calories_calculator/features/ai_nutrition/regex_nutrition_parser.dart';
import 'package:calories_calculator/features/ai_nutrition/qwen_llm_service.dart';

void main() {
  group('AI Total Calorie Extraction Tests', () {
    const cocaWithTotalOcr = '''
COCA COLA ORIGINAL
Nutrition Facts
100 kcal per 100ml
Thể tích thực: 500ml
''';

    const cocaWithoutTotalOcr = '''
COCA COLA ORIGINAL
Nutrition Facts
100 kcal per 100ml
''';

    const singleBarOcr = '''
PROTEIN CRUNCH BAR
Nutrition Facts
Serving Size: 1 Bar (60g)
Calories: 210 kcal
''';

    test('Coca with total in image: calculates 100 kcal/100ml x 500ml = 500 kcal total', () {
      final result = RegexNutritionParser.parse(cocaWithTotalOcr);

      expect(result.foodName, contains('COCA COLA'));
      expect(result.caloriesPerServing, equals(100));
      expect(result.totalProductQuantity, equals(500.0));
      expect(result.hasTotalQuantity, isTrue);
      // 100 * (500 / 100) = 500 kcal
      expect(result.calories, equals(500));
      expect(result.calculationNotes, contains('500 kcal'));
    });

    test('Coca without total in image: flags missing total and calculates 500 kcal when user inputs 500ml', () {
      final result = RegexNutritionParser.parse(cocaWithoutTotalOcr);

      expect(result.foodName, contains('COCA COLA'));
      expect(result.caloriesPerServing, equals(100));
      expect(result.hasTotalQuantity, isFalse);
      expect(result.calories, equals(0), reason: 'Must be 0 until user inputs total volume');

      // User inputs 500ml
      final calculated = result.copyWithTotalQuantity(500, newUnit: 'ml');
      expect(calculated.calories, equals(500));
      expect(calculated.hasTotalQuantity, isTrue);
      expect(calculated.totalProductQuantity, equals(500.0));
      expect(calculated.calculationNotes, contains('500 kcal'));
    });

    test('RegexNutritionParser extracts calories correctly from single container item', () {
      final result = RegexNutritionParser.parse(singleBarOcr);

      expect(result.foodName, contains('PROTEIN CRUNCH BAR'));
      expect(result.calories, equals(210));
      expect(result.hasTotalQuantity, isTrue);
    });

    test('PromptTemplates formats Qwen2.5 ChatML with TOTAL product calorie instructions', () {
      final prompt = PromptTemplates.buildQwenChatMlPrompt('Sample OCR');

      expect(prompt, contains('<|im_start|>system'));
      expect(prompt, contains('TOTAL CALORIES OF THE ENTIRE PRODUCT'));
      expect(prompt, contains('FOCUS EXCLUSIVELY ON CALORIES'));
      expect(prompt, contains('<|im_start|>user'));
      expect(prompt, contains('Sample OCR'));
      expect(prompt, contains('<|im_start|>assistant'));
    });

    test('QwenNutritionExtractor completes end-to-end extraction with Coca calculation', () async {
      final extractor = QwenNutritionExtractor();
      final result = await extractor.extractNutrition(cocaWithTotalOcr);

      expect(result.calories, equals(500));
      expect(result.totalProductQuantity, equals(500.0));
      expect(result.hasTotalQuantity, isTrue);
    });
  });
}
