import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/ai_nutrition/nutrition_extractor.dart';

/// ============================================================
/// Bảng Hiển Thị & Tính Toán TỔNG CALO Sản Phẩm (Total Calorie Panel)
/// ============================================================
///
/// Tính năng:
///   - Chỉ tập trung vào CALO (loại bỏ protein, carbs, fat theo yêu cầu).
///   - Tự động nhận diện tổng khối lượng/thể tích từ ảnh nếu có.
///   - Nếu chưa nhận diện được tổng khối lượng/thể tích -> Hiện thông báo
///     yêu cầu người dùng nhập vào ô bên dưới.
///   - Cho phép người dùng nhập/chỉnh sửa tổng khối lượng/thể tích để AI
///     tính toán lại tổng calo của cả sản phẩm trong thời gian thực (realtime).
class ExtractedNutritionTable extends StatefulWidget {
  final NutritionExtractionResult extractionResult;
  final Function(NutritionExtractionResult updatedResult)? onConfirm;
  final VoidCallback? onEdit;
  final int? targetCalories;

  const ExtractedNutritionTable({
    super.key,
    required this.extractionResult,
    this.onConfirm,
    this.onEdit,
    this.targetCalories,
  });

  @override
  State<ExtractedNutritionTable> createState() => _ExtractedNutritionTableState();
}

class _ExtractedNutritionTableState extends State<ExtractedNutritionTable> {
  late NutritionExtractionResult _currentResult;
  late TextEditingController _quantityController;
  late String _selectedUnit;
  bool _isRawOcrExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentResult = widget.extractionResult;
    _selectedUnit = _currentResult.unit.isNotEmpty ? _currentResult.unit : 'g';

