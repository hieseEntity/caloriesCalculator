import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/food_entry.dart';
import '../../core/theme/app_theme.dart';
// AiNutritionExtractor interface + NutritionExtractionResult model
import '../../features/ai_nutrition/nutrition_extractor.dart';
// QwenNutritionExtractor — LLM pipeline: OCR text → prompt → tính dinh dưỡng
import '../../features/ai_nutrition/qwen_llm_service.dart' show QwenNutritionExtractor;
// OcrEngineFactory: tự động chọn engine theo nền tảng
//   Android → Google ML Kit | Linux → Tesseract OCR
import '../../features/ocr/ocr_engine_factory.dart';
import '../../features/ocr/ocr_service.dart';
import '../../features/tracker/tracker_controller.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/extracted_nutrition_table.dart';

class ScanScreen extends StatefulWidget {
  final TrackerController trackerController;
  final int targetCalories;

  const ScanScreen({
    super.key,
    required this.trackerController,
    required this.targetCalories,
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  // OCR Engine được chọn tự động theo nền tảng:
  //   Android → Google ML Kit (nhanh, chính xác, không cần file riêng)
  //   Linux   → Tesseract OCR (cần assets/tessdata/vie.traineddata + eng.traineddata)
  final OcrEngine _ocrEngine = OcrEngineFactory.create();
  // QwenNutritionExtractor: nhận OCR text → tạo prompt → tính toán dinh dưỡng
  final AiNutritionExtractor _aiExtractor = QwenNutritionExtractor();

  bool _isProcessing = false;
  String _currentStep = '';
  NutritionExtractionResult? _extractionResult;
  String? _selectedImagePath;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (photo != null) {
        _processImage(photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access image: $e')),
        );
      }
    }
  }

  /// Lấy thứ tự ảnh được chụp/chọn trong ngày, bắt đầu từ 1
  Future<int> _getNextDailyMealNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final today = widget.trackerController.currentDate.isNotEmpty
        ? widget.trackerController.currentDate
        : DateTime.now().toIso8601String().substring(0, 10);
    final key = 'daily_photo_scan_count_$today';
    int current = prefs.getInt(key) ?? 0;

    final savedToday = widget.trackerController.todayEntries.length;
    if (current < savedToday) {
      current = savedToday;
    }

    final next = current + 1;
    await prefs.setInt(key, next);
    return next;
  }

  Future<void> _processImage(String path) async {
    setState(() {
      _selectedImagePath = path;
      _isProcessing = true;
      _currentStep = 'Đang nhận diện chữ qua ${OcrEngineFactory.platformEngineName}...';
      _extractionResult = null;
    });

    // 1. Phase 2: Run OCR
    final ocr = await _ocrEngine.processImage(path);

    setState(() {
      _currentStep = 'AI đang tính toán tổng lượng Calo...';
    });

    // 2. Phase 3: Run Qwen2.5-0.5B Extractor & Calculation Engine
    final extraction = await _aiExtractor.extractNutrition(ocr.rawText);

    // Đổi tên hiển thị thành "Meal thứ n" (thứ tự ảnh được chụp/chọn trong ngày, bắt đầu từ 1)
    final mealNumber = await _getNextDailyMealNumber();
    final mealResult = extraction.copyWith(foodName: 'Meal thứ $mealNumber');

    setState(() {
      _extractionResult = mealResult;
      _isProcessing = false;
      _currentStep = 'Tính toán hoàn tất!';
    });
  }

  Future<void> _saveEntry(FoodEntry entry) async {
    await widget.trackerController.addFoodEntry(entry, widget.targetCalories);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm "${entry.name}" (${entry.calories} kcal) vào nhật ký hôm nay!'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _runPresetDemo(String sampleType) async {
    final tempDir = Directory.systemTemp;
    final sampleFile = File('${tempDir.path}/sample_$sampleType.jpg');
    if (!await sampleFile.exists()) {
      await sampleFile.writeAsString('sample food packaging');
    }
    _processImage(sampleFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Nutrition Scanner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Architecture Info Badge
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: AppTheme.caloriesColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '100% On-Device AI Pipeline',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        Text(
                          // Hiển thị tên OCR engine đang dùng theo nền tảng
                          '${OcrEngineFactory.platformEngineName} → Qwen2.5-0.5B LLM',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Image Preview or Placeholder
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isProcessing ? AppTheme.primary : Colors.white.withOpacity(0.1),
                  width: _isProcessing ? 2 : 1,
                ),
              ),
              child: _isProcessing
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppTheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            _currentStep,
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : _selectedImagePath != null && File(_selectedImagePath!).existsSync() && _selectedImagePath!.endsWith('.jpg')
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            File(_selectedImagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                          ),
                        )
                      : _buildPlaceholder(),
            ),
            const SizedBox(height: 24),

            // Camera & Gallery Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick Image'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Demo / Testing Presets
            const Text(
              'Quick Test Presets (Zero Camera Needed)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white60),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.calculate, size: 16, color: AppTheme.caloriesColor),
                  label: const Text('Combo Meal (Multi-Item Sum)'),
                  onPressed: _isProcessing ? null : () => _runPresetDemo('lunch_combo'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.fitness_center, size: 16, color: AppTheme.proteinColor),
                  label: const Text('Protein Crunch Bar'),
                  onPressed: _isProcessing ? null : () => _runPresetDemo('protein_bar'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.breakfast_dining, size: 16, color: AppTheme.fatColor),
                  label: const Text('Oatmeal Energy Pack'),
                  onPressed: _isProcessing ? null : () => _runPresetDemo('oatmeal_snack'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bảng Thông Tin Dinh Dưỡng Bóc Tách (Extracted Nutrition Table)
            if (_extractionResult != null) ...[
              ExtractedNutritionTable(
                extractionResult: _extractionResult!,
                targetCalories: widget.targetCalories,
                onEdit: () async {
                  final entry = await ConfirmationDialog.show(
                    context,
                    extractionResult: _extractionResult!,
                    dateString: widget.trackerController.currentDate,
                    imagePath: _selectedImagePath,
                  );
                  if (entry != null) {
                    await _saveEntry(entry);
                  }
                },
                onConfirm: (updatedResult) async {
                  final entry = FoodEntry(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: updatedResult.foodName,
                    calories: updatedResult.calories,
                    protein: updatedResult.protein,
                    carbs: updatedResult.carbs,
                    fat: updatedResult.fat,
                    timestamp: DateTime.now(),
                    dateString: widget.trackerController.currentDate,
                    imagePath: _selectedImagePath,
                    rawOcrText: updatedResult.rawOcrInput,
                  );
                  await _saveEntry(entry);
                },
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.document_scanner_outlined, size: 54, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            'Capture food label or select test preset',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
