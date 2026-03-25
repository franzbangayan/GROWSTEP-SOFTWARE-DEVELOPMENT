import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/storage_service.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/avatar/avatar_selection_screen.dart';
import 'features/dashboard/home_screen.dart';
import 'features/shop/shop_screen.dart';
import 'features/lessons/lessons_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/avatar/dress_up_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Boot order matters:
  // 1. Open SQLite database
  // 2. Load SharedPreferences (session flags)
  // 3. Restore cached user from DB using the stored ID
  await DatabaseService.init();
  await StorageService.init();
  
  // TODO: REMOVE THIS LINE AFTER STARTING THE APP ONCE TO RESET
  await DatabaseService.deleteAllUsers();
  await StorageService.clearSession();

  await AuthService.restoreSession();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Routing logic — synchronous because restoreSession() already
  /// populated AuthService._currentUser before runApp() was called.
  String get _initialRoute {
    if (!AuthService.isLoggedIn) return AppConstants.loginRoute;
    final user = AuthService.currentUser;
    if (user == null || !user.hasSelectedAvatar) {
      return AppConstants.avatarSelectionRoute;
    }
    return AppConstants.homeRoute;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrowStep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: _initialRoute,
      routes: {
        AppConstants.loginRoute:           (_) => const LoginScreen(),
        AppConstants.registerRoute:        (_) => const RegisterScreen(),
        AppConstants.forgotPasswordRoute:  (_) => const ForgotPasswordScreen(),
        AppConstants.avatarSelectionRoute: (_) => const AvatarSelectionScreen(),
        AppConstants.homeRoute:            (_) => const HomeScreen(),
        AppConstants.shopRoute:            (_) => const ShopScreen(),
        AppConstants.lessonsRoute:         (_) => const LessonsScreen(),
        AppConstants.profileRoute:         (_) => const ProfileScreen(),
        AppConstants.dressUpRoute:          (_) => const DressUpScreen(),
      },
    );
  }
}
