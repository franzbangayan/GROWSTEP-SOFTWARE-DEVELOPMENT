class AppConstants {
  // Storage Keys
  static const String userKey = 'current_user';
  static const String isLoggedInKey = 'is_logged_in';
  static const String registeredUsersKey = 'registered_users';

  // Game Rules
  static const int metersPerCoin = 100;     // earn 1 coin every 100m walked
  static const int dailyGoalMeters = 10000; // 10km daily goal
  static const int quizTriggerMeters = 500; // quiz pops every 500m milestone
  static const int metersPerTap = 100;      // +0.1 km per tap (simulation)

  // Routes
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String avatarSelectionRoute = '/avatar-selection';
  static const String homeRoute = '/home';
  static const String stepTrackerRoute = '/step-tracker';
  static const String shopRoute = '/shop';
  static const String lessonsRoute = '/lessons';
  static const String profileRoute = '/profile';
  // QuizScreen is always pushed via MaterialPageRoute (requires parameters)
}