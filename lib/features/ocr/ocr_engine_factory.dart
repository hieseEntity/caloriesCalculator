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
      // Trên Android: Dùng engine thông minh (ML Kit làm chính, Tesseract làm fallback)
      return _AndroidSmartOcrEngine();
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
    if (Platform.isAndroid) return 'Google ML Kit / Tesseract (Android)';
    if (Platform.isLinux) return 'Tesseract OCR (Linux)';
    if (Platform.isIOS) return 'Google ML Kit (iOS)';
    if (Platform.isMacOS) return 'Google ML Kit (macOS)';
    return 'Google ML Kit';
  }
}

/// Engine thông minh cho Android:
/// 1. Ưu tiên chạy Google ML Kit on-device (nhanh, chuẩn).
/// 2. Nếu ML Kit trả về rỗng hoặc lỗi (ví dụ chưa kịp tải model Play Services),
///    tự động fallback sang Tesseract OCR on-device.
class _AndroidSmartOcrEngine implements OcrEngine {
  final GoogleMlKitOcrEngine _mlKit = GoogleMlKitOcrEngine();
  final TesseractOcrEngine _tesseract = TesseractOcrEngine();

  @override
  Future<OcrResult> processImage(String imagePath) async {
    try {
      final mlKitResult = await _mlKit.processImage(imagePath);
      if (!mlKitResult.isEmpty) {
        return mlKitResult;
      }
      // ignore: avoid_print
      print('[AndroidSmartOCR] ML Kit không nhận diện được chữ → Fallback sang Tesseract');
    } catch (e) {
      // ignore: avoid_print
      print('[AndroidSmartOCR] ML Kit lỗi ($e) → Fallback sang Tesseract');
    }

    return await _tesseract.processImage(imagePath);
  }
}
