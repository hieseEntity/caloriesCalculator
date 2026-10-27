import 'package:flutter/material.dart';
import 'core/database/database_helper.dart';
import 'core/services/preferences_service.dart';
import 'core/services/rollover_service.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/profile_controller.dart';
import 'features/tracker/tracker_controller.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Core Services
  final prefsService = await PreferencesService.create();
  final databaseHelper = DatabaseHelper.instance;
  final rolloverService = RolloverService(prefsService);

  // Initialize Controllers
  final profileController = ProfileController(prefsService);
  final trackerController = TrackerController(
    databaseHelper: databaseHelper,
    rolloverService: rolloverService,
  );

  // Load today's entries and rollover state
  await trackerController.init(profileController.tdeeResult.targetCalories);

  runApp(CaloriesCalculatorApp(
    profileController: profileController,
    trackerController: trackerController,
  ));
}

class CaloriesCalculatorApp extends StatelessWidget {
  final ProfileController profileController;
  final TrackerController trackerController;

  const CaloriesCalculatorApp({
    super.key,
    required this.profileController,
    required this.trackerController,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calories Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: HomeScreen(
        profileController: profileController,
        trackerController: trackerController,
      ),
    );
  }
}
