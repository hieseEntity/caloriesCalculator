import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ocr_service.dart';
import 'paddle_ocr_desktop_engine.dart';
import 'pp_ocr_mobile_engine.dart';

/// Factory chọn OCR Engine phù hợp với nền tảng đang chạy
///
/// CHIẾN LƯỢC PHÂN PHỐI (Platform Dispatch Strategy):
/// ┌─────────────────┬────────────────────────────────────────────────┐
/// │ Nền tảng        │ OCR Engine                                     │
/// ├─────────────────┼────────────────────────────────────────────────┤
/// │ Android         │ PP-OCRv5 Mobile (NCNN, fast_paddle_ocr)        │
/// ├─────────────────┼────────────────────────────────────────────────┤
/// │ Linux / Windows │ PP-OCRv6 Desktop (ONNX Runtime, pp_ocr)        │
/// ├─────────────────┼────────────────────────────────────────────────┤
/// │ iOS / macOS     │ PP-OCRv6 Desktop (ONNX Runtime, pp_ocr)        │
/// ├─────────────────┼────────────────────────────────────────────────┤
/// │ Web             │ PP-OCRv6 Desktop (fallback — mock mode)         │
/// └─────────────────┴────────────────────────────────────────────────┘
///
/// Tất cả engine đều sử dụng PaddleOCR — hỗ trợ đọc chữ trên mặt cong
/// (nhãn dinh dưỡng trên lon, chai...) nhờ kiến trúc PP-OCRv5/v6.
class OcrEngineFactory {
  OcrEngineFactory._();

  /// Tạo OCR engine thích ứng theo nền tảng
  static OcrEngine create() {
    if (kIsWeb) {
      // Web: dùng desktop engine ở chế độ fallback/mock
      return PaddleOcrDesktopEngine();
    }

    if (Platform.isAndroid) {
      // Android: Dùng PP-OCRv5 Mobile qua NCNN (fast_paddle_ocr)
      // Hỗ trợ curved text, real-time camera, hiệu năng cao
      return PpOcrMobileEngine();
    }

    if (Platform.isLinux || Platform.isWindows) {
      // Linux/Windows: Dùng PP-OCRv6 Desktop qua ONNX Runtime (pp_ocr)
      // Hỗ trợ curved text, offline, dart:ffi trực tiếp
      return PaddleOcrDesktopEngine();
    }

    if (Platform.isIOS || Platform.isMacOS) {
      // iOS/macOS: Dùng desktop engine (ONNX Runtime)
      return PaddleOcrDesktopEngine();
    }

    // Fallback: desktop engine
    return PaddleOcrDesktopEngine();
  }

  static String get platformEngineName {
    if (kIsWeb) return 'PP-OCRv6 Desktop (Web Fallback)';
    if (Platform.isAndroid) return 'PP-OCRv5 Mobile (Android)';
    if (Platform.isLinux) return 'PP-OCRv6 Desktop (Linux)';
    if (Platform.isWindows) return 'PP-OCRv6 Desktop (Windows)';
    if (Platform.isIOS) return 'PP-OCRv6 Desktop (iOS)';
    if (Platform.isMacOS) return 'PP-OCRv6 Desktop (macOS)';
    return 'PaddleOCR';
  }
}
