import 'package:intl/intl.dart';
import 'preferences_service.dart';

class RolloverResult {
  final bool didRollover;
  final String previousDate;
  final String currentDate;

  const RolloverResult({
    required this.didRollover,
    required this.previousDate,
    required this.currentDate,
  });
}

class RolloverService {
  final PreferencesService _prefs;
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  RolloverService(this._prefs);

  /// Returns today's active date string based on reset hour (e.g. 00:00)
  String getTodayDateString() {
    final now = DateTime.now();
    final resetHour = _prefs.getResetHour();

    // If current hour is before reset hour, the tracking belongs to yesterday's cycle
    final effectiveDate = now.hour < resetHour
        ? now.subtract(const Duration(days: 1))
        : now;

    return _dateFormat.format(effectiveDate);
  }

  /// Checks if day has changed since last active session.
  /// If so, updates last active date and returns [RolloverResult].
  Future<RolloverResult> checkAndTriggerRollover() async {
    final today = getTodayDateString();
    final lastActive = _prefs.getLastActiveDate();

    if (lastActive == null) {
      await _prefs.setLastActiveDate(today);
      return RolloverResult(
        didRollover: false,
        previousDate: today,
        currentDate: today,
      );
    }

    if (lastActive != today) {
      // Day has changed! Trigger rollover
      await _prefs.setLastActiveDate(today);
      return RolloverResult(
        didRollover: true,
        previousDate: lastActive,
        currentDate: today,
      );
    }

    return RolloverResult(
      didRollover: false,
      previousDate: lastActive,
      currentDate: today,
    );
  }
}

