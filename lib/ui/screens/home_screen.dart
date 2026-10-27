import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/food_entry.dart';
import '../../core/theme/app_theme.dart';
import '../../features/profile/profile_controller.dart';
import '../../features/tracker/tracker_controller.dart';
import '../widgets/calorie_gauge.dart';
import '../widgets/food_entry_tile.dart';
import '../widgets/macro_progress_card.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  final ProfileController profileController;
  final TrackerController trackerController;

  const HomeScreen({
    super.key,
    required this.profileController,
    required this.trackerController,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.profileController.addListener(_onProfileChanged);
    widget.trackerController.addListener(_onTrackerChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.profileController.removeListener(_onProfileChanged);
    widget.trackerController.removeListener(_onTrackerChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check for day rollover (00:00 midnight reset)
      widget.trackerController.checkRollover(widget.profileController.tdeeResult.targetCalories);
    }
  }

  void _onProfileChanged() => setState(() {});
  void _onTrackerChanged() => setState(() {});

  void _showManualAddDialog() {
    final nameCtrl = TextEditingController();
    final calsCtrl = TextEditingController();
    final proteinCtrl = TextEditingController(text: '0');
    final carbsCtrl = TextEditingController(text: '0');
    final fatCtrl = TextEditingController(text: '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Manual Meal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Meal Name', prefixIcon: Icon(Icons.restaurant)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: calsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calories (kcal)',
                  prefixIcon: Icon(Icons.local_fire_department, color: AppTheme.caloriesColor),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: proteinCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Protein (g)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: carbsCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Carbs (g)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fatCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Fat (g)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final entry = FoodEntry(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Manual Meal',
                    calories: int.tryParse(calsCtrl.text) ?? 0,
                    protein: double.tryParse(proteinCtrl.text) ?? 0.0,
                    carbs: double.tryParse(carbsCtrl.text) ?? 0.0,
                    fat: double.tryParse(fatCtrl.text) ?? 0.0,
                    timestamp: DateTime.now(),
                    dateString: widget.trackerController.currentDate,
                  );

                  widget.trackerController.addFoodEntry(
                    entry,
                    widget.profileController.tdeeResult.targetCalories,
                  );
                  Navigator.of(ctx).pop();
                },
                child: const Text('Add Meal'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tdee = widget.profileController.tdeeResult;
    final tracker = widget.trackerController;

    final screens = [
      _buildDashboard(context, tdee, tracker),
      ScanScreen(
        trackerController: tracker,
        targetCalories: tdee.targetCalories,
      ),
      HistoryScreen(
        trackerController: tracker,
        targetCalories: tdee.targetCalories,
      ),
      ProfileScreen(
        profileController: widget.profileController,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.primary.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.primary),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt, color: AppTheme.primary),
            label: 'AI Scanner',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppTheme.primary),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.primary),
            label: 'TDEE Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, dynamic tdee, TrackerController tracker) {
    final todayFormatted = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Calories Calculator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text(
              todayFormatted,
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
            tooltip: 'Add Manual Meal',
            onPressed: _showManualAddDialog,
          ),
        ],
      ),
      body: tracker.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: () async {
                await tracker.checkRollover(tdee.targetCalories);
                await tracker.loadTodayEntries();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Calorie Gauge
                    CalorieGauge(
                      consumed: tracker.consumedCalories,
                      target: tdee.targetCalories,
                    ),
                    const SizedBox(height: 24),

                    // Macro Progress Cards
                    Row(
                      children: [
                        MacroProgressCard(
                          label: 'Protein',
                          consumed: tracker.consumedProtein,
                          target: tdee.macros.proteinGrams,
                          color: AppTheme.proteinColor,
                        ),
                        const SizedBox(width: 8),
                        MacroProgressCard(
                          label: 'Carbs',
                          consumed: tracker.consumedCarbs,
                          target: tdee.macros.carbsGrams,
                          color: AppTheme.carbsColor,
                        ),
                        const SizedBox(width: 8),
                        MacroProgressCard(
                          label: 'Fat',
                          consumed: tracker.consumedFat,
                          target: tdee.macros.fatGrams,
                          color: AppTheme.fatColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick AI Scanner CTA Card
                    InkWell(
                      onTap: () => setState(() => _currentIndex = 1),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary.withOpacity(0.18),
                              AppTheme.secondary.withOpacity(0.15),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: AppTheme.caloriesColor, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Scan Food Packaging / Label',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Google ML Kit + Qwen2.5-0.5B on-device AI',
                                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Today's Meals Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Today\'s Meals',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${tracker.todayEntries.length} logged',
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Entries List or Empty State
                    if (tracker.todayEntries.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.no_meals_outlined, size: 48, color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 12),
                            Text(
                              'No meals logged today yet',
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Use AI Scanner or tap + to log your food',
                              style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    else
                      ...tracker.todayEntries.map((entry) {
                        return FoodEntryTile(
                          entry: entry,
                          onDelete: () => tracker.deleteFoodEntry(entry.id, tdee.targetCalories),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }
}

