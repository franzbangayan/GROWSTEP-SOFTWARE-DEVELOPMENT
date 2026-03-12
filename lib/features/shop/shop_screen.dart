import 'package:flutter/material.dart';
import '../../models/shop_item_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  UserModel? _user;
  ShopCategory _activeCategory = ShopCategory.clothes;

  static const Color _bg         = Color(0xFFF7F7F7);
  static const Color _cardBg     = Colors.white;
  static const Color _dark       = Color(0xFF1A1A2E);
  static const Color _green      = Color(0xFF3DBE7A);
  static const Color _coinYellow = Color(0xFFFFC107);
  static const Color _textGrey   = Color(0xFF9E9E9E);
  static const Color _ownedBlue  = Color(0xFF4A90D9);

@override
void initState() {
  super.initState();
  _refreshUser();
}

void _refreshUser() {
  setState(() {
    _user = AuthService.currentUser;
  });
}

  // ─── Purchase logic ───────────────────────────────────────

  Future<void> _purchaseItem(ShopItemModel item) async {
    if (_user == null) return;
    if (_user!.hasItem(item.id)) return;
    if (_user!.coins < item.coinCost) {
      _snack('Not enough coins! Need ${item.coinCost}.', isError: true);
      return;
    }
    if (item.isQuizLocked && _user!.completedQuizCount < item.requiredMilestones) {
      _snack('Pass ${item.requiredMilestones} quizzes to unlock this.', isError: true);
      return;
    }

    final confirmed = await _showConfirmDialog(item);
    if (!confirmed || !mounted) return;

    final updatedIds = List<String>.from(_user!.purchasedItemIds)..add(item.id);

    // Auto-equip on purchase if item has an avatar asset
    final newEquipped = item.avatarAsset != null ? item.id : _user!.equippedItemId;

    final updated = _user!.copyWith(
      coins: _user!.coins - item.coinCost,
      purchasedItemIds: updatedIds,
      equippedItemId: newEquipped,
    );

    await AuthService.saveUser(updated);
    setState(() => _user = updated);
    _snack(
      item.avatarAsset != null
          ? '${item.name} purchased & equipped!'
          : '${item.name} added!',
      isError: false,
    );
  }

  // ─── Equip logic ──────────────────────────────────────────

  Future<void> _equipItem(ShopItemModel item) async {
    if (_user == null || item.avatarAsset == null) return;

    final alreadyEquipped = _user!.equippedItemId == item.id;

    // Use ..equippedItemId = null to unequip (nullable workaround)
    final updated = alreadyEquipped
        ? (_user!.copyWith()..equippedItemId = null)
        : _user!.copyWith(equippedItemId: item.id);

    await AuthService.saveUser(updated);
    setState(() => _user = updated);
    _snack(
      alreadyEquipped ? '${item.name} unequipped.' : '${item.name} equipped!',
      isError: false,
    );
  }

  Future<bool> _showConfirmDialog(ShopItemModel item) async {
    return await showDialog<bool>(
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
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [item.imageColor, item.imageTint],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: item.avatarAsset != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(item.avatarAsset!,
                                fit: BoxFit.contain),
                          )
                        : Icon(item.icon, color: Colors.white, size: 46),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _dark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monetization_on_rounded,
                          color: _coinYellow, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${item.coinCost}',
                        style: const TextStyle(
                          color: _coinYellow,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Balance after: ${(_user?.coins ?? 0) - item.coinCost} coins',
                    style: const TextStyle(color: _textGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textGrey,
                            side: const BorderSide(color: Color(0xFFEEEEEE)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Buy',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  void _snack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: isError ? const Color(0xFFE53935) : _green,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildAvatarPreview(),
            const SizedBox(height: 14),
            _buildCategoryTabs(),
            const SizedBox(height: 16),
            Expanded(child: _buildItemGrid()),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.checkroom_rounded,
                color: Color(0xFF555555), size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Avatar Apparel',
                  style: TextStyle(
                      color: _dark, fontSize: 18, fontWeight: FontWeight.w800)),
              Text('DRESS FOR SUCCESS',
                  style: TextStyle(
                      color: _textGrey, fontSize: 10,
                      fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Color(0xFF555555), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Avatar preview ───────────────────────────────────────

  Widget _buildAvatarPreview() {
    final ownedCount = ShopItemModel.all
        .where((i) => _user?.hasItem(i.id) ?? false)
        .length;

    // Find equipped item and its avatar asset
    final equippedItem = _user?.equippedItemId != null
        ? ShopItemModel.all
            .where((i) => i.id == _user!.equippedItemId)
            .firstOrNull
        : null;
    final avatarAsset =
        equippedItem?.avatarAsset ?? 'assets/avatars/Oakley.png';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Avatar circle — updates live when equipped
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 126, height: 126,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFFE0E0E0), width: 2),
                ),
              ),
              Container(
                width: 118, height: 118,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFFFFCDD2), Color(0xFFF48FB1)],
                    center: Alignment.topCenter,
                    radius: 1.0,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    avatarAsset, // ← swaps based on equipped item
                    width: 88, height: 88,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Shows what's currently equipped
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
            decoration: BoxDecoration(
              color: _dark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              equippedItem != null
                  ? 'WEARING: ${equippedItem.name}'
                  : 'DEFAULT LOOK',
              style: const TextStyle(
                color: Colors.white, fontSize: 11,
                fontWeight: FontWeight.w800, letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                    color: _green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                '$ownedCount OWNED',
                style: const TextStyle(
                  color: _green, fontSize: 11,
                  fontWeight: FontWeight.w700, letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Category tabs ────────────────────────────────────────

 Widget _buildCategoryTabs() {
  final tabs = [
    (ShopCategory.clothes,     'CLOTHES'),
    (ShopCategory.accessories, 'ACCESSORIES'),
    (ShopCategory.necessities, 'NEEDS'),
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        // Tabs — scrollable so they never overflow
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tabs.map((t) {
                final active = _activeCategory == t.$1;
                return GestureDetector(
                  onTap: () => setState(() => _activeCategory = t.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? _dark : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      t.$2,
                      style: TextStyle(
                        color: active ? Colors.white : _textGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Coin balance — pinned to the right
        Row(
          children: [
            const Text('🪙', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 4),
            Text(
              '${_user?.coins ?? 0}',
              style: const TextStyle(
                  color: _dark, fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    ),
  );
}

  // ─── Item grid ────────────────────────────────────────────

  Widget _buildItemGrid() {
    final items = ShopItemModel.byCategory(_activeCategory);
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _buildItemCard(items[i]),
    );
  }

  Widget _buildItemCard(ShopItemModel item) {
    final owned     = _user?.hasItem(item.id) ?? false;
    final equipped  = _user?.equippedItemId == item.id;
    final locked    = item.isQuizLocked &&
        (_user?.completedQuizCount ?? 0) < item.requiredMilestones;
    final canAfford = (_user?.coins ?? 0) >= item.coinCost;

    return GestureDetector(
      onTap: locked
          ? () => _snack(
                'Pass ${item.requiredMilestones} quizzes to unlock.',
                isError: true,
              )
          : owned
              ? (item.avatarAsset != null ? () => _equipItem(item) : null)
              : () => _purchaseItem(item),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          // Highlight card if currently equipped
          border: equipped
              ? Border.all(color: _ownedBlue, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area ──────────────────────────────
            Expanded(
              flex: 10,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: locked
                              ? [const Color(0xFFCCCCCC), const Color(0xFFAAAAAA)]
                              : [item.imageColor, item.imageTint],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: locked
                          ? const Center(
                              child: Icon(Icons.lock_rounded,
                                  color: Colors.white54, size: 36))
                          : item.avatarAsset != null
                              // ← Show actual avatar PNG in card if available
                              ? Image.asset(item.avatarAsset!,
                                  fit: BoxFit.contain)
                              : Center(
                                  child: Icon(item.icon,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 56)),
                    ),
                  ),
                  // Equipped badge
                  if (equipped)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        width: 26, height: 26,
                        decoration: const BoxDecoration(
                            color: _ownedBlue, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16),
                      ),
                    )
                  else if (owned)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        width: 26, height: 26,
                        decoration: const BoxDecoration(
                            color: _green, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  // Lock badge
                  if (locked)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${item.requiredMilestones} quiz',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Info area ────────────────────────────────
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: locked ? _textGrey : _dark,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (owned)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            equipped ? 'EQUIPPED' : 'OWNED',
                            style: TextStyle(
                              color: equipped ? _ownedBlue : _green,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (item.avatarAsset != null)
                            GestureDetector(
                              onTap: () => _equipItem(item),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: equipped
                                      ? _ownedBlue
                                      : const Color(0xFFEEEEEE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  equipped ? 'ON ✓' : 'EQUIP',
                                  style: TextStyle(
                                    color: equipped
                                        ? Colors.white
                                        : _textGrey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 3),
                          Text(
                            '${item.coinCost}',
                            style: TextStyle(
                              color: locked ? _textGrey : _dark,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          if (!locked)
                            GestureDetector(
                              onTap: () => _purchaseItem(item),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: canAfford
                                      ? _green
                                      : const Color(0xFFEEEEEE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'BUY',
                                  style: TextStyle(
                                    color: canAfford
                                        ? Colors.white
                                        : _textGrey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}