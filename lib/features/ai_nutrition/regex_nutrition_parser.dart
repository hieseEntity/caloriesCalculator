import 'nutrition_extractor.dart';

/// Heuristic & Arithmetic Total Calorie Parser
/// Bóc tách và tính toán TỔNG LƯỢNG CALO CỦA CẢ SẢN PHẨM:
///   1. Tìm lượng calo trên mỗi khẩu phần hoặc trên 100g / 100ml
///   2. Tìm tổng khối lượng tịnh hoặc thể tích thực của sản phẩm (Net Wt / Volume / Servings)
///   3. Tính: Tổng Calo = Calo khẩu phần × (Tổng khối lượng / Khối lượng khẩu phần)
///   4. Nếu không có tổng khối lượng, đánh dấu hasTotalQuantity = false để người dùng nhập.
class RegexNutritionParser {
  static NutritionExtractionResult parse(String rawOcrText) {
    if (rawOcrText.trim().isEmpty) {
      return NutritionExtractionResult.empty(rawOcrText);
    }

    final lines = rawOcrText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // 1. Nhận diện tên sản phẩm / món ăn
    String foodName = 'Sản phẩm';
    final nonGenericLines = <String>[];
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (!lower.contains('nutrition') &&
          !lower.contains('serving') &&
          !lower.contains('amount') &&
          !lower.contains('facts') &&
          !lower.contains('calories') &&
          !lower.contains('total') &&
          !lower.contains('thông tin') &&
          !lower.contains('dinh dưỡng') &&
          !lower.contains('khẩu phần') &&
          !lower.contains('năng lượng') &&
          !lower.contains('thành phần') &&
          !lower.contains('khối lượng') &&
          !lower.contains('thể tích') &&
          line.length > 3) {
        nonGenericLines.add(_cleanFoodName(line));
      }
    }

    if (nonGenericLines.isNotEmpty) {
      foodName = nonGenericLines.first;
    }

    // 2. Nhận diện Khẩu phần (Serving Size) & Lượng khẩu phần cơ sở (ví dụ 100g, 30g, 1 can...)
    String servingSize = '1 khẩu phần';
    double servingQuantity = 100.0;
    String unit = 'g';

    final servingRegex = RegExp(
      r'(?:serving\s*size|khẩu\s*phần|khau\s*phan)[:\s]+([^\n\r,]+)',
      caseSensitive: false,
    );
    final servingMatch = servingRegex.firstMatch(rawOcrText);
    if (servingMatch != null) {
      servingSize = servingMatch.group(1)?.trim() ?? '1 khẩu phần';

      // Trích xuất số lượng từ chuỗi khẩu phần (ví dụ: "30g" -> 30, "100ml" -> 100, "1 can" -> 1)
      final numMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*(g|kg|ml|l|gam|oz)?', caseSensitive: false)
          .firstMatch(servingSize);
      if (numMatch != null) {
        final val = double.tryParse((numMatch.group(1) ?? '').replaceAll(',', '.')) ?? 100.0;
        final u = numMatch.group(2)?.toLowerCase() ?? '';
        if (u == 'kg') {
          servingQuantity = val * 1000;
          unit = 'g';
        } else if (u == 'l') {
          servingQuantity = val * 1000;
          unit = 'ml';
        } else {
          servingQuantity = val;
          if (u.isNotEmpty) unit = (u == 'gam' ? 'g' : u);
        }
      }
    }

    // 3. Nhận diện Calo cơ sở (Calories per serving / 100g / 100ml)
    final caloriesRegex = RegExp(
      r'(?:calories|energy|cal|calo|năng\s*lượng|nang\s*luong)[^\d\n]*?(\d+)(?:\s*(?:kcal|cal|kj))?',
      caseSensitive: false,
    );
    final calorieMatches = caloriesRegex.allMatches(rawOcrText).toList();

    int baseCalories = 0;
    if (calorieMatches.isNotEmpty) {
      baseCalories = int.tryParse(calorieMatches.first.group(1) ?? '0') ?? 0;
    }

    // Fallback nếu không có từ khóa calorie nhưng có số kèm theo 'kcal'
    if (baseCalories == 0) {
      final kcalMatch = RegExp(r'(\d+)\s*kcal\b', caseSensitive: false).firstMatch(rawOcrText);
      if (kcalMatch != null) {
        baseCalories = int.tryParse(kcalMatch.group(1) ?? '0') ?? 0;
      }
    }

    // 4. Nhận diện Tổng khối lượng tịnh / Thể tích thực của cả sản phẩm
    // (Net Weight, Khối lượng tịnh, Thể tích thực, Net Content, Dung tích)
    double? totalProductQuantity;
    bool hasTotalQuantity = false;

    final netWeightRegex = RegExp(
      r'(?:khối\s*lượng\s*tịnh|kl\s*tịnh|klt|thể\s*tích\s*thực|thể\s*tích|dung\s*tích|trọng\s*lượng|net\s*wt|net\s*weight|net\s*content|net\s*volume)[:\s]*(\d+(?:[.,]\d+)?)\s*(g|kg|ml|l|gam|lit|lít|oz)?',
      caseSensitive: false,
    );
    final netWeightMatch = netWeightRegex.firstMatch(rawOcrText);

