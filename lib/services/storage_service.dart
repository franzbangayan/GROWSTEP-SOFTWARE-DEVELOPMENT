import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// Session-only storage — just two keys.
/// All user data lives in SQLite (DatabaseService).
class StorageService {
  static SharedPreferences? _prefs;

  /// Call once in main() before runApp().
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Logged-in flag ────────────────────────────────────────

  static Future<void> setLoggedIn(bool value) async {
    await _prefs?.setBool(AppConstants.isLoggedInKey, value);
  }

  static bool isLoggedIn() =>
      _prefs?.getBool(AppConstants.isLoggedInKey) ?? false;

  // ─── Current user ID ───────────────────────────────────────

  static Future<void> setCurrentUserId(String id) async {
    await _prefs?.setString(AppConstants.currentUserIdKey, id);
  }

  static String? getCurrentUserId() =>
      _prefs?.getString(AppConstants.currentUserIdKey);

  // ─── Clear session (logout) ────────────────────────────────

  static Future<void> clearSession() async {
    await _prefs?.remove(AppConstants.isLoggedInKey);
    await _prefs?.remove(AppConstants.currentUserIdKey);
  }
}
