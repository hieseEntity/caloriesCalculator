import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:calories_calculator/features/ocr/tesseract_ocr_engine.dart';
import 'package:calories_calculator/features/ai_nutrition/regex_nutrition_parser.dart';

void main() {
  test('OCR accurately reads and extracts nutrition from TestImage/images.jpg', () async {
    final imageFile = File('TestImage/images.jpg');
    expect(await imageFile.exists(), isTrue, reason: 'TestImage/images.jpg must exist');

    final ocrEngine = TesseractOcrEngine();
    final ocrResult = await ocrEngine.processImage(imageFile.path);

    expect(ocrResult.rawText.isNotEmpty, isTrue, reason: 'OCR must not return empty text');

    // Parse extracted text
    final nutrition = RegexNutritionParser.parse(ocrResult.rawText);

    expect(nutrition.calories, equals(80), reason: 'Must detect 80 calories from test image');
    expect(nutrition.carbs, equals(19.0), reason: 'Must detect 19g carbs (from Sugars) from test image');
    expect(nutrition.servingSize, contains('1 Can'));
  });
}
