import 'package:flutter/material.dart';
import '../../core/models/food_entry.dart';
import '../../core/theme/app_theme.dart';
import '../../features/ai_nutrition/nutrition_extractor.dart';

/// Hộp thoại xem lại và xác nhận TỔNG CALO trước khi lưu vào nhật ký
class ConfirmationDialog extends StatefulWidget {
  final NutritionExtractionResult extractionResult;
  final String dateString;
  final String? imagePath;

  const ConfirmationDialog({
    super.key,
    required this.extractionResult,
    required this.dateString,
    this.imagePath,
  });

  static Future<FoodEntry?> show(
    BuildContext context, {
    required NutritionExtractionResult extractionResult,
    required String dateString,
    String? imagePath,
  }) {
    return showModalBottomSheet<FoodEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConfirmationDialog(
        extractionResult: extractionResult,
        dateString: dateString,
        imagePath: imagePath,
      ),
    );
  }

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _quantityController;
  bool _showRawOcr = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.extractionResult.foodName);
    _caloriesController = TextEditingController(text: widget.extractionResult.calories.toString());

    final qty = widget.extractionResult.totalProductQuantity;
    _quantityController = TextEditingController(
      text: qty != null && qty > 0 ? (qty % 1 == 0 ? qty.toInt().toString() : qty.toString()) : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final entry = FoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Sản phẩm',
      calories: int.tryParse(_caloriesController.text) ?? 0,
      protein: 0.0,
      carbs: 0.0,
      fat: 0.0,
      timestamp: DateTime.now(),
      dateString: widget.dateString,
      imagePath: widget.imagePath,
      rawOcrText: widget.extractionResult.rawOcrInput,
    );

    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xác nhận Tổng Calo Sản Phẩm',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Kiểm tra lại số liệu trước khi lưu vào nhật ký',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (widget.extractionResult.calculationNotes != null &&
                widget.extractionResult.calculationNotes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calculate_outlined, color: AppTheme.caloriesColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.extractionResult.calculationNotes!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Tên sản phẩm
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên món ăn / sản phẩm',
                prefixIcon: Icon(Icons.fastfood_outlined, color: Colors.white54),
              ),
            ),

            const SizedBox(height: 14),

            // Tổng Calo (kcal)
            TextField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.caloriesColor),
              decoration: const InputDecoration(
                labelText: 'Tổng Calo của cả sản phẩm (kcal)',
                prefixIcon: Icon(Icons.local_fire_department, color: AppTheme.caloriesColor),
              ),
            ),

            const SizedBox(height: 14),

            // Khối lượng / Thể tích
            TextField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Tổng khối lượng / thể tích (${widget.extractionResult.unit})',
                prefixIcon: const Icon(Icons.scale_rounded, color: Colors.white54),
                helperText: widget.extractionResult.hasTotalQuantity
                    ? 'Đã tự động trích xuất từ nhãn'
                    : 'Nhập để điều chỉnh nếu nhãn không có',
              ),
            ),

            const SizedBox(height: 12),

            // Toggle Raw OCR Text
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _showRawOcr = !_showRawOcr),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      _showRawOcr ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: Colors.white60,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _showRawOcr ? 'Ẩn văn bản OCR gốc' : 'Xem văn bản OCR gốc từ ảnh',
                      style: const TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),

            if (_showRawOcr)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.extractionResult.rawOcrInput.isNotEmpty
                      ? widget.extractionResult.rawOcrInput
                      : '(Không có văn bản OCR)',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Hủy bỏ', style: TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Lưu vào nhật ký', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
