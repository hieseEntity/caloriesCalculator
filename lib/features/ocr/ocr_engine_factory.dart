import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ocr_service.dart';
import 'google_mlkit_ocr_engine.dart';
import 'tesseract_ocr_engine.dart';

/// Factory chọn OCR Engine phù hợp với nền tảng đang chạy
///
/// CHIẾN LƯỢC PHÂN PHỐI (Platform Dispatch Strategy):
/// ┌─────────────────┬────────────────────────────────────────────────┐
/// │ Nền tảng        │ OCR Engine                                     │
/// ├─────────────────┼────────────────────────────────────────────────┤
/// │ Android         │ Google ML Kit — nhanh, on-device, không cần   │
/// │                 │ file traineddata riêng. Hỗ trợ đa ngôn ngữ.  │
/// ├─────────────────┼────────────────────────────────────────────────┤
/// │ Linux           │ Tesseract OCR — dùng file vie+eng.traineddata │
/// │                 │ Copy từ assets ra thư mục cache khi khởi động │
/// ├─────────────────┼────────────────────────────────────────────────┤
/// │ iOS / macOS     │ Google ML Kit (fallback)                       │
/// ├─────────────────┼────────────────────────────────────────────────┤
/// │ Web / Windows   │ Google ML Kit (fallback giới hạn)             │
/// └─────────────────┴────────────────────────────────────────────────┘
///
/// Cách dùng:
/// ```dart
/// final OcrEngine ocrEngine = OcrEngineFactory.create();
/// final OcrResult result = await ocrEngine.processImage(imagePath);
/// ```
class OcrEngineFactory {
  // Ngăn tạo instance của factory class
  OcrEngineFactory._();

  /// Tạo và trả về OCR engine phù hợp với nền tảng hiện tại
  ///
  /// - Nếu là Android: trả về [GoogleMlKitOcrEngine] (nhanh, chính xác cao)
  /// - Nếu là Linux: trả về [TesseractOcrEngine] (cần tessdata files)
  /// - Mặc định: trả về [GoogleMlKitOcrEngine] cho các nền tảng khác
  static OcrEngine create() {
    // Web không hỗ trợ Platform.isAndroid, cần guard kIsWeb trước
    if (kIsWeb) {
      // Web: dùng ML Kit làm fallback (giới hạn chức năng)
      return GoogleMlKitOcrEngine();
    }

    if (Platform.isAndroid) {
      // Android: Google ML Kit — tích hợp với Google Play Services
      // Không cần file traineddata, xử lý on-device nhanh và chính xác
      return GoogleMlKitOcrEngine();
    }

    if (Platform.isLinux) {
      // Linux: Tesseract OCR — yêu cầu file tessdata trong assets/tessdata/
      // Xem assets/tessdata/TESSDATA_REQUIRED.md để biết cách tải file
      return TesseractOcrEngine();
    }

    if (Platform.isIOS || Platform.isMacOS) {
      // iOS / macOS: Google ML Kit (tương thích tốt trên Apple platforms)
      return GoogleMlKitOcrEngine();
    }

    // Windows hoặc nền tảng khác: dùng ML Kit làm fallback mặc định
    return GoogleMlKitOcrEngine();
  }

  /// Trả về tên engine sẽ được dùng trên nền tảng hiện tại (để debug / UI)
  static String get platformEngineName {
    if (kIsWeb) return 'Google ML Kit (Web)';
    if (Platform.isAndroid) return 'Google ML Kit (Android)';
    if (Platform.isLinux) return 'Tesseract OCR (Linux)';
    if (Platform.isIOS) return 'Google ML Kit (iOS)';
    if (Platform.isMacOS) return 'Google ML Kit (macOS)';
    return 'Google ML Kit';
  }
}

