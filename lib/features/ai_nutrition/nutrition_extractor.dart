/// ============================================================
/// Data Model: Kết Quả Trích Xuất Dinh Dưỡng (Tập Trung Vào CALO)
/// ============================================================
///
/// Chứa thông tin về:
///   - [calories]: TỔNG CALO CỦA CẢ SẢN PHẨM (Total Product Calories)
///   - [caloriesPerServing]: Calo trên mỗi khẩu phần hoặc trên 100g/100ml
///   - [servingSize]: Chuỗi khẩu phần (ví dụ "100g", "1 lon 330ml", "30g")
///   - [servingQuantity]: Giá trị số của khẩu phần (ví dụ 100)
///   - [totalProductQuantity]: Tổng khối lượng/thể tích sản phẩm nhận diện được
///   - [unit]: Đơn vị (g, ml, khẩu phần, lon, chai, hộp...)
///   - [hasTotalQuantity]: `true` nếu OCR/AI tự nhận diện được tổng khối lượng/thể tích
///                         `false` nếu không có trong ảnh -> cần người dùng nhập
///   - [calculationNotes]: Giải thích công thức tính tổng calo
class NutritionExtractionResult {
  final String foodName;
  final String servingSize;
  final int calories; // TỔNG CALO CỦA CẢ SẢN PHẨM
  final int caloriesPerServing;
  final double? servingQuantity;
  final double? totalProductQuantity;
  final String unit;
  final bool hasTotalQuantity;

  // Giữ lại các trường macro (mặc định 0.0) để đảm bảo tính tương thích với FoodEntry & DB
  final double protein;
  final double carbs;
  final double fat;

  final double confidence;
  final String modelUsed;
  final String rawJson;
  final String rawOcrInput;
  final String? calculationNotes;

  const NutritionExtractionResult({
    required this.foodName,
    required this.servingSize,
    required this.calories,
    this.caloriesPerServing = 0,
    this.servingQuantity,
    this.totalProductQuantity,
    this.unit = 'g',
    this.hasTotalQuantity = false,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    required this.confidence,
    required this.modelUsed,
    required this.rawJson,
    required this.rawOcrInput,
    this.calculationNotes,
  });

  /// Tạo bản sao mới với tổng khối lượng/thể tích mới do người dùng nhập vào
  NutritionExtractionResult copyWithTotalQuantity(double newTotalQuantity, {String? newUnit}) {
    final effectiveUnit = newUnit ?? unit;
    int calculatedTotalCalories = calories;
    String newNotes = calculationNotes ?? '';

    final effectiveServing = (servingQuantity != null && servingQuantity! > 0) ? servingQuantity! : 100.0;
    final baseCalories = caloriesPerServing > 0 ? caloriesPerServing : calories;

    if (newTotalQuantity > 0) {
      final ratio = newTotalQuantity / effectiveServing;
      calculatedTotalCalories = (baseCalories * ratio).round();
      newNotes = 'Tính lại theo khối lượng nhập: $baseCalories kcal/($effectiveServing$effectiveUnit) × $newTotalQuantity$effectiveUnit = $calculatedTotalCalories kcal tổng';
    }

    return NutritionExtractionResult(
      foodName: foodName,
      servingSize: servingSize,
      calories: calculatedTotalCalories,
      caloriesPerServing: baseCalories,
      servingQuantity: servingQuantity,
      totalProductQuantity: newTotalQuantity,
      unit: effectiveUnit,
      hasTotalQuantity: true,
      protein: protein,
      carbs: carbs,
      fat: fat,
      confidence: confidence,
      modelUsed: modelUsed,
      rawJson: rawJson,
      rawOcrInput: rawOcrInput,
      calculationNotes: newNotes,
    );
  }

  /// Tạo bản sao với các trường được chỉ định thay đổi
  NutritionExtractionResult copyWith({
    String? foodName,
    String? servingSize,
    int? calories,
    int? caloriesPerServing,
    double? servingQuantity,
    double? totalProductQuantity,
    String? unit,
    bool? hasTotalQuantity,
    double? protein,
    double? carbs,
    double? fat,
    double? confidence,
    String? modelUsed,
    String? rawJson,
    String? rawOcrInput,
    String? calculationNotes,
  }) {
    return NutritionExtractionResult(
      foodName: foodName ?? this.foodName,
      servingSize: servingSize ?? this.servingSize,
      calories: calories ?? this.calories,
      caloriesPerServing: caloriesPerServing ?? this.caloriesPerServing,
      servingQuantity: servingQuantity ?? this.servingQuantity,
      totalProductQuantity: totalProductQuantity ?? this.totalProductQuantity,
      unit: unit ?? this.unit,
      hasTotalQuantity: hasTotalQuantity ?? this.hasTotalQuantity,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      confidence: confidence ?? this.confidence,
      modelUsed: modelUsed ?? this.modelUsed,
      rawJson: rawJson ?? this.rawJson,
      rawOcrInput: rawOcrInput ?? this.rawOcrInput,
      calculationNotes: calculationNotes ?? this.calculationNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_name': foodName,
      'serving_size': servingSize,
      'calories': calories,
      'calories_per_serving': caloriesPerServing,
      'total_product_quantity': totalProductQuantity,
      'unit': unit,
      'has_total_quantity': hasTotalQuantity,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'calculation_notes': calculationNotes,
    };
  }

  factory NutritionExtractionResult.empty(String ocrInput) {
    return NutritionExtractionResult(
      foodName: 'Food Item',
      servingSize: '1 serving',
      calories: 0,
      caloriesPerServing: 0,
      totalProductQuantity: null,
      unit: 'g',
      hasTotalQuantity: false,
      protein: 0.0,
      carbs: 0.0,
      fat: 0.0,
      confidence: 0.0,
      modelUsed: 'None',
      rawJson: '{}',
      rawOcrInput: ocrInput,
      calculationNotes: 'Không nhận diện được calo từ nhãn thực phẩm',
    );
  }
}

abstract class AiNutritionExtractor {
  Future<NutritionExtractionResult> extractNutrition(String rawOcrText);
}
