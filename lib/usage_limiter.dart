import 'package:shared_preferences/shared_preferences.dart';

class UsageLimiter {
  static const String _countKey = 'usage_count';
  static const String _dateKey = 'usage_date';
  static const int dailyLimit = 100;

  static Future<bool> canUse() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';

    String? savedDate = prefs.getString(_dateKey);
    int count = prefs.getInt(_countKey) ?? 0;

    if (savedDate != today) {
      await prefs.setString(_dateKey, today);
      await prefs.setInt(_countKey, 0);
      return true;
    }

    return count < dailyLimit;
  }

  static Future<void> incrementUsage() async {
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt(_countKey) ?? 0;
    await prefs.setInt(_countKey, count + 1);
  }
}
