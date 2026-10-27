import 'package:flutter/material.dart';
import '../../core/models/user_profile.dart';
import '../../core/theme/app_theme.dart';
import '../../features/profile/profile_controller.dart';
import '../../features/profile/tdee_calculator.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileController profileController;

  const ProfileScreen({
    super.key,
    required this.profileController,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Gender _gender;
  late double _weightKg;
  late double _heightCm;
  late int _age;
  late ActivityLevel _activityLevel;
  late CalorieGoal _goal;

  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    final p = widget.profileController.profile;
    _gender = p.gender;
    _weightKg = p.weightKg;
    _heightCm = p.heightCm;
    _age = p.age;
    _activityLevel = p.activityLevel;
    _goal = p.goal;

    _ageController = TextEditingController(text: _age.toString());
    _heightController = TextEditingController(text: _heightCm.toStringAsFixed(1));
    _weightController = TextEditingController(text: _weightKg.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  TdeeCalculationResult get _previewResult {
    final previewProfile = UserProfile(
      age: _age,
      heightCm: _heightCm,
      weightKg: _weightKg,
      gender: _gender,
      activityLevel: _activityLevel,
      goal: _goal,
    );
    return TdeeCalculator.calculate(previewProfile);
  }

  void _saveProfile() {
    widget.profileController.updateProfile(
      age: _age,
      heightCm: _heightCm,
      weightKg: _weightKg,
      gender: _gender,
      activityLevel: _activityLevel,
      goal: _goal,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile and TDEE updated successfully!'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _previewResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & TDEE Target'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TDEE Preview Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.2),
                    AppTheme.secondary.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Daily Calorie Target',
                    style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${result.targetCalories} kcal',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.caloriesColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MetricItem(label: 'BMR', value: '${result.bmr.round()} kcal'),
                      _MetricItem(label: 'TDEE Maintenance', value: '${result.tdee.round()} kcal'),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MacroPill(label: 'Protein', value: '${result.macros.proteinGrams}g', color: AppTheme.proteinColor),
                      _MacroPill(label: 'Carbs', value: '${result.macros.carbsGrams}g', color: AppTheme.carbsColor),
                      _MacroPill(label: 'Fat', value: '${result.macros.fatGrams}g', color: AppTheme.fatColor),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Gender Selection
            const Text(
              'Biological Gender (Mifflin-St Jeor)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Male (+5 formula)')),
                    selected: _gender == Gender.male,
                    onSelected: (val) {
                      if (val) setState(() => _gender = Gender.male);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Female (-161 formula)')),
                    selected: _gender == Gender.female,
                    onSelected: (val) {
                      if (val) setState(() => _gender = Gender.female);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Numeric Measurements
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age (years)'),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        setState(() => _age = parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Height (cm)'),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        setState(() => _heightCm = parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Weight (kg)'),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        setState(() => _weightKg = parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Activity Level Dropdown
            const Text(
              'Activity Level Factor',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ActivityLevel>(
                  isExpanded: true,
                  value: _activityLevel,
                  items: ActivityLevel.values.map((lvl) {
                    return DropdownMenuItem(
                      value: lvl,
                      child: Text('${lvl.label} (x${lvl.factor})', style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _activityLevel = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Calorie Goal Dropdown
            const Text(
              'Calorie Goal (Deficit / Surplus)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CalorieGoal>(
                  isExpanded: true,
                  value: _goal,
                  items: CalorieGoal.values.map((g) {
                    return DropdownMenuItem(
                      value: g,
                      child: Text(g.label, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _goal = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Profile & Update Target'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}

