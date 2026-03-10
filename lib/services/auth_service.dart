import '../models/user_model.dart';
import 'database_service.dart';
import 'storage_service.dart';

enum AuthResult { success, emailAlreadyExists, invalidCredentials, error }

class AuthService {
  // In-memory cache — loaded once at startup via restoreSession()
  static UserModel? _currentUser;

  // ─── Session restore ───────────────────────────────────────

  /// Call in main() after DatabaseService.init() + StorageService.init().
  /// Loads the previously logged-in user from SQLite into the cache.
  static Future<void> restoreSession() async {
    if (!StorageService.isLoggedIn()) return;
    final id = StorageService.getCurrentUserId();
    if (id == null) return;
    _currentUser = await DatabaseService.getUserById(id);
  }

  // ─── Auth operations ───────────────────────────────────────

  /// Register a new user — writes to SQLite, sets session.
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    try {
      if (await DatabaseService.emailExists(email)) {
        return AuthResult.emailAlreadyExists;
      }

      final newUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        password: password,
        securityQuestion: securityQuestion,
        securityAnswer: securityAnswer.toLowerCase().trim(),
      );

      await DatabaseService.upsertUser(newUser);
      await StorageService.setCurrentUserId(newUser.id);
      await StorageService.setLoggedIn(true);
      _currentUser = newUser;

      return AuthResult.success;
    } catch (_) {
      return AuthResult.error;
    }
  }

  /// Login — looks up user in SQLite, sets session.
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await DatabaseService.getUserByEmail(email);

      if (user == null || user.password != password) {
        return AuthResult.invalidCredentials;
      }

      await StorageService.setCurrentUserId(user.id);
      await StorageService.setLoggedIn(true);
      _currentUser = user;

      return AuthResult.success;
    } catch (_) {
      return AuthResult.error;
    }
  }

  /// Returns the security question for an email, or null if not found.
  static Future<String?> getSecurityQuestion(String email) async {
    final user = await DatabaseService.getUserByEmail(email);
    if (user == null || user.securityQuestion.isEmpty) return null;
    return user.securityQuestion;
  }

  /// Reset password after verifying security answer.
  static Future<AuthResult> resetPassword({
    required String email,
    required String securityAnswer,
    required String newPassword,
  }) async {
    try {
      final user = await DatabaseService.getUserByEmail(email);
      if (user == null) return AuthResult.invalidCredentials;

      if (user.securityAnswer != securityAnswer.toLowerCase().trim()) {
        return AuthResult.invalidCredentials;
      }

      final updated = user.copyWith(password: newPassword);
      await DatabaseService.upsertUser(updated);

      // Update cache if this is the currently logged-in user
      if (_currentUser?.id == user.id) _currentUser = updated;

      return AuthResult.success;
    } catch (_) {
      return AuthResult.error;
    }
  }

  /// Upsert user to SQLite and update the in-memory cache.
  /// Use this everywhere you need to save user changes.
  static Future<void> saveUser(UserModel user) async {
    await DatabaseService.upsertUser(user);
    if (_currentUser?.id == user.id) _currentUser = user;
  }

  /// Clear session and in-memory cache.
  static Future<void> logout() async {
    _currentUser = null;
    await StorageService.clearSession();
  }

  // ─── Synchronous getters (read from cache) ─────────────────

  static UserModel? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;
}
