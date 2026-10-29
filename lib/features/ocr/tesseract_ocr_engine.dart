import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'ocr_service.dart';

/// OCR Engine dùng Tesseract — dành cho nền tảng Linux (và Android làm backup)
///
/// Pipeline:
///   1. Lần đầu chạy: copy file traineddata (vie + eng) từ assets ra thư mục tạm
///   2. Gọi flutter_tesseract_ocr để nhận diện chữ từ ảnh
///   3. Trả về OcrResult chứa toàn bộ text và các block riêng lẻ
///
/// QUAN TRỌNG: Cần đặt file thực tế vào assets/tessdata/ trước khi build:
///   - assets/tessdata/vie.traineddata  (Tiếng Việt, ~20MB)
///   - assets/tessdata/eng.traineddata  (Tiếng Anh, ~12MB)
///   Xem assets/tessdata/TESSDATA_REQUIRED.md để biết link tải.
class TesseractOcrEngine implements OcrEngine {
  // Tên hiển thị của engine
  static const String _engineName = 'Tesseract OCR (vie+eng)';

  // Ngôn ngữ OCR: kết hợp Tiếng Việt + Tiếng Anh
  static const String _languages = 'vie+eng';

  // Đường dẫn tới thư mục tessdata sau khi copy ra cache (dùng trong log/debug)
  // ignore: unused_field
  String? _tessdataDir;

  // Cờ đánh dấu đã khởi tạo xong chưa
  bool _isInitialized = false;

  // ------------------------------------------------------------------
  // Khởi tạo: copy traineddata từ assets bundle ra thư mục tạm trên thiết bị
  // Chỉ chạy 1 lần (lazy init), lần sau dùng lại đường dẫn đã lưu.
  // ------------------------------------------------------------------
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    // Lấy thư mục documents của app (persistent storage)
    final appDir = await getApplicationDocumentsDirectory();
    final tessDir = Directory('${appDir.path}/tessdata');

    // Tạo thư mục tessdata nếu chưa có
    if (!await tessDir.exists()) {
      await tessDir.create(recursive: true);
    }

    // Copy từng file traineddata từ assets bundle ra ổ đĩa thiết bị
    // (Flutter assets bundle không thể đọc trực tiếp bằng Tesseract C++ native)
    for (final lang in ['vie', 'eng']) {
      final destFile = File('${tessDir.path}/$lang.traineddata');

      // Bỏ qua nếu file đã tồn tại (cache từ lần chạy trước)
      if (await destFile.exists()) continue;

      try {
        // Đọc file từ Flutter assets bundle
        final bytes = await rootBundle.load('assets/tessdata/$lang.traineddata');
        // Ghi ra ổ đĩa để Tesseract native có thể đọc
        await destFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      } catch (e) {
        // Nếu không tìm thấy file thật (chỉ có placeholder),
        // log cảnh báo và tiếp tục — sẽ OCR với model còn lại
        // ignore: avoid_print
        print('[TesseractOCR] Không tìm thấy $lang.traineddata trong assets: $e');
      }
    }

    _tessdataDir = tessDir.path;
    _isInitialized = true;
  }

  // ------------------------------------------------------------------
  // Hàm chính: nhận đường dẫn ảnh, trả về OcrResult
  // ------------------------------------------------------------------
  @override
  Future<OcrResult> processImage(String imagePath) async {
    final stopwatch = Stopwatch()..start();

    // Kiểm tra file ảnh tồn tại
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

    // Đảm bảo tessdata đã được copy ra thiết bị
    await _ensureInitialized();

    try {
      // Gọi Tesseract OCR — kết hợp cả vie+eng để nhận diện song ngữ
      // Tùy chọn:
      //   tessdata_dir: thư mục chứa file traineddata
      //   language: ngôn ngữ cần nhận diện
      final rawText = await FlutterTesseractOcr.extractText(
        imagePath,
        language: _languages,
        args: {
          // Chế độ nhận diện: 3 = auto, không cần page segmentation hint
          'psm': '3',
          // Ưu tiên nhận diện khối label thực phẩm / nutrition facts
          'preserve_interword_spaces': '1',
        },
      );

      stopwatch.stop();

      // Tách thành các block theo dòng để trả về cùng structure với ML Kit
      final lines = rawText
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .map((l) => OcrTextBlock(text: l.trim(), confidence: 0.85))
          .toList();

      return OcrResult(
        rawText: rawText.trim(),
        blocks: lines,
        latencyMs: stopwatch.elapsedMilliseconds,
        engine: _engineName,
      );
    } catch (e) {
      stopwatch.stop();
      // Nếu Tesseract lỗi, trả về empty result
      // ignore: avoid_print
      print('[TesseractOCR] Lỗi OCR: $e');
      return OcrResult(
        rawText: '',
        blocks: [],
        latencyMs: stopwatch.elapsedMilliseconds,
        engine: _engineName,
      );
    }
  }
}
