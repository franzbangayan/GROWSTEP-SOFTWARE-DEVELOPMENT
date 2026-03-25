import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

class StorageService {
  static SharedPreferences? _prefs;

  /// Call once in main.dart before runApp
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Auth State ────────────────────────────────────────────

  static Future<void> setLoggedIn(bool value) async {
    await _prefs?.setBool(AppConstants.isLoggedInKey, value);
  }

  static bool isLoggedIn() {
    return _prefs?.getBool(AppConstants.isLoggedInKey) ?? false;
  }

  // ─── Current User ──────────────────────────────────────────

  static Future<void> saveUser(UserModel user) async {
    await _prefs?.setString(AppConstants.userKey, user.toJson());
  }

  static UserModel? getUser() {
    final json = _prefs?.getString(AppConstants.userKey);
    if (json == null) return null;
    return UserModel.fromJson(json);
  }

  static Future<void> clearUser() async {
    await _prefs?.remove(AppConstants.userKey);
    await _prefs?.remove(AppConstants.isLoggedInKey);
  }

  // ─── All Registered Users (local auth) ────────────────────

  static Future<void> saveRegisteredUsers(List<UserModel> users) async {
    final list = users.map((u) => u.toJson()).toList();
    await _prefs?.setStringList(AppConstants.registeredUsersKey, list);
  }

  static List<UserModel> getRegisteredUsers() {
    final list =
        _prefs?.getStringList(AppConstants.registeredUsersKey) ?? [];
    return list.map((json) => UserModel.fromJson(json)).toList();
  }
}