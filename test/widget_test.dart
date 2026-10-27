import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calories_calculator/core/database/database_helper.dart';
import 'package:calories_calculator/core/services/preferences_service.dart';
import 'package:calories_calculator/core/services/rollover_service.dart';
import 'package:calories_calculator/features/profile/profile_controller.dart';
import 'package:calories_calculator/features/tracker/tracker_controller.dart';
import 'package:calories_calculator/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App smoke test: renders dashboard with TDEE targets and navigation', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    late DatabaseHelper db;
    late ProfileController profileController;
    late TrackerController trackerController;

    await tester.runAsync(() async {
      final prefs = await PreferencesService.create();
      db = await DatabaseHelper.createInMemory();
      final rollover = RolloverService(prefs);

      profileController = ProfileController(prefs);
      trackerController = TrackerController(
        databaseHelper: db,
        rolloverService: rollover,
      );

      await trackerController.init(profileController.tdeeResult.targetCalories);
    });

    await tester.pumpWidget(CaloriesCalculatorApp(
      profileController: profileController,
      trackerController: trackerController,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Calories Calculator header
    expect(find.text('Calories Calculator'), findsOneWidget);

    // Verify Navigation Bar items
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('AI Scanner'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('TDEE Profile'), findsOneWidget);

    // Verify Macro labels
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('Fat'), findsOneWidget);

    // Verify AI Scanner CTA card
    expect(find.text('Scan Food Packaging / Label'), findsOneWidget);

    await tester.runAsync(() async {
      await db.close();
    });
  });
}
