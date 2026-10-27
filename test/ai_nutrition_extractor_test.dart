import 'package:flutter_test/flutter_test.dart';
import 'package:calories_calculator/features/ai_nutrition/prompt_templates.dart';
import 'package:calories_calculator/features/ai_nutrition/regex_nutrition_parser.dart';
import 'package:calories_calculator/features/ai_nutrition/qwen_llm_service.dart';

void main() {
  group('AI Calorie & Macro Extraction Tests', () {
    const sampleLabelOcr = '''
PROTEIN CRUNCH BAR
Nutrition Facts
Serving Size: 1 Bar (60g)
Calories: 210
Total Fat: 7g (9% DV)
Total Carbohydrate: 22g (8% DV)
Protein: 20g
''';

    const multiItemOcr = '''
HEALTHY LUNCH COMBO
Item 1: Grilled Chicken Bowl
Calories: 450 kcal
Protein: 38g
Carbs: 45g
Fat: 12g

Item 2: Greek Yogurt & Berries
Calories: 150 kcal
Protein: 15g
Carbs: 18g
Fat: 2g
''';

    const missingCaloriesOcr = '''
HOMEMADE ENERGY BOWL
Protein: 25g
Total Carbohydrate: 50g
Total Fat: 10g
''';

    test('RegexNutritionParser extracts macros correctly from single-item OCR text', () {
      final result = RegexNutritionParser.parse(sampleLabelOcr);

      expect(result.foodName, contains('PROTEIN CRUNCH BAR'));
      expect(result.servingSize, contains('1 Bar (60g)'));
      expect(result.calories, equals(210));
      expect(result.fat, equals(7.0));
      expect(result.carbs, equals(22.0));
      expect(result.protein, equals(20.0));
      expect(result.confidence, greaterThanOrEqualTo(0.8));
    });

    test('RegexNutritionParser calculates sum across multiple items in OCR text', () {
      final result = RegexNutritionParser.parse(multiItemOcr);

      // 450 + 150 = 600 kcal
      expect(result.calories, equals(600));
      // 38 + 15 = 53g protein
      expect(result.protein, equals(53.0));
      // 45 + 18 = 63g carbs
      expect(result.carbs, equals(63.0));
      // 12 + 2 = 14g fat
      expect(result.fat, equals(14.0));
      expect(result.calculationNotes, contains('Summed 2 items'));
      expect(result.calculationNotes, contains('450 + 150 = 600 kcal'));
    });

    test('RegexNutritionParser calculates total calories via Atwater formula when calories are missing', () {
      final result = RegexNutritionParser.parse(missingCaloriesOcr);

      // (25 * 4) + (50 * 4) + (10 * 9) = 100 + 200 + 90 = 390 kcal
      expect(result.calories, equals(390));
      expect(result.protein, equals(25.0));
      expect(result.carbs, equals(50.0));
      expect(result.fat, equals(10.0));
      expect(result.calculationNotes, contains('Atwater formula'));
    });

    test('PromptTemplates formats Qwen2.5 ChatML with calculation instructions', () {
      final prompt = PromptTemplates.buildQwenChatMlPrompt('Sample OCR');

      expect(prompt, contains('<|im_start|>system'));
      expect(prompt, contains('CALCULATE the TOTAL nutritional values'));
      expect(prompt, contains('ATWATER CALORIE CROSS-CHECK'));
      expect(prompt, contains('<|im_start|>user'));
      expect(prompt, contains('Sample OCR'));
      expect(prompt, contains('<|im_start|>assistant'));
    });

    test('QwenNutritionExtractor completes end-to-end extraction with calculation notes', () async {
      final extractor = QwenNutritionExtractor();
      final result = await extractor.extractNutrition(multiItemOcr);

      expect(result.calories, equals(600));
      expect(result.protein, equals(53.0));
      expect(result.carbs, equals(63.0));
      expect(result.fat, equals(14.0));
      expect(result.modelUsed, contains('Qwen2.5-0.5B-Instruct'));
      expect(result.calculationNotes, isNotNull);
    });
  });
}
