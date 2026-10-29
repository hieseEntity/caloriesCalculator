import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'ocr_service.dart';

/// ============================================================
/// Tesseract OCR Engine — Nhận diện chữ trên Linux
/// ============================================================
///
/// Đọc cấu hình từ: assets/tessdata/tessdata_config.json
///
/// Pipeline:
///   1. Lần đầu chạy: đọc tessdata_config.json để lấy danh sách ngôn ngữ
///   2. Copy file traineddata (vie + eng) từ assets ra getApplicationDocumentsDirectory()
///   3. Gọi FlutterTesseractOcr.extractText() với tham số từ config
///   4. Trả về OcrResult chứa toàn bộ text và các block theo dòng
///
/// Được dùng bởi OcrEngineFactory khi Platform.isLinux == true.
///
/// QUAN TRỌNG: Cần đặt file thực tế vào assets/tessdata/ trước khi build:
///   - assets/tessdata/vie.traineddata  (Tiếng Việt, ~20MB)
///   - assets/tessdata/eng.traineddata  (Tiếng Anh, ~12MB)
///   Xem assets/tessdata/TESSDATA_REQUIRED.md để biết link tải.
class TesseractOcrEngine implements OcrEngine {
  // Tên hiển thị của engine trong UI và telemetry
  static const String _engineName = 'Tesseract OCR (vie+eng)';

  // Đường dẫn tới file cấu hình JSON trong assets bundle
  static const String _configAssetPath = 'assets/tessdata/tessdata_config.json';

  // Ngôn ngữ mặc định (dùng khi config không đọc được)
  static const String _defaultLanguages = 'vie+eng';

  // Tham số OCR mặc định (dùng khi config không đọc được)
  static const Map<String, String> _defaultOcrArgs = {
    'psm': '3',
    'preserve_interword_spaces': '1',
  };

  // Đường dẫn thư mục tessdata trên ổ đĩa thiết bị (sau khi copy ra)
  // ignore: unused_field
  String? _tessdataDir;

  // Cờ đánh dấu đã khởi tạo và copy traineddata xong chưa
  bool _isInitialized = false;

  // Config đọc từ tessdata_config.json
  Map<String, dynamic>? _config;

  // ------------------------------------------------------------------
  // Đọc tessdata_config.json từ assets bundle
  //
  // Thử lần lượt các đường dẫn có thể (phòng trường hợp pubspec khai báo
  // khác nhau giữa các môi trường build). Nếu tất cả thất bại → trả null,
  // engine sẽ dùng giá trị default hardcode — app KHÔNG crash.
  // ------------------------------------------------------------------
  Future<Map<String, dynamic>?> _loadConfig() async {
    // Các đường dẫn thử theo thứ tự ưu tiên
    final candidatePaths = [
      _configAssetPath,                      // assets/tessdata/tessdata_config.json
      'assets/tessdata_config.json',         // fallback nếu pubspec map flat
    ];
    for (final path in candidatePaths) {
      try {
        final jsonStr = await rootBundle.loadString(path);
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        // ignore: avoid_print
        print('[TesseractOCR] Config loaded từ: $path');
        return decoded;
      } catch (_) {
        // Thử đường dẫn tiếp theo
      }
    }
    // Không tìm thấy ở bất kỳ đường dẫn nào → dùng config mặc định
    // ignore: avoid_print
    print('[TesseractOCR] tessdata_config.json không đọc được → dùng config mặc định (vie+eng, psm=3)');
    return null;
  }

  // ------------------------------------------------------------------
  // Lấy danh sách ngôn ngữ từ config
  // Ưu tiên: config["languages"]["combined"] → fallback "_defaultLanguages"
  // ------------------------------------------------------------------
  String _getLanguages() {
    try {
      final langs = _config?['languages'] as Map<String, dynamic>?;
      return langs?['combined'] as String? ?? _defaultLanguages;
    } catch (_) {
      return _defaultLanguages;
    }
  }

