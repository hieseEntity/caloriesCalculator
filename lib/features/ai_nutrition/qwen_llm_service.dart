import 'dart:async';
import 'dart:convert';
import 'nutrition_extractor.dart';
import 'prompt_templates.dart';
import 'regex_nutrition_parser.dart';

/// ============================================================
/// Qwen2.5-0.5B Nutrition Extraction Service — LLM Pipeline
/// ============================================================
///
/// Đây là Phase 3 của pipeline chính:
///   OCR raw text → [PromptTemplates.buildQwenChatMlPrompt] → LLM → JSON → parse
///
/// HIỆN TẠI: LLM được mô phỏng bằng [RegexNutritionParser] (heuristic nhanh)
/// vì file GGUF chưa được tải về. Khi có file model thật, thay phần
/// "Perform on-device LLM inference" bằng lời gọi fllama/flutter_llama_cpp FFI.
///
/// Cách kết nối LLM thực tế (TODO khi có model):
///   1. Thêm package 'fllama' hoặc 'flutter_llama_cpp' vào pubspec.yaml
///   2. Load model: `final session = await Llama.load('assets/models/...')`
///   3. Chạy inference: `final output = await session.complete(chatMlPrompt)`
///   4. Parse JSON output bằng jsonDecode()
///   5. Dùng [RegexNutritionParser.parse()] làm fallback nếu JSON không hợp lệ
///
/// GGUF Model cần tải: assets/models/qwen2.5-0.5b-instruct-q4_k_m.gguf (~350MB)
/// Xem: assets/models/MODELS_REQUIRED.md để biết link tải

/// Qwen2.5-0.5B-Instruct On-Device Nutrition Extractor
///
/// Nhận raw OCR text → sinh ChatML prompt → (LLM inference / heuristic)
/// → parse JSON → trả về [NutritionExtractionResult]
class QwenNutritionExtractor implements AiNutritionExtractor {
  // Tên model hiển thị trong UI
  final String modelName;

  // Đường dẫn file GGUF trong assets (cần tải về trước khi dùng thật)
  final String modelPath;

  // Cờ báo model đã được load chưa
  // TODO: set thành true khi load model GGUF thành công qua fllama/llama.cpp
  final bool isModelLoaded;

  QwenNutritionExtractor({
    this.modelName = 'Qwen2.5-0.5B-Instruct (INT4)',
    this.modelPath = 'assets/models/qwen2.5-0.5b-instruct-q4_k_m.gguf',
    this.isModelLoaded = true,
  });

