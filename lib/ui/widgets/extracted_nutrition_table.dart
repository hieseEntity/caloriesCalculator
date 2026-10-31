import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/ai_nutrition/nutrition_extractor.dart';

/// ============================================================
/// Bảng Hiển Thị TỔNG CALO BẠN SẼ NẠP (Total Calorie Output)
/// ============================================================
///
/// Hoạt động theo quy trình:
///   1. Kiểm tra xem ảnh có chứa tổng khối lượng/thể tích của sản phẩm hay không.
///   2. NẾU CÓ: Tự động tính toán (Calo cơ sở × Tổng thể tích / Thể tích chuẩn)
///      và hiển thị DUY NHẤT con số TỔNG CALO người dùng sẽ nạp.
///   3. NẾU KHÔNG CÓ: Hiển thị thông báo yêu cầu người dùng nhập tổng khối lượng/thể tích
///      vào ô nhập để AI tính toán ngay lập tức.
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
  bool _showEditQuantity = false;

  @override
  void initState() {
    super.initState();
    _initData(widget.extractionResult);
  }

  @override
  void didUpdateWidget(covariant ExtractedNutritionTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.extractionResult != widget.extractionResult) {
      _initData(widget.extractionResult);
    }
  }

  void _initData(NutritionExtractionResult result) {
    _currentResult = result;
    _selectedUnit = result.unit.isNotEmpty ? result.unit : 'ml';
    final qty = result.totalProductQuantity;
    _quantityController = TextEditingController(
      text: qty != null && qty > 0 ? (qty % 1 == 0 ? qty.toInt().toString() : qty.toString()) : '',
    );
    _showEditQuantity = !result.hasTotalQuantity;
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
    } else {
      setState(() {
        _currentResult = widget.extractionResult;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _currentResult;
    final hasTotal = result.hasTotalQuantity && result.calories > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasTotal ? AppTheme.caloriesColor.withOpacity(0.5) : Colors.amber.withOpacity(0.6),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TÊN SẢN PHẨM & BADGE AI
          Row(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.foodName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      result.caloriesPerServing > 0
                          ? 'Calo cơ sở: ${result.caloriesPerServing} kcal'
                          : 'Khẩu phần: ${result.servingSize}',
                      style: const TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. KHI ĐÃ CÓ TỔNG CALO: CHỈ HIỂN THỊ DUY NHẤT TỔNG CALO BẠN SẼ NẠP
          if (hasTotal) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.2),
                    AppTheme.caloriesColor.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.caloriesColor.withOpacity(0.6), width: 1.5),
              ),
              child: Column(
                children: [
                  const Text(
                    'TỔNG CALO BẠN SẼ NẠP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${result.calories}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.caloriesColor,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'kcal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  if (result.calculationNotes != null && result.calculationNotes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        result.calculationNotes!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Nút bấm mở/đóng ô điều chỉnh khối lượng
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: () => setState(() => _showEditQuantity = !_showEditQuantity),
                icon: Icon(
                  _showEditQuantity ? Icons.keyboard_arrow_up_rounded : Icons.edit_note_rounded,
                  size: 16,
                  color: Colors.white60,
                ),
                label: Text(
                  _showEditQuantity
                      ? 'Thu gọn ô điều chỉnh'
                      : 'Điều chỉnh tổng thể tích/khối lượng (${_currentResult.totalProductQuantity != null ? "${_currentResult.totalProductQuantity} $_selectedUnit" : ""})',
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
              ),
            ),
          ] else ...[
            // 3. KHI CHƯA NHẬN DIỆN ĐƯỢC TỔNG: HIỂN THỊ YÊU CẦU NGƯỜI DÙNG NHẬP
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bao bì có: ${result.caloriesPerServing > 0 ? "${result.caloriesPerServing} kcal" : "chưa rõ tổng"}.\nNhập tổng lượng bên dưới để AI tính tổng calo bạn sẽ nạp:',
                      style: const TextStyle(fontSize: 12, color: Colors.white, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 4. Ô NHẬP TỔNG THỂ TÍCH / KHỐI LƯỢNG
          if (_showEditQuantity || !hasTotal) ...[
            const SizedBox(height: 12),
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
                    'Nhập tổng thể tích / khối lượng của cả sản phẩm:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Ví dụ: 500, 330, 250...',
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: ['ml', 'g', 'khẩu phần', 'lon', 'gói', 'hộp'].contains(_selectedUnit)
                                ? _selectedUnit
                                : 'ml',
                            dropdownColor: AppTheme.surface,
                            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                            items: const [
                              DropdownMenuItem(value: 'ml', child: Text('Mililit (ml)')),
                              DropdownMenuItem(value: 'g', child: Text('Gam (g)')),
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
          ],

          const SizedBox(height: 18),

          // 5. NÚT LƯU VÀO NHẬT KÝ DUY NHẤT
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: hasTotal ? AppTheme.primary : AppTheme.cardColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: hasTotal ? 3 : 0,
            ),
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: Text(
              hasTotal
                  ? 'Lưu ${result.calories} kcal vào nhật ký'
                  : 'Vui lòng nhập lượng tổng để tính calo',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            onPressed: hasTotal && widget.onConfirm != null
                ? () => widget.onConfirm!(_currentResult)
                : null,
          ),
        ],
      ),
    );
  }
}