    final initialQty = _currentResult.totalProductQuantity;
    _quantityController = TextEditingController(
      text: initialQty != null && initialQty > 0 ? (initialQty % 1 == 0 ? initialQty.toInt().toString() : initialQty.toString()) : '',
    );
  }

  @override
  void didUpdateWidget(covariant ExtractedNutritionTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.extractionResult != widget.extractionResult) {
      _currentResult = widget.extractionResult;
      _selectedUnit = _currentResult.unit.isNotEmpty ? _currentResult.unit : 'g';
      final initialQty = _currentResult.totalProductQuantity;
      _quantityController.text = initialQty != null && initialQty > 0
          ? (initialQty % 1 == 0 ? initialQty.toInt().toString() : initialQty.toString())
          : '';
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _onQuantityChanged(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed != null && parsed > 0) {
      setState(() {
        _currentResult = _currentResult.copyWithTotalQuantity(parsed, newUnit: _selectedUnit);
      });
    } else if (value.trim().isEmpty) {
      setState(() {
        _currentResult = widget.extractionResult;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _currentResult;
    final hasTotal = result.hasTotalQuantity && result.totalProductQuantity != null && result.totalProductQuantity! > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasTotal ? AppTheme.caloriesColor.withOpacity(0.4) : Colors.amber.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TIÊU ĐỀ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.cardColor.withOpacity(0.4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.caloriesColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_fire_department_rounded, color: AppTheme.caloriesColor, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TỔNG CALO CỦA SẢN PHẨM',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'AI Total Calories Calculation',
                        style: TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    result.modelUsed,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 2. TÊN SẢN PHẨM & KHẨU PHẦN CƠ SỞ
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.foodName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Khẩu phần chuẩn trên nhãn: ${result.servingSize}',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                          if (result.caloriesPerServing > 0)
                            Text(
                              'Calo cơ sở: ${result.caloriesPerServing} kcal / ${result.servingSize}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.caloriesColor.withOpacity(0.85),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // HỘP HIỂN THỊ TỔNG CALO NỔI BẬT
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withOpacity(0.25),
                            AppTheme.caloriesColor.withOpacity(0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${result.calories}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.caloriesColor,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'TỔNG CALO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            '(KCAL)',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 3. THÔNG BÁO TRẠNG THÁI NHẬN DIỆN KHỐI LƯỢNG / THỂ TÍCH
                if (hasTotal) ...[
                  // ĐÃ nhận diện được tổng khối lượng từ ảnh
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Đã nhận diện tổng: ${result.totalProductQuantity! % 1 == 0 ? result.totalProductQuantity!.toInt() : result.totalProductQuantity} $selectedUnitDisplay',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // CHƯA nhận diện được tổng khối lượng từ ảnh -> THÔNG BÁO YÊU CẦU NGƯỜI DÙNG NHẬP
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.6)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chưa nhận diện được tổng khối lượng / thể tích',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Vui lòng nhập tổng khối lượng hoặc thể tích của sản phẩm vào ô dưới để AI tính tổng lượng calo chính xác!',
                                style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // 4. Ô NHẬP TỔNG KHỐI LƯỢNG / THỂ TÍCH ĐỂ GIÚP AI TÍNH TOÁN
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.background.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng khối lượng / thể tích của cả sản phẩm:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Nhập số (vd: 250, 330, 500)',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
                                prefixIcon: const Icon(Icons.scale_rounded, color: AppTheme.caloriesColor, size: 18),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                fillColor: AppTheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                              ),
                              onChanged: _onQuantityChanged,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Dropdown chọn đơn vị (g, ml, khẩu phần, lon, gói)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.15)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: ['g', 'ml', 'khẩu phần', 'lon', 'gói', 'hộp'].contains(_selectedUnit)
                                    ? _selectedUnit
                                    : 'g',
                                dropdownColor: AppTheme.surface,
                                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                                items: const [
                                  DropdownMenuItem(value: 'g', child: Text('Gam (g)')),
                                  DropdownMenuItem(value: 'ml', child: Text('Mililit (ml)')),
                                  DropdownMenuItem(value: 'khẩu phần', child: Text('Khẩu phần')),
                                  DropdownMenuItem(value: 'lon', child: Text('Lon')),
                                  DropdownMenuItem(value: 'gói', child: Text('Gói')),
                                  DropdownMenuItem(value: 'hộp', child: Text('Hộp')),
                                ],
                                onChanged: (newUnit) {
                                  if (newUnit != null) {
                                    setState(() {
                                      _selectedUnit = newUnit;
                                      _onQuantityChanged(_quantityController.text);
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 5. GHI CHÚ CÔNG THỨC TÍNH TOÁN
                if (result.calculationNotes != null && result.calculationNotes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.calculate_rounded, color: AppTheme.caloriesColor, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chi tiết phép tính:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.caloriesColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                result.calculationNotes!,
                                style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 6. XEM RAW OCR TEXT (EXPANDABLE)
                if (result.rawOcrInput.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _isRawOcrExpanded = !_isRawOcrExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            _isRawOcrExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                            size: 18,
                            color: Colors.white60,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Xem văn bản gốc OCR nhận diện được từ bao bì',
                            style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isRawOcrExpanded) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        result.rawOcrInput,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.white60,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ],

                // 7. CÁC NÚT THAO TÁC (LƯU VÀO NHẬT KÝ)
                if (widget.onConfirm != null || widget.onEdit != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (widget.onEdit != null)
                        Expanded(
                          flex: 1,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withOpacity(0.2)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.edit_note_rounded, size: 18),
                            label: const Text('Chỉnh sửa'),
                            onPressed: widget.onEdit,
                          ),
                        ),
                      if (widget.onConfirm != null && widget.onEdit != null)
                        const SizedBox(width: 10),
                      if (widget.onConfirm != null)
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                            label: Text(
                              'Lưu ${result.calories} kcal vào nhật ký',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => widget.onConfirm!(_currentResult),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get selectedUnitDisplay {
    switch (_selectedUnit) {
      case 'g':
        return 'gam (g)';
      case 'ml':
        return 'ml';
      default:
        return _selectedUnit;
    }
  }
}
