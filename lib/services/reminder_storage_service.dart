import 'package:shared_preferences/shared_preferences.dart';

class ReminderStorageService {
  static Future<void> saveLockedUntil(
    String storeId,
    DateTime until,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'lock_$storeId',
      until.toIso8601String(),
    );
  }

  static Future<DateTime?> loadLockedUntil(
    String storeId,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getString('lock_$storeId');

    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static Future<void> clearLockedUntil(
    String storeId,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('lock_$storeId');
  }
}