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

  bool get isEmpty => rawText.trim().isEmpty;
}

abstract class OcrEngine {
  Future<OcrResult> processImage(String imagePath);
}