  // ------------------------------------------------------------------
  // Lấy tham số OCR từ config (psm, preserve_interword_spaces...)
  // Chuyển đổi về Map<String, String> mà FlutterTesseractOcr.extractText() cần
  // ------------------------------------------------------------------
  Map<String, String> _getOcrArgs() {
    try {
      final params = _config?['ocr_params'] as Map<String, dynamic>?;
      if (params == null) return _defaultOcrArgs;
      // Lọc chỉ lấy key không bắt đầu bằng '_' (bỏ qua các trường comment)
      return {
        for (final entry in params.entries)
          if (!entry.key.startsWith('_'))
            entry.key: entry.value.toString(),
      };
    } catch (_) {
      return _defaultOcrArgs;
    }
  }

  // ------------------------------------------------------------------
  // Lấy danh sách file traineddata cần copy từ config
  // Trả về list các Map chứa lang, filename, asset_path
  // ------------------------------------------------------------------
  List<Map<String, dynamic>> _getTrainedDataFiles() {
    try {
      final files = _config?['traineddata_files'] as List<dynamic>?;
      if (files == null) {
        // Fallback: hardcode 2 ngôn ngữ mặc định
        return [
          {'lang': 'vie', 'filename': 'vie.traineddata', 'asset_path': 'assets/tessdata/vie.traineddata'},
          {'lang': 'eng', 'filename': 'eng.traineddata', 'asset_path': 'assets/tessdata/eng.traineddata'},
        ];
      }
      return files.cast<Map<String, dynamic>>();
    } catch (_) {
      return [
        {'lang': 'vie', 'filename': 'vie.traineddata', 'asset_path': 'assets/tessdata/vie.traineddata'},
        {'lang': 'eng', 'filename': 'eng.traineddata', 'asset_path': 'assets/tessdata/eng.traineddata'},
      ];
    }
  }

  // ------------------------------------------------------------------
  // Khởi tạo: đọc config → copy traineddata từ assets bundle ra ổ đĩa
  //
  // Chỉ chạy 1 lần (lazy init) — lần sau dùng lại cache.
  // Lý do phải copy: Tesseract C++ native không thể đọc file
  // trực tiếp từ Flutter asset bundle (memory-mapped, không có path thật).
  // ------------------------------------------------------------------
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    // BƯỚC 1: Đọc tessdata_config.json
    _config = await _loadConfig();

    // BƯỚC 2: Lấy thư mục documents của app (persistent, survives reboots)
    final appDir = await getApplicationDocumentsDirectory();
    final destSubdir = (_config?['runtime'] as Map<String, dynamic>?)?['destination_subdir'] as String? ?? 'tessdata';
    final tessDir = Directory('${appDir.path}/$destSubdir');

    // Tạo thư mục tessdata nếu chưa có
    if (!await tessDir.exists()) {
      await tessDir.create(recursive: true);
    }

    // BƯỚC 3: Kiểm tra chiến lược cache từ config
    final cacheStrategy = (_config?['runtime'] as Map<String, dynamic>?)?['cache_strategy'] as String? ?? 'skip_if_exists';
    final skipIfExists = cacheStrategy == 'skip_if_exists';

