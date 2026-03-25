import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/avatar/avatar_selection_screen.dart';
import 'features/dashboard/home_screen.dart';
import 'features/shop/shop_screen.dart';
import 'features/lessons/lessons_screen.dart';
import 'features/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Routing logic on app launch:
  /// 1. Not logged in           → Login
  /// 2. Logged in, no avatar    → Avatar Selection
  /// 3. Logged in, has avatar   → Home
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
        AppConstants.loginRoute: (_) => const LoginScreen(),
        AppConstants.registerRoute: (_) => const RegisterScreen(),
        AppConstants.avatarSelectionRoute: (_) => const AvatarSelectionScreen(),
        AppConstants.homeRoute: (_) => const HomeScreen(),
        AppConstants.shopRoute: (_) => const ShopScreen(),
        AppConstants.lessonsRoute: (_) => const LessonsScreen(),
        AppConstants.profileRoute: (_) => const ProfileScreen(),
        // QuizScreen is NOT registered here — it takes runtime parameters
        // and is always navigated to using MaterialPageRoute directly.
      },
    );
  }
}