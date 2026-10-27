import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../features/ai_nutrition/nutrition_extractor.dart';
import '../../features/ai_nutrition/qwen_llm_service.dart';
import '../../features/ocr/ocr_service.dart';
import '../../features/ocr/pp_ocr_mobile_engine.dart';
import '../../features/tracker/tracker_controller.dart';
import '../widgets/confirmation_dialog.dart';

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
  final OcrEngine _ocrEngine = PpOcrMobileEngine();
  final AiNutritionExtractor _aiExtractor = QwenNutritionExtractor();

  bool _isProcessing = false;
  String _currentStep = '';
  OcrResult? _ocrResult;
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

  Future<void> _processImage(String path) async {
    setState(() {
      _selectedImagePath = path;
      _isProcessing = true;
      _currentStep = 'Phase 2: Running PP-OCRv4 Mobile...';
      _ocrResult = null;
      _extractionResult = null;
    });

    // 1. Phase 2: Run PP-OCRv4
    final ocr = await _ocrEngine.processImage(path);

    setState(() {
      _ocrResult = ocr;
      _currentStep = 'Phase 3: Parsing via Qwen2.5-0.5B INT4...';
    });

    // 2. Phase 3: Run Qwen2.5-0.5B Extractor
    final extraction = await _aiExtractor.extractNutrition(ocr.rawText);

    setState(() {
      _extractionResult = extraction;
      _isProcessing = false;
      _currentStep = 'Extraction Complete!';
    });

    // 3. Phase 4: Show User Confirmation Prompt
    if (!mounted) return;
    final entry = await ConfirmationDialog.show(
      context,
      extractionResult: extraction,
      dateString: widget.trackerController.currentDate,
      imagePath: path,
    );

    if (entry != null && mounted) {
      await widget.trackerController.addFoodEntry(entry, widget.targetCalories);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${entry.name}" (${entry.calories} kcal) to today\'s log!'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                          'PP-OCRv4 Mobile (<300ms) ➔ Qwen2.5-0.5B INT4',
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
                  avatar: const Icon(Icons.fitness_center, size: 16, color: AppTheme.proteinColor),
                  label: const Text('Protein Crunch Bar'),
                  onPressed: _isProcessing ? null : () => _runPresetDemo('protein_bar'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.eco, size: 16, color: AppTheme.primary),
                  label: const Text('Chicken Salad Bowl'),
                  onPressed: _isProcessing ? null : () => _runPresetDemo('chicken_salad'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.breakfast_dining, size: 16, color: AppTheme.fatColor),
                  label: const Text('Oatmeal Snack Pack'),
                  onPressed: _isProcessing ? null : () => _runPresetDemo('oatmeal_snack'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pipeline Telemetry Card if results present
            if (_ocrResult != null && _extractionResult != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.caloriesColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppTheme.caloriesColor, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Pipeline Telemetry',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_ocrResult!.latencyMs} ms',
                            style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 18),
                    _TelemetryRow(label: 'OCR Engine', value: _ocrResult!.engine),
                    _TelemetryRow(label: 'AI Extractor', value: _extractionResult!.modelUsed),
                    _TelemetryRow(label: 'Confidence', value: '${(_extractionResult!.confidence * 100).toInt()}%'),
                    _TelemetryRow(label: 'Extracted Calories', value: '${_extractionResult!.calories} kcal'),
                    _TelemetryRow(
                      label: 'Extracted Macros',
                      value: 'P: ${_extractionResult!.protein.toInt()}g | C: ${_extractionResult!.carbs.toInt()}g | F: ${_extractionResult!.fat.toInt()}g',
                    ),
                  ],
                ),
              ),
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

class _TelemetryRow extends StatelessWidget {
  final String label;
  final String value;

  const _TelemetryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}
