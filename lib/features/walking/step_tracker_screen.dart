import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/quiz_question_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../quiz/quiz_screen.dart';

class StepTrackerScreen extends StatefulWidget {
  const StepTrackerScreen({super.key});

  @override
  State<StepTrackerScreen> createState() => _StepTrackerScreenState();
}

class _StepTrackerScreenState extends State<StepTrackerScreen>
    with TickerProviderStateMixin {
  int _totalMeters = 0;
  int _coins = 0;
  int _sessionMeters = 0;

  /// How many quiz milestones the user has REACHED so far (based on distance).
  int _quizMilestoneCount = 0;

  /// Prevents a second quiz from triggering while one is already open.
  bool _quizInProgress = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  late AnimationController _coinPopController;
  late Animation<double> _coinPopAnim;

  @override
  void initState() {
    super.initState();

    // Load saved user data
    final user = AuthService.currentUser;
    if (user != null) {
      _totalMeters = user.totalMeters;
      _coins = user.coins;
      _quizMilestoneCount = _totalMeters ~/ AppConstants.quizTriggerMeters;
    }

    // Pulsing walk button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Coin badge pop animation — stays at 1.0 until earned
    _coinPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _coinPopAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _coinPopController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _coinPopController.dispose();
    super.dispose();
  }

  Future<void> _onWalkTap() async {
    if (_quizInProgress) return; // don't count steps while quiz is open

    setState(() {
      _totalMeters += AppConstants.metersPerTap;
      _sessionMeters += AppConstants.metersPerTap;

      // Every metersPerCoin (100m) = 1 coin
      if (_sessionMeters % AppConstants.metersPerCoin == 0) {
        _coins += 1;
        _coinPopController.forward(from: 0);
      }
    });

    // Persist updated distance and coins
    final user = AuthService.currentUser;
    if (user != null) {
      final updated = user.copyWith(
        coins: _coins,
        totalMeters: _totalMeters,
      );
      await StorageService.saveUser(updated);
      await _syncToRegisteredUsers(updated);
    }

    // Check if a new quiz milestone was reached
    final newMilestoneCount = _totalMeters ~/ AppConstants.quizTriggerMeters;
    if (newMilestoneCount > _quizMilestoneCount) {
      _quizMilestoneCount = newMilestoneCount;
      await _launchQuiz(_quizMilestoneCount);
    }
  }

  /// Navigate to the QuizScreen and handle the pass/fail result.
  Future<void> _launchQuiz(int milestoneNumber) async {
    if (_quizInProgress || !mounted) return;
    setState(() => _quizInProgress = true);

    final questions = QuizQuestion.getRandomQuestions(count: 5);

    final passed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: questions,
          milestoneNumber: milestoneNumber,
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _quizInProgress = false);

    if (passed == true) {
      // Increment completedQuizCount — this is what unlocks shop items
      final user = AuthService.currentUser;
      if (user != null) {
        final updated =
            user.copyWith(completedQuizCount: user.completedQuizCount + 1);
        await StorageService.saveUser(updated);
        await _syncToRegisteredUsers(updated);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.emoji_events_rounded,
                    color: Colors.black, size: 18),
                SizedBox(width: 8),
                Text('Quiz passed! New shop items may be unlocked.',
                    style: TextStyle(color: Colors.black)),
              ],
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _syncToRegisteredUsers(UserModel updatedUser) async {
    final users = StorageService.getRegisteredUsers();
    final index = users.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      users[index] = updatedUser;
      await StorageService.saveRegisteredUsers(users);
    }
  }

  @override
  Widget build(BuildContext context) {
    final milestoneProgress =
        (_totalMeters % AppConstants.quizTriggerMeters) /
            AppConstants.quizTriggerMeters;
    final nextMilestone =
        (_quizMilestoneCount + 1) * AppConstants.quizTriggerMeters;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Step Tracker',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ScaleTransition(
              scale: _coinPopAnim,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: AppTheme.accent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: AppTheme.accent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$_coins',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildDistanceCard(),
            const SizedBox(height: 24),
            _buildMilestoneProgress(milestoneProgress, nextMilestone),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const Spacer(),
            _buildWalkButton(),
            const SizedBox(height: 16),
            Text(
              'Tap to simulate +${(AppConstants.metersPerTap / 1000).toStringAsFixed(1)} km per step',
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceCard() {
    final displayValue = _totalMeters >= 1000
        ? (_totalMeters / 1000).toStringAsFixed(2)
        : '$_totalMeters';
    final displayUnit = _totalMeters >= 1000 ? 'km' : 'm';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.15),
            AppTheme.primaryDark.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          const Text(
            'Distance Walked',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  displayUnit,
                  style: const TextStyle(
                    fontSize: 20,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Earn 1 coin every ${AppConstants.metersPerCoin}m',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneProgress(double progress, int nextMilestone) {
    final current = _totalMeters % AppConstants.quizTriggerMeters;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Next Quiz Milestone',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.quiz_rounded,
                      color: AppTheme.primaryDark, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${current}m / ${AppConstants.quizTriggerMeters}m',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppTheme.surfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryDark),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Reach ${nextMilestone}m to unlock a Flutter quiz',
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final user = AuthService.currentUser;
    final completedQuizzes = user?.completedQuizCount ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            icon: Icons.directions_walk_rounded,
            label: 'This Session',
            value: '${_sessionMeters}m',
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatChip(
            icon: Icons.emoji_events_rounded,
            label: 'Quizzes Passed',
            value: '$completedQuizzes',
            color: const Color(0xFFFF8C42),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalkButton() {
    return ScaleTransition(
      scale: _pulseAnim,
      child: GestureDetector(
        onTap: _onWalkTap,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.45),
                blurRadius: 32,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_walk_rounded,
                  color: Colors.black, size: 52),
              const SizedBox(height: 6),
              Text(
                '+${(AppConstants.metersPerTap / 1000).toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}