import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/ai_nutrition/nutrition_extractor.dart';

/// ============================================================
/// Bảng Hiển Thị Thông Tin Dinh Dưỡng Bóc Tách (Nutrition Table)
/// ============================================================
///
/// Trực quan hóa toàn bộ dữ liệu dinh dưỡng được trích xuất từ OCR & LLM:
///   - Tên món ăn & khẩu phần
///   - Tổng lượng Calo & tỷ lệ phân bổ Macro (Protein, Carbs, Fat)
///   - Bảng chi tiết từng chất dinh dưỡng (Khối lượng, Calo tương ứng, Tỷ lệ %)
///   - Ghi chú tính toán (Công thức Atwater / Tổng hợp nhiều món)
///   - Đối chiếu văn bản gốc OCR (Raw OCR Text)
class ExtractedNutritionTable extends StatefulWidget {
  final NutritionExtractionResult extractionResult;
  final VoidCallback? onConfirm;
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
  bool _isRawOcrExpanded = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.extractionResult;

    // Tính toán năng lượng từ từng macro theo công thức Atwater chuẩn:
    // Protein: 4 kcal/g, Carbs: 4 kcal/g, Fat: 9 kcal/g
    final proteinKcal = result.protein * 4;
    final carbsKcal = result.carbs * 4;
    final fatKcal = result.fat * 9;
    final totalMacroKcal = proteinKcal + carbsKcal + fatKcal;

    final proteinPct = totalMacroKcal > 0 ? (proteinKcal / totalMacroKcal * 100).round() : 0;
    final carbsPct = totalMacroKcal > 0 ? (carbsKcal / totalMacroKcal * 100).round() : 0;
    final fatPct = totalMacroKcal > 0 ? (fatKcal / totalMacroKcal * 100).round() : 0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.caloriesColor.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TIÊU ĐỀ BẢNG (TABLE HEADER)
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
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.table_chart_rounded, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THÔNG TIN DINH DƯỠNG BÓC TÁCH',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Extracted Nutrition Facts Table',
                        style: TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.secondary.withOpacity(0.4)),
                  ),
                  child: Text(
                    result.modelUsed,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.proteinColor,
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
                // 2. TÊN MÓN ĂN & KHẨU PHẦN
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
                          Row(
                            children: [
                              const Icon(Icons.scale_rounded, size: 14, color: Colors.white60),
                              const SizedBox(width: 5),
                              Text(
                                'Khẩu phần: ${result.servingSize}',
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Hộp Calo nổi bật
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withOpacity(0.2),
                            AppTheme.caloriesColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${result.calories}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.caloriesColor,
                              height: 1.0,
                            ),
                          ),
                          const Text(
                            'KCAL / CALO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 3. BẢNG CHI TIẾT CÁC THÀNH PHẦN (STRUCTURED DATA TABLE)
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.background.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2.6), // Thành phần
                        1: FlexColumnWidth(1.8), // Khối lượng
                        2: FlexColumnWidth(1.8), // Năng lượng
                        3: FlexColumnWidth(1.3), // Tỷ lệ
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        // Hàng tiêu đề bảng
                        TableRow(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                          ),
                          children: const [
                            _HeaderCell('Thành phần'),
                            _HeaderCell('Khối lượng'),
                            _HeaderCell('Năng lượng'),
                            _HeaderCell('Tỷ lệ'),
                          ],
                        ),

                        // Hàng 1: Chất đạm (Protein)
                        _buildMacroRow(
                          name: 'Chất đạm (Protein)',
                          amount: '${result.protein.toStringAsFixed(1)} g',
                          energy: '${proteinKcal.round()} kcal',
                          percentage: '$proteinPct%',
                          color: AppTheme.proteinColor,
                          icon: Icons.fitness_center_rounded,
                        ),

                        // Hàng 2: Tinh bột (Carbohydrates)
                        _buildMacroRow(
                          name: 'Tinh bột (Carbs)',
                          amount: '${result.carbs.toStringAsFixed(1)} g',
                          energy: '${carbsKcal.round()} kcal',
                          percentage: '$carbsPct%',
                          color: AppTheme.carbsColor,
                          icon: Icons.grain_rounded,
                        ),

                        // Hàng 3: Chất béo (Total Fat)
                        _buildMacroRow(
                          name: 'Chất béo (Fat)',
                          amount: '${result.fat.toStringAsFixed(1)} g',
                          energy: '${fatKcal.round()} kcal',
                          percentage: '$fatPct%',
                          color: AppTheme.fatColor,
                          icon: Icons.opacity_rounded,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. GHI CHÚ TÍNH TOÁN / CÔNG THỨC ATWATER
                if (result.calculationNotes != null && result.calculationNotes!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.secondary.withOpacity(0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.calculate_outlined, color: AppTheme.secondary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Công thức & Chi tiết tính toán:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.proteinColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                result.calculationNotes!,
                                style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 5. KHU VỰC XEM RAW OCR TEXT (EXPANDABLE)
                if (result.rawOcrInput.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
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
                            'Xem văn bản gốc OCR nhận diện được',
                            style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
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

                // 6. NÚT XÁC NHẬN / CHỈNH SỬA
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
                            label: const Text(
                              'Lưu vào nhật ký',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: widget.onConfirm,
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

  static TableRow _buildMacroRow({
    required String name,
    required String amount,
    required String energy,
    required String percentage,
    required Color color,
    required IconData icon,
    bool isLast = false,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(
            amount,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(
            energy,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(
            percentage,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
