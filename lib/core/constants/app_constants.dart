class AppConstants {
  // ─── SharedPreferences keys (session only) ─────────────────
  static const String isLoggedInKey    = 'is_logged_in';
  static const String currentUserIdKey = 'current_user_id';

  // ─── Game Rules ────────────────────────────────────────────
  static const int metersPerCoin      = 100;    // 1 coin per 100m
  static const int dailyGoalMeters    = 10000;  // 10 km daily goal
  static const int quizTriggerMeters  = 500;    // quiz every 500m
  static const int metersPerTap       = 100;    // +0.1 km per tap

  // ─── Routes ────────────────────────────────────────────────
  static const String loginRoute            = '/login';
  static const String registerRoute         = '/register';
  static const String forgotPasswordRoute   = '/forgot-password';
  static const String avatarSelectionRoute  = '/avatar-selection';
  static const String homeRoute             = '/home';
  static const String stepTrackerRoute      = '/step-tracker';
  static const String shopRoute             = '/shop';
  static const String lessonsRoute          = '/lessons';
  static const String profileRoute          = '/profile';
  static const String dressUpRoute          = '/dress-up';
  // QuizScreen is always MaterialPageRoute (requires runtime parameters)

  // ─── Security Questions ────────────────────────────────────
  static const List<String> securityQuestions = [
    'What was the name of your first pet?',
    'What city were you born in?',
    "What is your mother's maiden name?",
    'What was the name of your elementary school?',
    'What is your favorite book?',
  ];
}
