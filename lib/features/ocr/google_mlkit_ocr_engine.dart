import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'ocr_service.dart';

/// ============================================================
/// Google ML Kit OCR Engine — Nhận diện chữ trên Android/iOS
/// ============================================================
///
/// Dùng Google ML Kit Text Recognition để nhận diện chữ từ ảnh.
/// Chạy hoàn toàn ON-DEVICE — không cần internet, bảo mật dữ liệu.
///
/// Nền tảng hỗ trợ:
///   - Android: ✅ (yêu cầu Google Play Services)
///   - iOS:     ✅ (Core ML)
///   - Linux/Desktop: ⚠️ Dùng chế độ mock/demo (không có ML Kit native)
///
/// Được dùng bởi [OcrEngineFactory.create()] khi chạy trên Android/iOS.
class GoogleMlKitOcrEngine implements OcrEngine {
  // Script OCR — mặc định Latin (hỗ trợ tiếng Anh, tiếng Việt Latin)
  final TextRecognitionScript script;

  // Tên hiển thị trong UI và telemetry
  final String modelName;

  GoogleMlKitOcrEngine({
    this.script = TextRecognitionScript.latin,
    this.modelName = 'Google ML Kit Text Recognition',
  });

  // ------------------------------------------------------------------
  // Hàm chính: nhận đường dẫn ảnh, trả về OcrResult
  // ------------------------------------------------------------------
  @override
  Future<OcrResult> processImage(String imagePath) async {
    final stopwatch = Stopwatch()..start();
    final file = File(imagePath);

    // Kiểm tra file ảnh tồn tại trước khi xử lý
    if (!await file.exists()) {
      stopwatch.stop();
      return OcrResult(
        rawText: '',
        blocks: [],
        latencyMs: stopwatch.elapsedMilliseconds,
        engine: modelName,
      );
    }

    // --- Nhánh Mobile (Android / iOS) ---
    // Thực thi Google ML Kit native on-device inference
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final textRecognizer = TextRecognizer(script: script);
      try {
        // Chuyển đường dẫn ảnh thành InputImage cho ML Kit
        final inputImage = InputImage.fromFilePath(imagePath);

        // Gọi ML Kit nhận diện văn bản — async, chạy trên native thread
        final recognizedText = await textRecognizer.processImage(inputImage);

        // Chuyển kết quả ML Kit sang OcrTextBlock để đồng nhất với interface
        final blocks = recognizedText.blocks.map((b) {
          final rect = b.boundingBox;
          return OcrTextBlock(
            text: b.text,
            confidence: 0.98, // ML Kit có accuracy cao, tạm hardcode 98%
            boundingBox: [rect.left, rect.top, rect.width, rect.height],
          );
        }).toList();

        stopwatch.stop();
        return OcrResult(
          rawText: recognizedText.text,
          blocks: blocks,
          latencyMs: stopwatch.elapsedMilliseconds,
          engine: modelName,
        );
      } finally {
        // QUAN TRỌNG: phải close TextRecognizer để giải phóng native resources
        await textRecognizer.close();
      }
    }

    // --- Nhánh Desktop/Test (Linux, Windows, macOS, Web) ---
    // ML Kit native không có sẵn trên desktop — dùng mock data để demo/test
    String rawExtracted = '';

    // Nếu có file .txt companion (dùng cho integration test),
    // đọc nội dung từ đó thay vì mock
    final companionTextFile = File('$imagePath.txt');
    if (await companionTextFile.exists()) {
      rawExtracted = await companionTextFile.readAsString();
    } else {
      // Sinh mock data theo tên file để demo các trường hợp khác nhau
      rawExtracted = _generateContextualMock(file.path);
    }

    // Tách thành các block theo dòng
    final blocks = rawExtracted
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .map((l) => OcrTextBlock(text: l.trim(), confidence: 0.95))
        .toList();

    stopwatch.stop();
    return OcrResult(
      rawText: rawExtracted,
      blocks: blocks,
      latencyMs: stopwatch.elapsedMilliseconds.clamp(60, 200),
      engine: modelName,
    );
  }

  // ------------------------------------------------------------------
  // Mock data generator — tạo nutrition text giả để test/demo trên desktop
  // Dựa vào tên file ảnh để trả về dữ liệu phù hợp với kịch bản demo
  // ------------------------------------------------------------------
  String _generateContextualMock(String path) {
    final lower = path.toLowerCase();

    // Kịch bản 1: Combo bữa trưa lành mạnh
    if (lower.contains('combo') || lower.contains('lunch') || lower.contains('salad')) {
      return '''
HEALTHY LUNCH COMBO
Items:
1x Grilled Chicken Bowl
Calories: 450 kcal
Protein: 38g
Carbs: 45g
Fat: 12g

1x Greek Yogurt & Berries
Calories: 150 kcal
Protein: 15g
Carbs: 18g
Fat: 2g
''';
    }
    // Kịch bản 2: Protein bar / snack
    else if (lower.contains('snack') || lower.contains('bar') || lower.contains('protein')) {
      return '''
PROTEIN CRUNCH BAR
Nutrition Facts
Serving Size: 1 Bar (60g)
Calories: 210
Total Fat: 7g
Total Carbohydrate: 22g
Dietary Fiber: 10g
Protein: 20g
''';
    }
    // Kịch bản mặc định: Oatmeal
    else {
      return '''
OATMEAL ENERGY PACK
Nutrition Facts
Serving Size: 1 Container
Calories: 260
Total Fat: 5g
Total Carbohydrate: 44g
Protein: 10g
''';
    }
  }
}