    // BƯỚC 4: Copy từng file traineddata từ assets bundle ra ổ đĩa
    final trainedDataFiles = _getTrainedDataFiles();
    for (final fileInfo in trainedDataFiles) {
      final filename = fileInfo['filename'] as String;
      final assetPath = fileInfo['asset_path'] as String;
      final destFile = File('${tessDir.path}/$filename');

      // Bỏ qua nếu file đã tồn tại và cache_strategy là skip_if_exists
      if (skipIfExists && await destFile.exists()) {
        // ignore: avoid_print
        print('[TesseractOCR] Cache hit: $filename đã có sẵn, bỏ qua copy');
        continue;
      }

      try {
        // Đọc binary từ Flutter assets bundle
        final bytes = await rootBundle.load(assetPath);
        // Ghi ra ổ đĩa để Tesseract C++ native có thể truy cập theo đường dẫn
        await destFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
        // ignore: avoid_print
        print('[TesseractOCR] Đã copy $filename → ${destFile.path}');
      } catch (e) {
        // Nếu file không tồn tại trong assets (chỉ có placeholder),
        // log cảnh báo và tiếp tục — Tesseract sẽ chạy với ngôn ngữ còn lại
        final fallbackAction = (_config?['fallback'] as Map<String, dynamic>?)?['on_missing_traineddata'] as String?;
        // ignore: avoid_print
        print('[TesseractOCR] [$fallbackAction] Không tìm thấy $assetPath: $e');
        // ignore: avoid_print
        print('[TesseractOCR] → Tải file thật tại: ${fileInfo['download_url'] ?? 'xem TESSDATA_REQUIRED.md'}');
      }
    }

    _tessdataDir = tessDir.path;
    _isInitialized = true;
    // ignore: avoid_print
    print('[TesseractOCR] Khởi tạo hoàn tất — tessdata dir: ${tessDir.path}');
  }

  // ------------------------------------------------------------------
  // Hàm chính: nhận đường dẫn ảnh, trả về OcrResult
  //
  // Flow:
  //   1. Kiểm tra file ảnh tồn tại
  //   2. Đảm bảo tessdata đã được copy (lazy init)
  //   3. Gọi FlutterTesseractOcr với ngôn ngữ và tham số từ config
  //   4. Tách kết quả thành blocks theo dòng
  //   5. Trả về OcrResult
  // ------------------------------------------------------------------
  @override
  Future<OcrResult> processImage(String imagePath) async {
    final stopwatch = Stopwatch()..start();

    // BƯỚC 1: Kiểm tra file ảnh tồn tại
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

    // BƯỚC 2: Đảm bảo tessdata đã sẵn sàng (đọc config + copy files)
    await _ensureInitialized();

    try {
      // BƯỚC 3: Lấy ngôn ngữ và tham số từ config (hoặc dùng default)
      final language = _getLanguages();
      final args = _getOcrArgs();

      // BƯỚC 4: Gọi Tesseract OCR
      // language: "vie+eng" — nhận diện song ngữ Việt + Anh trong cùng một ảnh
      // args: tham số Tesseract (psm, preserve_interword_spaces...)
      final rawText = await FlutterTesseractOcr.extractText(
        imagePath,
        language: language,
        args: args,
      );

      stopwatch.stop();

      // BƯỚC 5: Tách kết quả thành OcrTextBlock[] theo từng dòng
      // Cấu trúc này tương thích với output của GoogleMlKitOcrEngine
      final doSplit = (_config?['post_processing'] as Map<String, dynamic>?)?['split_by_newline'] as bool? ?? true;
      final doTrim = (_config?['post_processing'] as Map<String, dynamic>?)?['trim_whitespace'] as bool? ?? true;

      final processedText = doTrim ? rawText.trim() : rawText;

      final lines = doSplit
          ? processedText
              .split('\n')
              .where((l) => l.trim().isNotEmpty)
              .map((l) => OcrTextBlock(text: l.trim(), confidence: 0.85))
              .toList()
          : [OcrTextBlock(text: processedText, confidence: 0.85)];

      return OcrResult(
        rawText: processedText,
        blocks: lines,
        latencyMs: stopwatch.elapsedMilliseconds,
        engine: _engineName,
      );
    } catch (e) {
      stopwatch.stop();
      // Nếu Tesseract lỗi, trả về empty result (app không crash)
      final fallbackAction = (_config?['fallback'] as Map<String, dynamic>?)?['on_exception'] as String?;
      // ignore: avoid_print
      print('[TesseractOCR] [$fallbackAction] Lỗi OCR: $e');
      return OcrResult(
        rawText: '',
        blocks: [],
        latencyMs: stopwatch.elapsedMilliseconds,
        engine: _engineName,
      );
    }
  }
}
