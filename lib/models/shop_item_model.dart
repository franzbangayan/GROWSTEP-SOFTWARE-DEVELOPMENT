import 'package:flutter/material.dart';

enum ShopCategory { clothes, accessories, necessities }

class ShopItemModel {
  final String id;
  final String name;
  final ShopCategory category;
  final int coinCost;
  final IconData icon;
  final Color imageColor;      // dominant color for the card image area
  final Color imageTint;       // secondary tint for gradient
  final int requiredMilestones;

  const ShopItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.coinCost,
    required this.icon,
    required this.imageColor,
    required this.imageTint,
    this.requiredMilestones = 0,
  });

  bool get isQuizLocked => requiredMilestones > 0;

  /// Primary display color — alias for imageColor (used by profile_screen)
  Color get color => imageColor;

  static const List<ShopItemModel> all = [

    // ─── Clothes ──────────────────────────────────────────
    ShopItemModel(
      id: 'item_dino_hoodie',
      name: 'DINO HOODIE',
      category: ShopCategory.clothes,
      coinCost: 120,
      icon: Icons.checkroom_rounded,
      imageColor: Color(0xFF2E4057),
      imageTint: Color(0xFF1A6B5A),
    ),
    ShopItemModel(
      id: 'item_cloud_shoes',
      name: 'CLOUD SHOES',
      category: ShopCategory.clothes,
      coinCost: 200,
      icon: Icons.directions_run_rounded,
      imageColor: Color(0xFF1C1C2E),
      imageTint: Color(0xFF3A3A5C),
    ),
    ShopItemModel(
      id: 'item_star_cap',
      name: 'STAR CAP',
      category: ShopCategory.clothes,
      coinCost: 158,
      icon: Icons.sports_baseball_rounded,
      imageColor: Color(0xFFD4A017),
      imageTint: Color(0xFFE8C547),
    ),
    ShopItemModel(
      id: 'item_cyber_jacket',
      name: 'CYBER JACKET',
      category: ShopCategory.clothes,
      coinCost: 400,
      icon: Icons.dry_cleaning_rounded,
      imageColor: Color(0xFF3A3A3A),
      imageTint: Color(0xFF5A5A5A),
      requiredMilestones: 3,
    ),
    ShopItemModel(
      id: 'item_golden_outfit',
      name: 'GOLDEN OUTFIT',
      category: ShopCategory.clothes,
      coinCost: 600,
      icon: Icons.auto_awesome_rounded,
      imageColor: Color(0xFFB8860B),
      imageTint: Color(0xFFFFD700),
      requiredMilestones: 5,
    ),

    // ─── Accessories ──────────────────────────────────────
    ShopItemModel(
      id: 'item_hero_mask',
      name: 'HERO MASK',
      category: ShopCategory.accessories,
      coinCost: 200,
      icon: Icons.masks_rounded,
      imageColor: Color(0xFFC4894A),
      imageTint: Color(0xFFE8B06A),
    ),
    ShopItemModel(
      id: 'item_panda_pack',
      name: 'PANDA PACK',
      category: ShopCategory.accessories,
      coinCost: 180,
      icon: Icons.backpack_rounded,
      imageColor: Color(0xFF2D2D2D),
      imageTint: Color(0xFF4A4A4A),
    ),
    ShopItemModel(
      id: 'item_cool_glasses',
      name: 'COOL GLASSES',
      category: ShopCategory.accessories,
      coinCost: 90,
      icon: Icons.remove_red_eye_rounded,
      imageColor: Color(0xFF1A6B5A),
      imageTint: Color(0xFF2E9E7A),
    ),
    ShopItemModel(
      id: 'item_champion_crown',
      name: 'CHAMPION CROWN',
      category: ShopCategory.accessories,
      coinCost: 500,
      icon: Icons.emoji_events_rounded,
      imageColor: Color(0xFFB8860B),
      imageTint: Color(0xFFFFD700),
      requiredMilestones: 5,
    ),

    // ─── Necessities ──────────────────────────────────────
    ShopItemModel(
      id: 'item_water_bottle',
      name: 'WATER BOTTLE',
      category: ShopCategory.necessities,
      coinCost: 50,
      icon: Icons.water_drop_rounded,
      imageColor: Color(0xFF0077B6),
      imageTint: Color(0xFF48CAE4),
    ),
    ShopItemModel(
      id: 'item_energy_bar',
      name: 'ENERGY BAR',
      category: ShopCategory.necessities,
      coinCost: 30,
      icon: Icons.lunch_dining_rounded,
      imageColor: Color(0xFFE67E22),
      imageTint: Color(0xFFF4A261),
    ),
    ShopItemModel(
      id: 'item_flutter_badge',
      name: 'FLUTTER BADGE',
      category: ShopCategory.necessities,
      coinCost: 300,
      icon: Icons.military_tech_rounded,
      imageColor: Color(0xFF00796B),
      imageTint: Color(0xFF26A69A),
      requiredMilestones: 2,
    ),
  ];

  static List<ShopItemModel> byCategory(ShopCategory category) =>
      all.where((item) => item.category == category).toList();
}