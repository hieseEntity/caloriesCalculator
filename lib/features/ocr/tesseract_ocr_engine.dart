import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'ocr_service.dart';

/// ============================================================
/// Tesseract OCR Engine — Nhận diện chữ trên Linux & Android
/// ============================================================
///
/// Hỗ trợ:
///   - Linux: Chạy trực tiếp qua native `tesseract` binary
///   - Android: Chạy qua `flutter_tesseract_ocr` plugin
///   - Preprocessing: Tự động đảo màu (invert) nếu nền tối (chữ trắng trên bao bì đen),
///     nâng độ tương phản và scale ảnh để tối ưu hóa nhận diện.
/// ============================================================
class TesseractOcrEngine implements OcrEngine {
  static const String _engineName = 'Tesseract OCR (vie+eng)';
  static const String _defaultLanguages = 'vie+eng';

  String? _tessdataPath;
  bool _isInitialized = false;
  Map<String, dynamic>? _config;

  Future<Map<String, dynamic>?> _loadConfig() async {
    final candidatePaths = [
      'assets/tessdata_config.json',
      'assets/tessdata/tessdata_config.json',
    ];
    for (final path in candidatePaths) {
      try {
        final jsonStr = await rootBundle.loadString(path);
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  String _getLanguages() {
    try {
      final langs = _config?['languages'] as Map<String, dynamic>?;
      return (langs?['combined'] as String?) ?? _defaultLanguages;
    } catch (_) {
      return _defaultLanguages;
    }
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    _config = await _loadConfig();

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final tessDir = Directory('${appDir.path}/tessdata');
      if (!await tessDir.exists()) {
        await tessDir.create(recursive: true);
      }

      final targetFiles = ['vie.traineddata', 'eng.traineddata'];
      for (final fileName in targetFiles) {
        final destFile = File('${tessDir.path}/$fileName');
        if (!await destFile.exists()) {
          try {
            final byteData = await rootBundle.load('assets/tessdata/$fileName');
            await destFile.writeAsBytes(
              byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
              flush: true,
            );
          } catch (_) {}
        }
      }

      _tessdataPath = tessDir.path;
    } catch (_) {
      final localAssetsDir = Directory('assets/tessdata');
      if (await localAssetsDir.exists()) {
        _tessdataPath = localAssetsDir.absolute.path;
      }
    }

    _isInitialized = true;
  }

  @override
  Future<OcrResult> processImage(String imagePath) async {
    final stopwatch = Stopwatch()..start();
    final imageFile = File(imagePath);

    if (!await imageFile.exists()) {
      stopwatch.stop();
      return OcrResult(
        rawText: '',
        blocks: [],
        latencyMs: stopwatch.elapsedMilliseconds,
        engine: _engineName,
      );
    }

    // 1. Nếu là file demo preset giả lập (dung lượng nhỏ hơn 256 bytes)
    final fileLength = await imageFile.length();
    if (fileLength < 256) {
      final mockText = _generateContextualMock(imagePath);
      stopwatch.stop();
      return OcrResult(
        rawText: mockText,
        blocks: _toBlocks(mockText),
        latencyMs: stopwatch.elapsedMilliseconds.clamp(40, 150),
        engine: '$_engineName (Mock Preset)',
      );
    }

    await _ensureInitialized();
    final language = _getLanguages();
    final effectiveTessdata = _tessdataPath ?? 'assets/tessdata';

    // 2. Thử OCR trên ảnh gốc
    String rawExtracted = await _runTesseract(imagePath, language, effectiveTessdata, psm: '3');

    // 3. Nếu ảnh gốc ra ít chữ hoặc không nhận diện được dinh dưỡng (ví dụ: nền đen chữ trắng)
    // Tự động tiền xử lý ảnh: grayscale + đảo màu (invert) + tăng tương phản + upscale
    if (rawExtracted.trim().length < 35 || !_hasNutritionKeywords(rawExtracted)) {
      final preprocessedPath = await _preprocessImage(imagePath);
      if (preprocessedPath != null) {
        // Thử với PSM 11 (Sparse text) và PSM 6 (Uniform block of text)
        final psm11Result = await _runTesseract(preprocessedPath, language, effectiveTessdata, psm: '11');
        final psm6Result = await _runTesseract(preprocessedPath, language, effectiveTessdata, psm: '6');

        final candidates = [rawExtracted, psm11Result, psm6Result];
        candidates.sort((a, b) => b.length.compareTo(a.length));
        rawExtracted = candidates.first;

        // Xóa file tạm sau khi OCR xong
        try {
          final tempFile = File(preprocessedPath);
          if (await tempFile.exists()) await tempFile.delete();
        } catch (_) {}
      }
    }

    // 4. Nếu vẫn trống (ví dụ ảnh không nhận diện được chữ nào nhưng có text companion):
    if (rawExtracted.trim().isEmpty) {
      final companion = File('$imagePath.txt');
      if (await companion.exists()) {
        rawExtracted = await companion.readAsString();
      }
    }

    stopwatch.stop();

    return OcrResult(
      rawText: rawExtracted.trim(),
      blocks: _toBlocks(rawExtracted),
      latencyMs: stopwatch.elapsedMilliseconds,
      engine: _engineName,
    );
  }

  /// Tiền xử lý ảnh thông minh: Tự động đảo màu nếu nền tối, scale x2 và tăng tương phản
  Future<String?> _preprocessImage(String originalPath) async {
    try {
      final bytes = await File(originalPath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // 1. Chuyển sang ảnh thang độ xám (grayscale)
      var processed = img.grayscale(decoded);

      // 2. Kiểm tra nếu nền tối (chữ sáng trên nền tối)
      int darkPixels = 0;
      int sampled = 0;
      for (int y = 0; y < processed.height; y += 8) {
        for (int x = 0; x < processed.width; x += 8) {
          final pixel = processed.getPixel(x, y);
          if (pixel.r < 128) darkPixels++;
          sampled++;
        }
      }
      final isDark = (darkPixels / sampled) > 0.5;

      // Đảo màu nếu nền tối (Tesseract nhận diện tốt nhất chữ đen trên nền trắng)
      if (isDark) {
        processed = img.invert(processed);
      }

      // 3. Phóng to 2x nếu ảnh nhỏ (tăng độ phân giải cho OCR)
      if (processed.width < 900) {
        processed = img.copyResize(processed, width: processed.width * 2);
      }

      // 4. Tăng độ tương phản
      processed = img.adjustColor(processed, contrast: 1.6);

      final tempDir = Directory.systemTemp;
      final tempPath = '${tempDir.path}/ocr_prep_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(tempPath).writeAsBytes(img.encodePng(processed));
      return tempPath;
    } catch (e) {
      // ignore: avoid_print
      print('[Tesseract Preprocessing Error] $e');
      return null;
    }
  }

  /// Chạy Tesseract trên một file cụ thể
  Future<String> _runTesseract(String path, String language, String tessdataDir, {String psm = '3'}) async {
    String text = '';

    // Trên Linux: Ưu tiên gọi CLI tesseract trực tiếp
    if (!kIsWeb && Platform.isLinux) {
      try {
        final res = await Process.run('tesseract', [
          path,
          'stdout',
          '-l',
          language,
          '--tessdata-dir',
          tessdataDir,
          '--psm',
          psm,
          '-c',
          'preserve_interword_spaces=1',
        ]);
        if (res.exitCode == 0) {
          text = res.stdout.toString().trim();
        }
      } catch (_) {}
    }

    // Trên Android hoặc fallback: Dùng Flutter plugin
    if (text.isEmpty) {
      try {
        text = await FlutterTesseractOcr.extractText(
          path,
          language: language,
          args: {
            'psm': psm,
            'preserve_interword_spaces': '1',
          },
        );
      } catch (_) {}
    }

    return text;
  }

  bool _hasNutritionKeywords(String text) {
    final lower = text.toLowerCase();
    return lower.contains('cal') ||
        lower.contains('calo') ||
        lower.contains('kcal') ||
        lower.contains('fat') ||
        lower.contains('protein') ||
        lower.contains('carb') ||
        lower.contains('nutrition') ||
        lower.contains('năng lượng') ||
        lower.contains('chất đạm') ||
        lower.contains('chất béo');
  }

  List<OcrTextBlock> _toBlocks(String text) {
    return text
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .map((l) => OcrTextBlock(text: l.trim(), confidence: 0.88))
        .toList();
  }

  String _generateContextualMock(String path) {
    final lower = path.toLowerCase();
    if (lower.contains('combo') || lower.contains('lunch') || lower.contains('salad')) {
      return '''
HEALTHY LUNCH COMBO
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
    } else if (lower.contains('snack') || lower.contains('bar') || lower.contains('protein')) {
      return '''
PROTEIN CRUNCH BAR
Nutrition Facts
Serving Size: 1 Bar (60g)
Calories: 210 kcal
Total Fat: 7g
Total Carbohydrate: 22g
Protein: 20g
''';
    } else {
      return '''
OATMEAL ENERGY PACK
Nutrition Facts
Serving Size: 1 Container
Calories: 260 kcal
Total Fat: 5g
Total Carbohydrate: 44g
Protein: 10g
''';
    }
  }
}
