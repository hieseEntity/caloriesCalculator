/// ============================================================
/// OCR Service — Định nghĩa Interface và Data Models cho OCR
/// ============================================================
library;
///
/// File này định nghĩa:
///   - [OcrTextBlock]: Một đoạn văn bản được nhận diện từ ảnh
///   - [OcrResult]: Kết quả tổng hợp sau khi OCR xong
///   - [OcrEngine]: Abstract interface — mọi engine OCR đều implement
///
/// Kiến trúc dạng Strategy Pattern:
///   OcrEngine (interface)
///     ├── GoogleMlKitOcrEngine (Android/iOS)
///     └── TesseractOcrEngine  (Linux)
///   => Được chọn tự động bởi OcrEngineFactory

/// Đại diện cho một đoạn text được nhận diện từ ảnh
///
/// [text]        — Nội dung văn bản
/// [confidence]  — Độ tin cậy (0.0 – 1.0)
/// [boundingBox] — Vị trí trên ảnh [x, y, width, height]
class OcrTextBlock {
  final String text;
  final double confidence;
  final List<double>? boundingBox; // [x, y, width, height]

  const OcrTextBlock({
    required this.text,
    this.confidence = 1.0,
    this.boundingBox,
  });
}

/// Kết quả đầu ra sau khi một OCR engine xử lý xong một ảnh
///
/// [rawText]    — Toàn bộ văn bản (dùng để truyền vào LLM prompt)
/// [blocks]     — Danh sách các đoạn text riêng biệt
/// [latencyMs]  — Thời gian xử lý OCR (milliseconds)
/// [engine]     — Tên engine đã dùng (để hiển thị trong UI)
class OcrResult {
  final String rawText;
  final List<OcrTextBlock> blocks;
  final int latencyMs;
  final String engine;

  const OcrResult({
    required this.rawText,
    required this.blocks,
    required this.latencyMs,
    required this.engine,
  });

  /// Trả về true nếu OCR không nhận diện được chữ nào
  bool get isEmpty => rawText.trim().isEmpty;
}

/// Interface (abstract class) cho mọi OCR engine
///
/// Mỗi engine cụ thể (ML Kit, Tesseract...) phải implement hàm này:
///   [processImage] — nhận đường dẫn ảnh, trả về [OcrResult]
abstract class OcrEngine {
  Future<OcrResult> processImage(String imagePath);
}