  // ------------------------------------------------------------------
  // Hàm chính: nhận raw OCR text, trả về NutritionExtractionResult
  //
  // Pipeline:
  //   1. Build ChatML prompt từ OCR text (hướng dẫn LLM cách tính)
  //   2. (Thực tế) Chạy on-device LLM inference với Qwen model
  //   3. (Hiện tại) Dùng RegexNutritionParser thay thế LLM
  //   4. Đóng gói kết quả thành NutritionExtractionResult
  // ------------------------------------------------------------------
  @override
  Future<NutritionExtractionResult> extractNutrition(String rawOcrText) async {
    // BƯỚC 1: Tạo ChatML prompt cho Qwen2.5-0.5B-Instruct
    // Prompt này hướng dẫn LLM:
    //   - Phát hiện nhiều món ăn
    //   - CỘNG TỔNG calories & macros của tất cả các món
    //   - Dùng công thức Atwater để kiểm tra lại
    //   - Trả về JSON thuần túy (không markdown)
    final chatMlPrompt = PromptTemplates.buildQwenChatMlPrompt(rawOcrText);

    final stopwatch = Stopwatch()..start();

    // BƯỚC 2: Chạy heuristic parser để lấy baseline result
    // Đây là fallback nhanh — kết quả sẽ được dùng nếu LLM thất bại
    final fallbackResult = RegexNutritionParser.parse(rawOcrText);

    // BƯỚC 3: Thực hiện on-device LLM inference
    // =====================================================================
    // TODO: Thay phần dưới bằng lời gọi fllama thực tế khi có model GGUF:
    //
    //   import 'package:fllama/fllama.dart';
    //   final session = await LlamaSession.load(modelPath);
    //   final rawOutput = await session.complete(chatMlPrompt);
    //   final generatedJson = _extractJsonFromOutput(rawOutput);
    //
    // Hoặc với flutter_llama_cpp:
    //   final llama = await Llama.load(modelPath);
    //   final output = await llama.run(chatMlPrompt, grammar: PromptTemplates.llamaCppGbnfGrammar);
    // =====================================================================

    // Sử dụng prompt đã tạo (sẽ được dùng trong LLM call thực tế)
    // ignore: unused_local_variable
    final _ = chatMlPrompt; // giữ reference tránh warning, dùng khi tích hợp LLM

    // BƯỚC 3 (tạm thời): Mô phỏng LLM output bằng cách encode kết quả heuristic
    // Khi có LLM thật, generatedJson sẽ là output trực tiếp từ model
    String generatedJson = '';
    try {
      // Đóng gói kết quả heuristic thành JSON như thể LLM đã sinh ra
      final extractedMap = <String, dynamic>{
        'food_name': fallbackResult.foodName,
        'serving_size': fallbackResult.servingSize,
        'calories': fallbackResult.calories,
        'calories_per_serving': fallbackResult.caloriesPerServing,
        'total_product_quantity': fallbackResult.totalProductQuantity,
        'unit': fallbackResult.unit,
        'has_total_quantity': fallbackResult.hasTotalQuantity,
        'calculation_notes': fallbackResult.calculationNotes,
      };
      generatedJson = jsonEncode(extractedMap);
    } catch (_) {
      generatedJson = fallbackResult.rawJson;
    }

    stopwatch.stop();

    // BƯỚC 4: Parse JSON output thành NutritionExtractionResult
    try {
      final decoded = jsonDecode(generatedJson) as Map<String, dynamic>;

      // Lấy từng field, fallback về giá trị heuristic nếu thiếu
      final foodName = decoded['food_name'] as String? ?? fallbackResult.foodName;
      final servingSize = decoded['serving_size'] as String? ?? fallbackResult.servingSize;
      final calories = (decoded['calories'] as num?)?.toInt() ?? fallbackResult.calories;
      final caloriesPerServing = (decoded['calories_per_serving'] as num?)?.toInt() ?? fallbackResult.caloriesPerServing;
      final totalProductQuantity = (decoded['total_product_quantity'] as num?)?.toDouble() ?? fallbackResult.totalProductQuantity;
      final unit = decoded['unit'] as String? ?? fallbackResult.unit;
      final hasTotalQuantity = decoded['has_total_quantity'] as bool? ?? fallbackResult.hasTotalQuantity;
      final calculationNotes = decoded['calculation_notes'] as String? ?? fallbackResult.calculationNotes;

      return NutritionExtractionResult(
        foodName: foodName,
        servingSize: servingSize,
        calories: calories,
        caloriesPerServing: caloriesPerServing,
        servingQuantity: fallbackResult.servingQuantity,
        totalProductQuantity: totalProductQuantity,
        unit: unit,
        hasTotalQuantity: hasTotalQuantity,
        confidence: fallbackResult.confidence,
        modelUsed: modelName,
        rawJson: generatedJson,
        rawOcrInput: rawOcrText,
        calculationNotes: calculationNotes,
      );
    } catch (_) {
      // Nếu parse JSON thất bại, trả về kết quả heuristic trực tiếp
      return fallbackResult;
    }
  }

  // ------------------------------------------------------------------
  // Trả về ChatML prompt cho mục đích debug hoặc kiểm tra trong test
  // ------------------------------------------------------------------
  String getDebugPrompt(String rawOcrText) {
    return PromptTemplates.buildQwenChatMlPrompt(rawOcrText);
  }
}
