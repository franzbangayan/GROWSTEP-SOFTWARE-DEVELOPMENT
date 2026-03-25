import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../models/quiz_question_model.dart';
import '../../services/auth_service.dart';
import '../lessons/lessons_screen.dart';
import '../profile/profile_screen.dart';
import '../quiz/quiz_screen.dart';
import '../shop/shop_screen.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'package:flutter_compass/flutter_compass.dart';
import '../../models/shop_item_model.dart';
import '../../models/avatar_model.dart';


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

  // ─── AR Coins ─────────────────────────────────────────────
  final List<ARCoin> _arCoins = [];
  Timer? _coinCheckTimer;
  int _coinIdCounter = 0;
  Position? _currentPosition;
  double _compassHeading = 0.0;
  StreamSubscription<CompassEvent>? _compassStream;

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
    _initLocationAndCoins();
    _initCompass(); 
  

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
    _coinCheckTimer?.cancel();
    _compassStream?.cancel();
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
    await AuthService.saveUser(updated);
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
  Future<void> _initLocationAndCoins() async {
  final status = await Permission.location.request();
  if (status != PermissionStatus.granted) return;

  _currentPosition = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
  }
void _initCompass() {
  _compassStream = FlutterCompass.events!.listen((CompassEvent event) {
    if (event.heading != null && mounted) {
      setState(() => _compassHeading = event.heading!);
    }
  });

  _spawnCoinsNearby();

  _coinCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
    _currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _checkCoinProximity();
  });

}
void _spawnCoinsNearby() {
  if (_currentPosition == null) return;
  final rand = Random();
  for (int i = 0; i < 5; i++) {
    final latOffset = (rand.nextDouble() - 0.5) * 0.0001;
    final lonOffset = (rand.nextDouble() - 0.5) * 0.0001;
    _arCoins.add(ARCoin(
      id: _coinIdCounter++,
      latitude: _currentPosition!.latitude + latOffset,
      longitude: _currentPosition!.longitude + lonOffset,
    ));
  }
  setState(() {});
}

void _checkCoinProximity() {
  if (_currentPosition == null) return;
  bool changed = false;

  for (final coin in _arCoins) {
    if (coin.collected) continue;

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      coin.latitude,
      coin.longitude,
    );

    if (distance < 15 && !coin.isVisible) {
      coin.isVisible = true;
      changed = true;
    }

    if (distance < 5 && !coin.collected) {
      coin.collected = true;
      coin.isVisible = false;
      _coins += 5;
      _coinController.forward(from: 0);
      _persistUser();
      changed = true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Text('🪙', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('+5 coins collected!',
                  style: TextStyle(color: Colors.white)),
            ]),
            backgroundColor: const Color(0xFFFFC107),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }

    if (distance >= 15 && coin.isVisible) {
      coin.isVisible = false;
      changed = true;
    }
  }

  if (_arCoins.every((c) => c.collected)) {
    _arCoins.clear();
    _spawnCoinsNearby();
    return;
  }

  if (changed) setState(() {});
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
  if (index == 0) return;
  setState(() => _currentNavIndex = index);

  // ← Persist latest user state before opening any screen
  _persistUser().then((_) {
    final screens = [
      null,
      const LessonsScreen(),
      const ShopScreen(),
      const ProfileScreen(),
    ];
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screens[index]!),
    ).then((_) {
      if (mounted) {
        setState(() => _currentNavIndex = 0);
        _loadUser();
      }
    });
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
  // ─── Status Bar ───────────────────────────────────────────

 Widget _buildStatusBar() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Row(
      children: [
        _statusPill(
          icon: Icons.trending_up_rounded,
          iconColor: _green,
          label: 'Lvl $_level',
        ),
        const SizedBox(width: 6),
        _statusPill(
          icon: Icons.directions_walk_rounded,
          iconColor: Colors.white,
          label: '$_sessionSteps steps',
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
        const SizedBox(width: 6),
        _statusPill(
          icon: Icons.bolt_rounded,
          iconColor: _lightBlue,
          label: _distanceLabel,
        ),
        const SizedBox(width: 8),
        // TEST BUTTON
        GestureDetector(
          onTap: () async {
            setState(() => _coins += 200);
            await _persistUser();
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            child: const Icon(Icons.add, color: Colors.white, size: 14),
          ),
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // ← was 10, 7
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.58),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 13), // ← was 15
        const SizedBox(width: 4), // ← was 5
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11, // ← was 13
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
            // AR Coins — only show visible ones
// AR Coins — compass-based, ground level
// AR Coins — GPS proximity, random screen position
..._arCoins.where((c) => c.isVisible && !c.collected).map((coin) {
  if (_currentPosition == null) return const SizedBox.shrink();

  final distance = Geolocator.distanceBetween(
    _currentPosition!.latitude,
    _currentPosition!.longitude,
    coin.latitude,
    coin.longitude,
  );

  // Use coin ID to give each coin a stable random position
  final rand = Random(coin.id);
  final screenX = constraints.maxWidth * (0.15 + rand.nextDouble() * 0.7);
  final screenY = constraints.maxHeight * (0.15 + rand.nextDouble() * 0.5);
  final coinSize = 64.0;

  return Positioned(
    left: screenX - coinSize / 2,
    top: screenY - coinSize / 2,
    child: TweenAnimationBuilder<double>(
      key: ValueKey(coin.id),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: coinSize,
            height: coinSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _coinYellow,
              boxShadow: [
                BoxShadow(
                  color: _coinYellow.withOpacity(0.7),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '🪙',
                style: TextStyle(fontSize: coinSize * 0.5),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${distance.toStringAsFixed(0)}m away',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}).toList(),
          ],
        );
      },
    );
  }

  Widget _buildCharacter() {
    final user = AuthService.currentUser;
    final avatarAsset = AvatarModel.getAssetPath(
      avatarId: user?.avatarId,
      avatarVariantId: user?.avatarVariantId,
      equippedItemId: user?.equippedItemId,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppConstants.dressUpRoute).then((_) => setState(() => _loadUser())),
          child: Container(
            width: 100,
            height: 100,
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
                avatarAsset,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      const SizedBox(height: 10),
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
class ARCoin {
  final int id;
  final double latitude;
  final double longitude;
  bool isVisible;
  bool collected;

  ARCoin({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.isVisible = false,
    this.collected = false,
  });
}