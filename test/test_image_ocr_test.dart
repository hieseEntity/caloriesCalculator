import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:calories_calculator/features/ocr/paddle_ocr_desktop_engine.dart';
import 'package:calories_calculator/features/ai_nutrition/regex_nutrition_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('OCR accurately reads and extracts nutrition from TestImage/images.jpg', () async {
    final imageFile = File('TestImage/images.jpg');
    expect(await imageFile.exists(), isTrue, reason: 'TestImage/images.jpg must exist');

    final ocrEngine = PaddleOcrDesktopEngine();
    final ocrResult = await ocrEngine.processImage(imageFile.path);

    expect(ocrResult.rawText.isNotEmpty, isTrue, reason: 'OCR must not return empty text');

    // Parse extracted text
    final nutrition = RegexNutritionParser.parse(ocrResult.rawText);

    expect(nutrition.calories, equals(80), reason: 'Must detect 80 calories from test image');
    expect(nutrition.servingSize, contains('1 Can'));
    expect(nutrition.hasTotalQuantity, isTrue, reason: '1 Can is a complete single product container');
  });
}
