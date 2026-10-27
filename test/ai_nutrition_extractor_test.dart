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

    test('RegexNutritionParser extracts macros correctly from OCR text', () {
      final result = RegexNutritionParser.parse(sampleLabelOcr);

      expect(result.foodName, contains('PROTEIN CRUNCH BAR'));
      expect(result.servingSize, contains('1 Bar (60g)'));
      expect(result.calories, equals(210));
      expect(result.fat, equals(7.0));
      expect(result.carbs, equals(22.0));
      expect(result.protein, equals(20.0));
      expect(result.confidence, greaterThanOrEqualTo(0.8));
    });

    test('PromptTemplates formats Qwen2.5 ChatML correctly', () {
      final prompt = PromptTemplates.buildQwenChatMlPrompt('Sample OCR');

      expect(prompt, contains('<|im_start|>system'));
      expect(prompt, contains('<|im_start|>user'));
      expect(prompt, contains('Sample OCR'));
      expect(prompt, contains('<|im_start|>assistant'));
    });

    test('QwenNutritionExtractor completes end-to-end extraction', () async {
      final extractor = QwenNutritionExtractor();
      final result = await extractor.extractNutrition(sampleLabelOcr);

      expect(result.calories, equals(210));
      expect(result.protein, equals(20.0));
      expect(result.carbs, equals(22.0));
      expect(result.fat, equals(7.0));
      expect(result.modelUsed, contains('Qwen2.5-0.5B-Instruct'));
    });
  });
}

