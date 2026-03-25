import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../models/avatar_model.dart';
import '../../models/shop_item_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  UserModel? _user;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // ─── Light palette  ──────────────────
  static const Color _bg       = Color(0xFFF7F7F7);
  static const Color _cardBg   = Colors.white;
  static const Color _dark     = Color(0xFF1A1A2E);
  static const Color _green    = Color(0xFF3DBE7A);
  static const Color _yellow   = Color(0xFFFFC107);
  static const Color _grey     = Color(0xFF9E9E9E);
  static const Color _blue     = Color(0xFF4A90D9);
  static const Color _orange   = Color(0xFFFF8C42);

  @override
  void initState() {
    super.initState();
    _user = AuthService.currentUser;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
        parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  AvatarModel? get _selectedAvatar {
    if (_user?.avatarId == null) return null;
    try {
      return AvatarModel.defaults.firstWhere((a) => a.id == _user!.avatarId);
    } catch (_) {
      return null;
    }
  }

  List<ShopItemModel> get _ownedItems {
    if (_user == null) return [];
    final avatarId = _user?.avatarId ?? 'oakley';
    return ShopItemModel.all
        .where((item) => _user!.hasItem(item.id) && 
            (item.id.startsWith(avatarId) || item.id == 'normal_$avatarId'))
        .toList();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        backgroundColor: _cardBg,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Colors.redAccent, size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'Log Out?',
                style: TextStyle(
                  color: _dark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your progress is saved. You can log back in anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _grey, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _grey,
                        side: const BorderSide(color: Color(0xFFEEEEEE)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Log Out',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      await AuthService.logout();
      Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserCard(),
                      const SizedBox(height: 16),
                      _buildStatsGrid(),
                      const SizedBox(height: 16),
                      _buildProgressSection(),
                      const SizedBox(height: 16),
                      _buildOwnedItemsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 16, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: _dark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Profile',
              style: TextStyle(
                color: _dark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // Logout button
          GestureDetector(
            onTap: _handleLogout,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.redAccent, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─── User card ────────────────────────────────────────────

  Widget _buildUserCard() {
    final avatar = _selectedAvatar;
    final avatarAsset = AvatarModel.getAssetPath(
      avatarId: _user?.avatarId,
      avatarVariantId: _user?.avatarVariantId,
      equippedItemId: _user?.equippedItemId,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _green.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _green.withOpacity(0.05),
              border: Border.all(
                  color: _green.withOpacity(0.35), width: 2.5),
            ),
              child: ClipOval(
                child: Image.asset(
                  avatarAsset,
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain, 
                ),
            ),

          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user?.name ?? 'Player',
                  style: const TextStyle(
                    color: _dark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _user?.email ?? '',
                  style: const TextStyle(
                    color: _grey,
                    fontSize: 13,
                  ),
                ),
                if (avatar != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${avatar.name} · ${avatar.role}',
                          style: const TextStyle(
                            color: _green,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppConstants.dressUpRoute).then((_) {
                          setState(() {
                            _user = AuthService.currentUser;
                          });
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.checkroom_rounded, color: _blue, size: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats grid ───────────────────────────────────────────

  Widget _buildStatsGrid() {
  final meters = _user?.totalMeters ?? 0;
  final distanceLabel = meters >= 1000
      ? '${(meters / 1000).toStringAsFixed(2)} km'
      : '${meters}m';

  final stats = [
    _Stat('Distance',    distanceLabel,                       Icons.directions_walk_rounded, _green),
    _Stat('Coins',       '${_user?.coins ?? 0}',              Icons.monetization_on_rounded, _yellow),
    _Stat('Quizzes',     '${_user?.completedQuizCount ?? 0}', Icons.quiz_rounded,            _blue),
    _Stat('Items Owned', '${_ownedItems.length}',             Icons.shopping_bag_rounded,    _orange),
  ];

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          children: [
            _buildStatCard(stats[0]),
            const SizedBox(height: 12),
            _buildStatCard(stats[2]),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          children: [
            _buildStatCard(stats[1]),
            const SizedBox(height: 12),
            _buildStatCard(stats[3]),
          ],
        ),
      ),
    ],
  );
}

 Widget _buildStatCard(_Stat stat) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // ← key fix
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: stat.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(stat.icon, color: stat.color, size: 16),
        ),
        const SizedBox(height: 8),
        Text(
          stat.value,
          style: TextStyle(
            color: stat.color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          stat.label,
          style: const TextStyle(
            color: _grey,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
  // ─── Progress section ─────────────────────────────────────

  Widget _buildProgressSection() {
    final meters = _user?.totalMeters ?? 0;
    const goal = AppConstants.dailyGoalMeters;
    final walkProgress = (meters / goal).clamp(0.0, 1.0);
    final quizzes = _user?.completedQuizCount ?? 0;
    final quizProgress = (quizzes / 10).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress',
            style: TextStyle(
              color: _dark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          _buildProgressRow(
            label: 'Daily Goal',
            sublabel: '${meters}m / ${goal}m',
            progress: walkProgress,
            color: _green,
          ),
          const SizedBox(height: 16),
          _buildProgressRow(
            label: 'Quiz Milestones',
            sublabel: '$quizzes / 10 passed',
            progress: quizProgress,
            color: _blue,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow({
    required String label,
    required String sublabel,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: _dark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            Text(sublabel,
                style: const TextStyle(color: _grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Owned items ──────────────────────────────────────────

  Widget _buildOwnedItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Owned Items',
              style: TextStyle(
                color: _dark,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${_ownedItems.length} / ${ShopItemModel.all.length}',
              style: const TextStyle(color: _grey, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ownedItems.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_bag_outlined,
                          color: _grey, size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No items yet',
                      style: TextStyle(
                          color: _dark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Earn coins by walking and spend\nthem in the Shop!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _grey, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.9,
                ),
                itemCount: _ownedItems.length,
                itemBuilder: (_, i) => _buildOwnedItemCard(_ownedItems[i]),
              ),
      ],
    );
  }

  Widget _buildOwnedItemCard(ShopItemModel item) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [item.imageColor, item.imageTint],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              item.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _dark,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
}