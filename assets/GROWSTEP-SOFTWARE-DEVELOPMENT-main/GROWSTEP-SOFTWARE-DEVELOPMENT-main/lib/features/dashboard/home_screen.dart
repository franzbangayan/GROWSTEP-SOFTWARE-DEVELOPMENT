import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../models/quiz_question_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../lessons/lessons_screen.dart';
import '../profile/profile_screen.dart';
import '../quiz/quiz_screen.dart';
import '../shop/shop_screen.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;

  // Pedometer State
  StreamSubscription<StepCount>? _stepCountStream;
  int _stepsAtSessionStart = 0;
  int _sessionSteps = 0;

  // ─── Walking state ────────────────────────────────────────
  int _totalMeters = 0;
  int _coins = 0;
  int _completedQuizCount = 0;

  // ─── UI state ─────────────────────────────────────────────
  bool _quizPending = false;
  bool _quizInProgress = false;
  bool _showMilestoneBanner = false;
  int _lastMilestoneMeters = 0; // meters at which the last milestone occurred
  int _currentNavIndex = 0;

  // ─── Animations ───────────────────────────────────────────
  late AnimationController _bannerController;
  late Animation<double> _bannerAnim;

  late AnimationController _coinController;
  late Animation<double> _coinAnim;

  late AnimationController _quizButtonController;
  late Animation<double> _quizButtonAnim;

  // ─── Brand palette ────────────────────────────────────────
  static const Color _green      = Color(0xFF3DBE7A);
  static const Color _darkGreen  = Color(0xFF2DA869);
  static const Color _quizRed    = Color(0xFFE53935);
  static const Color _coinYellow = Color(0xFFFFC107);
  static const Color _lightBlue  = Color(0xFF64B5F6);

  // ─── Level helpers ────────────────────────────────────────
  int get _level => _completedQuizCount + 1;

  String get _levelTitle {
    if (_level <= 3)  return 'Newborn';
    if (_level <= 6)  return 'Junior';
    if (_level <= 10) return 'Explorer';
    return 'Champion';
  }

  String get _distanceLabel {
    if (_totalMeters >= 1000) {
      return '${(_totalMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${_totalMeters}m';
  }

  double get _milestoneProgress {
    if (_totalMeters == 0) return 0.0;
    final rem = _totalMeters % AppConstants.quizTriggerMeters;
    if (rem == 0 && _totalMeters > 0) return 1.0;
    return rem / AppConstants.quizTriggerMeters;
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    _initCamera();
    _initPedometer();
  

    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _bannerAnim = CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeOutBack,
    );

    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _coinAnim = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _coinController, curve: Curves.elasticOut),
    );

    _quizButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _quizButtonAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _quizButtonController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
    _bannerController.dispose();
    _coinController.dispose();
    _quizButtonController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ─── User load / sync ─────────────────────────────────────

  void _loadUser() {
    final user = AuthService.currentUser;
    if (user != null) {
      setState(() {
        _totalMeters       = user.totalMeters;
        _coins             = user.coins;
        _completedQuizCount = user.completedQuizCount;
      });
    }
  }

  Future<void> _persistUser() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final updated = user.copyWith(
      coins: _coins,
      totalMeters: _totalMeters,
      completedQuizCount: _completedQuizCount,
    );
    await StorageService.saveUser(updated);
    await _syncRegistered(updated);
  }

  Future<void> _syncRegistered(UserModel user) async {
    final all = StorageService.getRegisteredUsers();
    final idx = all.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      all[idx] = user;
      await StorageService.saveRegisteredUsers(all);
    }
  }

  // ─── Walk tap logic ───────────────────────────────────────

  Future<void> _onWalkTap() async {
    if (_quizInProgress) return;

    final prevMeters = _totalMeters;
    final newMeters  = _totalMeters + AppConstants.metersPerTap;

    // Coin earned?
    final prevCoin = prevMeters ~/ AppConstants.metersPerCoin;
    final newCoin  = newMeters  ~/ AppConstants.metersPerCoin;
    if (newCoin > prevCoin) {
      _coinController.forward(from: 0);
    }

    setState(() {
      _totalMeters = newMeters;
      _coins      += (newCoin - prevCoin);
    });

    await _persistUser();

    // Milestone crossed?
    final prevMilestone = prevMeters ~/ AppConstants.quizTriggerMeters;
    final newMilestone  = newMeters  ~/ AppConstants.quizTriggerMeters;
    if (newMilestone > prevMilestone) {
      _triggerMilestone(newMeters);
    }
  }

  void _triggerMilestone(int metersAtMilestone) {
    setState(() {
      _quizPending          = true;
      _showMilestoneBanner  = true;
      _lastMilestoneMeters  = metersAtMilestone;
    });
    _bannerController.forward(from: 0);

    // Auto-hide banner after 3 s (quiz button stays)
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _bannerController.reverse().then((_) {
        if (mounted) setState(() => _showMilestoneBanner = false);
      });
    });
  }

  // ─── Quiz launch ──────────────────────────────────────────

 Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,       // back camera
      ResolutionPreset.high,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _initPedometer() async {
    final status = await Permission.activityRecognition.request();
    if (status != PermissionStatus.granted) return;
    _stepCountStream = Pedometer.stepCountStream.listen(
    (StepCount event) {
      if (_stepsAtSessionStart == 0) {
        _stepsAtSessionStart = event.steps;
      }
      final newSessionSteps = event.steps - _stepsAtSessionStart;
      final addedSteps = newSessionSteps - _sessionSteps;
      if (addedSteps > 0) {
        _sessionSteps = newSessionSteps;
        final addedMeters = (addedSteps * 0.75).round();
        _onStepDetected(addedMeters);
      }
    },
    onError: (error) => debugPrint('Pedometer error: $error'),
  );
}

