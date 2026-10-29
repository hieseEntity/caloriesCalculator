import 'package:flutter_test/flutter_test.dart';
import 'package:calories_calculator/features/ai_nutrition/prompt_templates.dart';
import 'package:calories_calculator/features/ai_nutrition/regex_nutrition_parser.dart';
import 'package:calories_calculator/features/ai_nutrition/qwen_llm_service.dart';

void main() {
  group('AI Total Calorie Extraction Tests', () {
    const singleBarOcr = '''
PROTEIN CRUNCH BAR
Nutrition Facts
Serving Size: 1 Bar (60g)
Calories: 210 kcal
''';

    const netWeightProductOcr = '''
KHOAI TÂY SẤY GIÒN
Thông tin dinh dưỡng
Khẩu phần: 100g
Năng lượng: 400 kcal
Khối lượng tịnh: 250g
''';

    const missingNetWeightOcr = '''
BÁNH QUY BƠ PHÁP
Thông tin dinh dưỡng
Khẩu phần: 100g
Năng lượng: 350 kcal
''';

    test('RegexNutritionParser extracts calories correctly from single-item OCR text', () {
      final result = RegexNutritionParser.parse(singleBarOcr);

      expect(result.foodName, contains('PROTEIN CRUNCH BAR'));
      expect(result.servingSize, contains('1 Bar (60g)'));
      expect(result.calories, equals(210));
      expect(result.hasTotalQuantity, isTrue);
    });

    test('RegexNutritionParser automatically calculates total calories from Net Weight', () {
      final result = RegexNutritionParser.parse(netWeightProductOcr);

      // 400 kcal per 100g * (250g / 100g) = 1000 kcal total
      expect(result.calories, equals(1000));
      expect(result.hasTotalQuantity, isTrue);
      expect(result.totalProductQuantity, equals(250.0));
      expect(result.calculationNotes, contains('1000 kcal tổng'));
    });

    test('RegexNutritionParser flags missing total weight and allows user recalculation', () {
      final result = RegexNutritionParser.parse(missingNetWeightOcr);

      expect(result.calories, equals(350));
      expect(result.hasTotalQuantity, isFalse);
      expect(result.calculationNotes, contains('Chưa nhận diện được tổng khối lượng'));

      // User enters 200g
      final updated = result.copyWithTotalQuantity(200);
      expect(updated.calories, equals(700)); // 350 * 2 = 700 kcal
      expect(updated.hasTotalQuantity, isTrue);
      expect(updated.totalProductQuantity, equals(200.0));
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

    test('QwenNutritionExtractor completes end-to-end extraction focusing on calories', () async {
      final extractor = QwenNutritionExtractor();
      final result = await extractor.extractNutrition(netWeightProductOcr);

      expect(result.calories, equals(1000));
      expect(result.totalProductQuantity, equals(250.0));
      expect(result.hasTotalQuantity, isTrue);
    });
  });
}
