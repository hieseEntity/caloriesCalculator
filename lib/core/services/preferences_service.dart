import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class PreferencesService {
  static const String _keyProfile = 'user_profile_json';
  static const String _keyLastActiveDate = 'last_active_date';
  static const String _keyResetHour = 'reset_hour';
  static const String _keyOnboardingDone = 'onboarding_done';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  UserProfile getProfile() {
    final raw = _prefs.getString(_keyProfile);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return UserProfile.fromJson(map);
      } catch (_) {
        // Fallback default
      }
    }
    return const UserProfile();
  }

  Future<bool> saveProfile(UserProfile profile) async {
    final raw = jsonEncode(profile.toJson());
    return await _prefs.setString(_keyProfile, raw);
  }

  String? getLastActiveDate() {
    return _prefs.getString(_keyLastActiveDate);
  }

  Future<bool> setLastActiveDate(String dateString) async {
    return await _prefs.setString(_keyLastActiveDate, dateString);
  }

  int getResetHour() {
    return _prefs.getInt(_keyResetHour) ?? 0; // Default 00:00 (midnight)
  }

  Future<bool> setResetHour(int hour) async {
    return await _prefs.setInt(_keyResetHour, hour);
  }

  bool isOnboardingDone() {
    return _prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<bool> setOnboardingDone(bool done) async {
    return await _prefs.setBool(_keyOnboardingDone, done);
  }
}

