import 'package:flutter/material.dart';
import '../../core/models/food_entry.dart';
import '../../core/theme/app_theme.dart';
import '../../features/ai_nutrition/nutrition_extractor.dart';

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
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  bool _showRawOcr = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.extractionResult.foodName);
    _caloriesController = TextEditingController(text: widget.extractionResult.calories.toString());
    _proteinController = TextEditingController(text: widget.extractionResult.protein.toStringAsFixed(1));
    _carbsController = TextEditingController(text: widget.extractionResult.carbs.toStringAsFixed(1));
    _fatController = TextEditingController(text: widget.extractionResult.fat.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final entry = FoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Meal',
      calories: int.tryParse(_caloriesController.text) ?? 0,
      protein: double.tryParse(_proteinController.text) ?? 0.0,
      carbs: double.tryParse(_carbsController.text) ?? 0.0,
      fat: double.tryParse(_fatController.text) ?? 0.0,
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
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Extracted Nutrition',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Verify values before saving to your daily log',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.extractionResult.calculationNotes != null &&
                widget.extractionResult.calculationNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            const SizedBox(height: 16),
            // Bảng tóm tắt thông tin bóc tách
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardColor.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'BẢNG BÓC TÁCH GỐC (EXTRACTED)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white70),
                      ),
                      Text(
                        'Khẩu phần: ${widget.extractionResult.servingSize}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.caloriesColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _CompactMacroBadge(label: 'Năng lượng', value: '${widget.extractionResult.calories} kcal', color: AppTheme.caloriesColor),
                      _CompactMacroBadge(label: 'Đạm (P)', value: '${widget.extractionResult.protein.toStringAsFixed(1)}g', color: AppTheme.proteinColor),
                      _CompactMacroBadge(label: 'Carb (C)', value: '${widget.extractionResult.carbs.toStringAsFixed(1)}g', color: AppTheme.carbsColor),
                      _CompactMacroBadge(label: 'Béo (F)', value: '${widget.extractionResult.fat.toStringAsFixed(1)}g', color: AppTheme.fatColor),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Food / Meal Name',
                prefixIcon: Icon(Icons.fastfood_outlined, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Calories (kcal)',
                      prefixIcon: Icon(Icons.local_fire_department, color: AppTheme.caloriesColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _proteinController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Protein (g)',
                      prefixIcon: Icon(Icons.fitness_center, color: AppTheme.proteinColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _carbsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Carbs (g)',
                      prefixIcon: Icon(Icons.grain, color: AppTheme.carbsColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _fatController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Fat (g)',
                      prefixIcon: Icon(Icons.opacity, color: AppTheme.fatColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            InkWell(
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
                      _showRawOcr ? 'Hide Raw OCR Text' : 'View Raw OCR Text',
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
                      : '(No raw OCR text)',
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
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onConfirm,
                    child: const Text('Save Entry'),
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

class _CompactMacroBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CompactMacroBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

