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
/// │ Android         │ Google ML Kit (ưu tiên) + Tesseract fallback   │
/// ├─────────────────┼────────────────────────────────────────────────┤
/// │ Linux           │ Tesseract OCR (hỗ trợ CLI native + traineddata)│
/// ├─────────────────┼────────────────────────────────────────────────┤
/// │ iOS / macOS     │ Google ML Kit                                  │
/// ├─────────────────┼────────────────────────────────────────────────┤
/// │ Web / Windows   │ Google ML Kit                                  │
/// └─────────────────┴────────────────────────────────────────────────┘
class OcrEngineFactory {
  OcrEngineFactory._();

  /// Tạo OCR engine thích ứng theo nền tảng
  static OcrEngine create() {
    if (kIsWeb) {
      return GoogleMlKitOcrEngine();
    }

    if (Platform.isAndroid) {
      // Trên Android: Dùng Google ML Kit Text Recognition on-device (nhanh, chuẩn, offline)
      return GoogleMlKitOcrEngine();
    }

    if (Platform.isLinux) {
      // Trên Linux: Dùng Tesseract OCR với vie+eng traineddata
      return TesseractOcrEngine();
    }

    if (Platform.isIOS || Platform.isMacOS) {
      return GoogleMlKitOcrEngine();
    }

    return GoogleMlKitOcrEngine();
  }

  static String get platformEngineName {
    if (kIsWeb) return 'Google ML Kit (Web)';
    if (Platform.isAndroid) return 'Google ML Kit (Android)';
    if (Platform.isLinux) return 'Tesseract OCR (Linux)';
    if (Platform.isIOS) return 'Google ML Kit (iOS)';
    if (Platform.isMacOS) return 'Google ML Kit (macOS)';
    return 'Google ML Kit';
  }
}
