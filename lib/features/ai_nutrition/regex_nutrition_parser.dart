import 'nutrition_extractor.dart';

/// Heuristic & Arithmetic Total Calorie Parser
/// Bóc tách và tính toán TỔNG LƯỢNG CALO CỦA CẢ SẢN PHẨM:
///   1. Tìm lượng calo cơ sở trên mỗi khẩu phần hoặc trên 100g / 100ml
///   2. Tìm tổng thể tích/khối lượng của cả sản phẩm (ví dụ 500ml, 250g, Net Wt)
///   3. Nếu CÓ tổng thể tích/khối lượng trong ảnh:
///      -> Tự động tính: Tổng Calo = Calo cơ sở × (Tổng thể tích / Thể tích chuẩn)
///      -> Đánh dấu hasTotalQuantity = true
///   4. Nếu KHÔNG CÓ tổng trong ảnh:
///      -> Đánh dấu hasTotalQuantity = false để giao diện yêu cầu người dùng nhập.
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

    // 2. Nhận diện Calo cơ sở (Base Calories) và đơn vị khẩu phần cơ sở (e.g. 100ml, 100g, 30g, 1 can...)
    int baseCalories = 0;
    double servingQuantity = 100.0;
    String unit = 'g';
    String servingSize = '100g';

    // Kiểm tra mẫu "100 kcal / 100ml" hoặc "100 kcal per 100ml" hoặc "80 kcal/100g"
    final caloPerUnitRegex = RegExp(
      r'(\d+)\s*(?:kcal|cal)\s*(?:\/|per|trên|trong)\s*(\d+(?:[.,]\d+)?)\s*(ml|g|kg|l)?',
      caseSensitive: false,
    );
    final caloPerUnitMatch = caloPerUnitRegex.firstMatch(rawOcrText);

    if (caloPerUnitMatch != null) {
      baseCalories = int.tryParse(caloPerUnitMatch.group(1) ?? '0') ?? 0;
      final parsedServing = double.tryParse((caloPerUnitMatch.group(2) ?? '100').replaceAll(',', '.')) ?? 100.0;
      servingQuantity = parsedServing;
      final u = caloPerUnitMatch.group(3)?.toLowerCase() ?? '';
      if (u == 'ml' || u == 'l') {
        unit = (u == 'l') ? 'l' : 'ml';
      } else {
        unit = (u == 'kg') ? 'kg' : 'g';
      }
      servingSize = '${servingQuantity.toInt()}$unit';
    } else {
      // Tìm calo chuẩn qua từ khóa Calories / Năng lượng / Calo
      final caloriesRegex = RegExp(
        r'(?:calories|energy|cal|calo|năng\s*lượng|nang\s*luong)[^\d\n]*?(\d+)(?:\s*(?:kcal|cal|kj))?',
        caseSensitive: false,
      );
      final calorieMatches = caloriesRegex.allMatches(rawOcrText).toList();
      if (calorieMatches.isNotEmpty) {
        baseCalories = int.tryParse(calorieMatches.first.group(1) ?? '0') ?? 0;
      } else {
        final kcalMatch = RegExp(r'(\d+)\s*kcal\b', caseSensitive: false).firstMatch(rawOcrText);
        if (kcalMatch != null) {
          baseCalories = int.tryParse(kcalMatch.group(1) ?? '0') ?? 0;
        }
      }

      // Tìm Serving Size chuẩn
      final servingRegex = RegExp(
        r'(?:serving\s*size|khẩu\s*phần|khau\s*phan)[:\s]+([^\n\r,]+)',
        caseSensitive: false,
      );
      final servingMatch = servingRegex.firstMatch(rawOcrText);
      if (servingMatch != null) {
        servingSize = servingMatch.group(1)?.trim() ?? '1 khẩu phần';
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
    }

    // 3. TÍNH TOÁN TỔNG KHỐI LƯỢNG / THỂ TÍCH & TỔNG CALO
    double? totalProductQuantity;
    bool hasTotalQuantity = false;
    int totalCalories = 0;
    String calculationNotes = '';

    // Trường hợp A: Khẩu phần chính là trọn vẹn sản phẩm (ví dụ "1 bar (60g)", "1 can", "1 lon", "1 chai", "1 gói")
    final isSingleContainer = servingSize.toLowerCase().contains('can') ||
        servingSize.toLowerCase().contains('lon') ||
        servingSize.toLowerCase().contains('chai') ||
        servingSize.toLowerCase().contains('gói') ||
        servingSize.toLowerCase().contains('hộp') ||
        servingSize.toLowerCase().contains('bar');

    if (isSingleContainer) {
      hasTotalQuantity = true;
      totalProductQuantity = servingQuantity;
      totalCalories = baseCalories;
      calculationNotes = '$baseCalories kcal (trọn $servingSize)';
    } else {
      // Trường hợp B: Nhãn có ghi rõ Thể tích thực / Khối lượng tịnh (Net Weight / Net Volume)
      final netWeightRegex = RegExp(
        r'(?:thể\s*tích\s*thực|thể\s*tích|dung\s*tích|khối\s*lượng\s*tịnh|kl\s*tịnh|klt|net\s*wt|net\s*weight|net\s*content|net\s*volume)[:\s]*(\d+(?:[.,]\d+)?)\s*(g|kg|ml|l|gam|lit|lít|oz)?',
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
            if (rawUnit.isNotEmpty) unit = (rawUnit == 'gam' ? 'g' : rawUnit);
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

      if (hasTotalQuantity && totalProductQuantity != null && totalProductQuantity > 0) {
        if (servingQuantity > 0) {
          final ratio = totalProductQuantity / servingQuantity;
          totalCalories = (baseCalories * ratio).round();
          final displayTotal = totalProductQuantity % 1 == 0 ? totalProductQuantity.toInt() : totalProductQuantity;
          final displayServing = servingQuantity % 1 == 0 ? servingQuantity.toInt() : servingQuantity;
          calculationNotes = '$baseCalories kcal/$displayServing$unit × $displayTotal$unit = $totalCalories kcal';
        } else {
          totalCalories = baseCalories;
          calculationNotes = '$totalCalories kcal';
        }
      } else if (servingsPerContainer > 1) {
        totalCalories = baseCalories * servingsPerContainer;
        hasTotalQuantity = true;
        totalProductQuantity = servingsPerContainer.toDouble();
        unit = 'khẩu phần';
        calculationNotes = '$baseCalories kcal × $servingsPerContainer khẩu phần = $totalCalories kcal';
      } else {
        // CHƯA CÓ TỔNG KHỐI LƯỢNG / THỂ TÍCH TRONG ẢNH
        hasTotalQuantity = false;
        totalCalories = 0; // Chưa có tổng để tính -> cần người dùng nhập
        calculationNotes = 'Chưa có tổng thể tích/khối lượng. Vui lòng nhập để tính tổng calo.';
      }
    }

    final rawJson = '''
{
  "food_name": "$foodName",
  "serving_size": "$servingSize",
  "calories_per_serving": $baseCalories,
  "serving_quantity": $servingQuantity,
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
      confidence: hasTotalQuantity ? 0.95 : 0.75,
      modelUsed: 'AI Total Calorie Extractor',
      rawJson: rawJson.trim(),
      rawOcrInput: rawOcrText,
      calculationNotes: calculationNotes,
    );
  }

  static String _cleanFoodName(String text) {
    var cleaned = text.replaceAll(RegExp(r'[^\p{L}\p{N}\s-]', unicode: true), '').trim();
    if (cleaned.length > 35) {
      cleaned = cleaned.substring(0, 35);
    }
    return cleaned.isNotEmpty ? cleaned : 'Sản phẩm';
  }
}