    if (netWeightMatch != null) {
      final rawVal = (netWeightMatch.group(1) ?? '').replaceAll(',', '.');
      final val = double.tryParse(rawVal);
      final rawUnit = netWeightMatch.group(2)?.toLowerCase() ?? '';

      if (val != null && val > 0) {
        if (rawUnit == 'kg') {
          totalProductQuantity = val * 1000;
          unit = 'g';
        } else if (rawUnit == 'l' || rawUnit == 'lit' || rawUnit == 'lít') {
          totalProductQuantity = val * 1000;
          unit = 'ml';
        } else {
          totalProductQuantity = val;
          if (rawUnit.isNotEmpty) {
            unit = (rawUnit == 'gam' ? 'g' : rawUnit);
          }
        }
        hasTotalQuantity = true;
      }
    }

    // Nhận diện Số khẩu phần trong sản phẩm (Servings Per Container)
    int servingsPerContainer = 1;
    final containerServingsRegex = RegExp(
      r'(?:servings?\s+per\s+container|about\s+(\d+)\s+servings?|số\s+khẩu\s+phần[:\s]*(\d+))',
      caseSensitive: false,
    );
    final containerMatch = containerServingsRegex.firstMatch(rawOcrText);
    if (containerMatch != null) {
      final s = containerMatch.group(1) ?? containerMatch.group(2);
      if (s != null) {
        servingsPerContainer = int.tryParse(s) ?? 1;
      }
    }

    // 5. Tính toán TỔNG LƯỢNG CALO CỦA CẢ SẢN PHẨM
    int totalCalories = baseCalories;
    String calculationNotes = '';

    if (hasTotalQuantity && totalProductQuantity != null && totalProductQuantity > 0) {
      if (servingQuantity > 0 && totalProductQuantity != servingQuantity) {
        final ratio = totalProductQuantity / servingQuantity;
        totalCalories = (baseCalories * ratio).round();
        calculationNotes = 'Tính theo tổng khối lượng: $baseCalories kcal/($servingQuantity$unit) × $totalProductQuantity$unit = $totalCalories kcal tổng';
      } else {
        totalCalories = baseCalories;
        calculationNotes = 'Khẩu phần đúng bằng toàn bộ sản phẩm: $totalCalories kcal ($totalProductQuantity$unit)';
      }
    } else if (servingsPerContainer > 1) {
      totalCalories = baseCalories * servingsPerContainer;
      hasTotalQuantity = true;
      totalProductQuantity = servingsPerContainer.toDouble();
      unit = 'khẩu phần';
      calculationNotes = 'Tính theo số khẩu phần: $baseCalories kcal × $servingsPerContainer khẩu phần = $totalCalories kcal tổng';
    } else {
      // Trường hợp nhãn như "1 Can", "1 Chai", "1 Gói"
      final isSingleContainer = servingSize.toLowerCase().contains('can') ||
          servingSize.toLowerCase().contains('lon') ||
          servingSize.toLowerCase().contains('chai') ||
          servingSize.toLowerCase().contains('gói') ||
          servingSize.toLowerCase().contains('hộp') ||
          servingSize.toLowerCase().contains('bar');

      if (isSingleContainer) {
        hasTotalQuantity = true;
        totalCalories = baseCalories;
        calculationNotes = 'Calo trọn gói sản phẩm ($servingSize): $totalCalories kcal';
      } else {
        hasTotalQuantity = false;
        totalCalories = baseCalories;
        calculationNotes = 'Chưa nhận diện được tổng khối lượng/thể tích của sản phẩm. Vui lòng nhập khối lượng để AI tính tổng calo.';
      }
    }

    final rawJson = '''
{
  "food_name": "$foodName",
  "serving_size": "$servingSize",
  "calories_per_serving": $baseCalories,
  "total_product_quantity": $totalProductQuantity,
  "unit": "$unit",
  "has_total_quantity": $hasTotalQuantity,
  "total_calories": $totalCalories,
  "calculation_notes": "$calculationNotes"
}
''';

    return NutritionExtractionResult(
      foodName: foodName,
      servingSize: servingSize,
      calories: totalCalories,
      caloriesPerServing: baseCalories,
      servingQuantity: servingQuantity,
      totalProductQuantity: totalProductQuantity,
      unit: unit,
      hasTotalQuantity: hasTotalQuantity,
      confidence: hasTotalQuantity ? 0.95 : 0.70,
      modelUsed: 'AI Total Calorie Extractor',
      rawJson: rawJson.trim(),
      rawOcrInput: rawOcrText,
      calculationNotes: calculationNotes,
    );
  }

  static String _cleanFoodName(String text) {
    var cleaned = text.replaceAll(RegExp(r'[^\p{L}\p{N}\s-]', unicode: true), '').trim();
    if (cleaned.length > 40) {
      cleaned = cleaned.substring(0, 40);
    }
    return cleaned.isNotEmpty ? cleaned : 'Sản phẩm';
  }
}
