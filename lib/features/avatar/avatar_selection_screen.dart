import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/avatar_model.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';

class AvatarSelectionScreen extends StatefulWidget {
  const AvatarSelectionScreen({super.key});

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  int _currentIndex = 0;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  late AnimationController _statsController;
  late Animation<double> _statsAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _statsAnim =
        CurvedAnimation(parent: _statsController, curve: Curves.easeOutCubic);
    _statsController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (index < 0 || index >= AvatarModel.defaults.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _statsController.forward(from: 0);
  }

  Future<void> _confirmSelection() async {
    setState(() => _isLoading = true);

    final avatar = AvatarModel.defaults[_currentIndex];
    final user = AuthService.currentUser;

    if (user != null) {
      final updatedUser = user.copyWith(
        avatarId: avatar.id,
        hasSelectedAvatar: true,
      );
      await StorageService.saveUser(updatedUser);

      final users = StorageService.getRegisteredUsers();
      final idx = users.indexWhere((u) => u.id == user.id);
      if (idx != -1) {
        users[idx] = updatedUser;
        await StorageService.saveRegisteredUsers(users);
      }
    }

    setState(() => _isLoading = false);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
  }

  @override
  Widget build(BuildContext context) {
    final avatar = AvatarModel.defaults[_currentIndex];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF0B2535), Color(0xFF0D1B2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                const SizedBox(height: 32),
                _buildHeader(),
                const SizedBox(height: 24),
                _buildCarousel(),
                const SizedBox(height: 20),
                _buildAvatarInfo(avatar),
                const SizedBox(height: 20),
                _buildStats(avatar),
                const Spacer(),
                _buildConfirmButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          'CHOOSE YOUR\nHERO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'SELECT YOUR GROWSTEP PARTNER',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: AvatarModel.defaults.length,
            itemBuilder: (context, index) =>
                _buildAvatarCard(AvatarModel.defaults[index]),
          ),
          Positioned(
            left: 8,
            child: _buildArrow(
              icon: Icons.chevron_left_rounded,
              onTap: () => _goToPage(_currentIndex - 1),
              enabled: _currentIndex > 0,
            ),
          ),
          Positioned(
            right: 8,
            child: _buildArrow(
              icon: Icons.chevron_right_rounded,
              onTap: () => _goToPage(_currentIndex + 1),
              enabled: _currentIndex < AvatarModel.defaults.length - 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCard(AvatarModel avatar) {
    print('Loading image: ${avatar.assetPath}');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD4A5A0).withOpacity(0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFD4A5A0).withOpacity(0.4),
                      const Color(0xFF0D1B2A).withOpacity(0.0),
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
              // Replace with Image.asset(avatar.assetPath) once images are added
             Image.asset(
              avatar.assetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.child_care_rounded,
                size: 120,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            
              ...List.generate(6, (i) => _sparkle(i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sparkle(int index) {
    final positions = [
      const Offset(30, 40),
      const Offset(200, 30),
      const Offset(50, 160),
      const Offset(210, 150),
      const Offset(100, 20),
      const Offset(160, 200),
    ];
    final sizes = [6.0, 8.0, 5.0, 7.0, 5.0, 6.0];
    final pos = positions[index % positions.length];
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Container(
        width: sizes[index % sizes.length],
        height: sizes[index % sizes.length],
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primary.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildArrow({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.25,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF162535),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  Widget _buildAvatarInfo(AvatarModel avatar) {
    return Column(
      children: [
        Text(
          avatar.name,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            avatar.role.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(AvatarModel avatar) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1E2D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          children: [
            _buildStatBar(
                icon: Icons.speed_rounded, label: 'SPEED', value: avatar.speed),
            const SizedBox(height: 14),
            _buildStatBar(
                icon: Icons.bolt_rounded,
                label: 'STAMINA',
                value: avatar.stamina),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBar({
    required IconData icon,
    required String label,
    required int value,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.6),
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Text('$value',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: AnimatedBuilder(
            animation: _statsAnim,
            builder: (context, child) => LinearProgressIndicator(
              value: (value / 100) * _statsAnim.value,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _confirmSelection,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.black, strokeWidth: 2.5),
                )
              : const Icon(Icons.check_rounded, size: 22),
          label: Text(_isLoading ? 'SAVING...' : 'CONFIRM SELECTION'),
        ),
      ),
    );
  }
}