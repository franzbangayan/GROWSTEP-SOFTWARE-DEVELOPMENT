import '../models/user_model.dart';
import 'storage_service.dart';

enum AuthResult { success, emailAlreadyExists, invalidCredentials, error }

class AuthService {
  /// Register a new user locally
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final users = StorageService.getRegisteredUsers();

      final exists = users.any(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
      if (exists) return AuthResult.emailAlreadyExists;

      final newUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        password: password,
      );

      users.add(newUser);
      await StorageService.saveRegisteredUsers(users);
      await StorageService.saveUser(newUser);
      await StorageService.setLoggedIn(true);

      return AuthResult.success;
    } catch (_) {
      return AuthResult.error;
    }
  }

  /// Login with email and password
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final users = StorageService.getRegisteredUsers();

      final user = users.firstWhere(
        (u) =>
            u.email.toLowerCase() == email.toLowerCase() &&
            u.password == password,
        orElse: () =>
            UserModel(id: '', name: '', email: '', password: ''),
      );

      if (user.id.isEmpty) return AuthResult.invalidCredentials;

      await StorageService.saveUser(user);
      await StorageService.setLoggedIn(true);

      return AuthResult.success;
    } catch (_) {
      return AuthResult.error;
    }
  }

  /// Logout current user
  static Future<void> logout() async {
    await StorageService.clearUser();
  }

  /// Get current logged-in user
  static UserModel? get currentUser => StorageService.getUser();

  /// Check if user is logged in
  static bool get isLoggedIn => StorageService.isLoggedIn();
}