Future<void> _onStepDetected(int addedMeters) async {
  if (_quizInProgress) return;
  final prevMeters = _totalMeters;
  final newMeters = _totalMeters + addedMeters;
  final prevCoin = prevMeters ~/ AppConstants.metersPerCoin;
  final newCoin = newMeters ~/ AppConstants.metersPerCoin;
  if (newCoin > prevCoin) _coinController.forward(from: 0);
  setState(() {
    _totalMeters = newMeters;
    _coins += (newCoin - prevCoin);
  });
  await _persistUser();
  final prevMilestone = prevMeters ~/ AppConstants.quizTriggerMeters;
  final newMilestone = newMeters ~/ AppConstants.quizTriggerMeters;
  if (newMilestone > prevMilestone) _triggerMilestone(newMeters);
}
  Future<void> _launchQuiz() async {
    if (_quizInProgress || !mounted) return;
    setState(() {
      _quizInProgress = true;
      _quizPending    = false;
    });

    final questions = QuizQuestion.getRandomQuestions(count: 5);
    final passed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: questions,
          milestoneNumber: _totalMeters ~/ AppConstants.quizTriggerMeters,
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _quizInProgress = false);

    if (passed == true) {
      setState(() => _completedQuizCount++);
      await _persistUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.emoji_events_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Quiz passed! Shop items unlocked.',
                  style: TextStyle(color: Colors.white)),
            ]),
            backgroundColor: _darkGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // ─── Bottom nav ───────────────────────────────────────────

  void _onNavTap(int index) {
    if (index == 0) return; // already home
    setState(() => _currentNavIndex = index);

    final screens = [null, const LessonsScreen(), const ShopScreen(), const ProfileScreen()];
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screens[index]!),
    ).then((_) {
      if (mounted) {
        setState(() => _currentNavIndex = 0);
        _loadUser(); // refresh coins/stats on return
      }
    });
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
            if (_cameraController != null && _cameraController!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize!.height,
                  height: _cameraController!.value.previewSize!.width,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            Container(color: Colors.black), // fallback while loading
          // ── 1. Full-screen outdoor background ─────────────
        
          // ── 2. All HUD content ────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildStatusBar(),
                const SizedBox(height: 10),
                // Milestone banner (shows & hides with animation)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _showMilestoneBanner
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildMilestoneBanner(),
                        )
                      : const SizedBox.shrink(),
                ),
                // AR area — fills remaining space
                Expanded(child: _buildARArea()),
                // Walk progress panel
                _buildWalkProgressPanel(),
                // Bottom nav spacing
                SizedBox(height: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Background ───────────────────────────────────────────
  // Outdoor nature theme — replace with Image.asset / CameraPreview later

  Widget _buildBackground() {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withOpacity(0.28),
          Colors.transparent,
          Colors.black.withOpacity(0.20),
        ],
        stops: const [0.0, 0.45, 1.0],
      ),
    ),
  );
}
  // ─── Status Bar ───────────────────────────────────────────

  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          _statusPill(
            icon: Icons.trending_up_rounded,
            iconColor: _green,
            label: '$_levelTitle (Lvl $_level)',
          ),
          const Spacer(),
          ScaleTransition(
            scale: _coinAnim,
            child: _statusPill(
              icon: Icons.monetization_on_rounded,
              iconColor: _coinYellow,
              label: '$_coins',
            ),
          ),
          const SizedBox(width: 8),
          _statusPill(
            icon: Icons.bolt_rounded,
            iconColor: _lightBlue,
            label: _distanceLabel,
          ),
           const SizedBox(width: 8), 
        _statusPill(
          icon: Icons.directions_walk_rounded,
          iconColor: Colors.white,
          label: '$_sessionSteps steps',
        ), 
        ],
      ),
    );
  }

  Widget _statusPill({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.58),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Milestone Banner ─────────────────────────────────────

  Widget _buildMilestoneBanner() {
    final km = (_lastMilestoneMeters / 1000).toStringAsFixed(1);
    return ScaleTransition(
      scale: _bannerAnim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: _green.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 9),
            Text(
              'MILESTONE  $km KM',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AR Area ──────────────────────────────────────────────

  Widget _buildARArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Character — centered
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(child: _buildCharacter()),
            ),

            // QUIZ! button — lower-right of character
            if (_quizPending)
              Positioned(
                top: constraints.maxHeight * 0.52,
                left: constraints.maxWidth * 0.54,
                child: ScaleTransition(
                  scale: _quizButtonAnim,
                  child: _buildQuizButton(),
                ),
              ),

            // Trophy / achievements shortcut — bottom-left
            Positioned(
              bottom: 16,
              left: 16,
              child: _buildTrophyButton(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCharacter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AR circle frame
        Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.08),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/avatars/Oakley.png',
              fit: BoxFit.contain,
            )
          ),
        ),
        const SizedBox(height: 10),
        // Level badge below character
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$_levelTitle · Lvl $_level',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizButton() {
    return GestureDetector(
      onTap: _launchQuiz,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: _quizRed,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _quizRed.withOpacity(0.5),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'QUIZ!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildTrophyButton() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.emoji_events_rounded, color: _green, size: 30),
    );
  }

  // ─── Walk Progress Panel ──────────────────────────────────

  Widget _buildWalkProgressPanel() {
    final progressMeters = _totalMeters % AppConstants.quizTriggerMeters;
    const nextMeters = AppConstants.quizTriggerMeters;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: label + progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'WALK PROGRESS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBBBBBB),
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _milestoneProgress,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor: const AlwaysStoppedAnimation<Color>(_green),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${progressMeters}m / ${nextMeters}m to next quiz',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFBBBBBB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Right: walk button
          GestureDetector(
            onTap: _quizInProgress ? null : _onWalkTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: _quizInProgress ? _green.withOpacity(0.5) : _green,
                borderRadius: BorderRadius.circular(22),
                boxShadow: _quizInProgress
                    ? []
                    : [
                        BoxShadow(
                          color: _green.withOpacity(0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_walk_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 7),
                  Text(
                    '+${(AppConstants.metersPerTap / 1000).toStringAsFixed(1)} km',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Navigation ────────────────────────────────────

  Widget _buildBottomNav() {
    const activeColor   = _green;
    const inactiveColor = Color(0xFFAAAAAA);

    final items = [
      (Icons.home_rounded,        Icons.home_outlined,           'HOME'),
      (Icons.grid_view_rounded,   Icons.grid_view_outlined,      'LESSONS'),
      (Icons.storefront_rounded,  Icons.storefront_outlined,     'SHOP'),
      (Icons.person_rounded,      Icons.person_outline_rounded,  'PROFILE'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: kBottomNavigationBarHeight,
          child: Row(
            children: List.generate(items.length, (i) {
              final active = _currentNavIndex == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onNavTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        active ? items[i].$1 : items[i].$2,
                        color: active ? activeColor : inactiveColor,
                        size: 26,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].$3,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                          color: active ? activeColor : inactiveColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}