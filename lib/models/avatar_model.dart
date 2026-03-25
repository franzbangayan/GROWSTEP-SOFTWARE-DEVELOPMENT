import 'shop_item_model.dart';

class AvatarVariant {
  final String id;
  final String assetPath;

  const AvatarVariant({
    required this.id,
    required this.assetPath,
  });
}

class AvatarModel {
  final String id;
  final String name;
  final String role;
  final String assetPath;
  final int speed;
  final int stamina;
  final List<AvatarVariant> variants;

  const AvatarModel({
    required this.id,
    required this.name,
    required this.role,
    required this.assetPath,
    required this.speed,
    required this.stamina,
    this.variants = const [],
  });

  static const List<AvatarModel> defaults = [
    AvatarModel(
      id: 'oakley',
      name: 'Oakley',
      role: 'Forest Guardian',
      assetPath: 'assets/oakley/normal_oakley.png',
      speed: 67,
      stamina: 80,
      variants: [
        const AvatarVariant(id: 'oakley_v1', assetPath: 'assets/oakley/oakley-1.png'),
        const AvatarVariant(id: 'oakley_v2', assetPath: 'assets/oakley/oakley-2.png'),
        const AvatarVariant(id: 'oakley_v3', assetPath: 'assets/oakley/oakley-3.png'),
        const AvatarVariant(id: 'oakley_v4', assetPath: 'assets/oakley/oakley-4.png'),
        const AvatarVariant(id: 'oakley_v5', assetPath: 'assets/oakley/oakley-5.png'),
        const AvatarVariant(id: 'oakley_v6', assetPath: 'assets/oakley/oakley-6.png'),
        const AvatarVariant(id: 'oakley_v7', assetPath: 'assets/oakley/oakley-7.png'),
        const AvatarVariant(id: 'oakley_v8', assetPath: 'assets/oakley/oakley-8.png'),
        const AvatarVariant(id: 'oakley_v9', assetPath: 'assets/oakley/oakley-9.png'),
        const AvatarVariant(id: 'oakley_v10', assetPath: 'assets/oakley/oakley-10.png'),
        const AvatarVariant(id: 'oakley_v11', assetPath: 'assets/oakley/oakley-11.png'),
        const AvatarVariant(id: 'oakley_v12', assetPath: 'assets/oakley/oakley-12.png'),
      ],
    ),
    AvatarModel(
      id: 'glowie',
      name: 'Glowie',
      role: 'Luminous Sprite',
      assetPath: 'assets/glowie/normal_glowie.png',
      speed: 85,
      stamina: 60,
      variants: [
        const AvatarVariant(id: 'glowie_barong', assetPath: 'assets/glowie/glowie-barong.png'),
        const AvatarVariant(id: 'glowie_brown_jacket', assetPath: 'assets/glowie/glowie-brown_jacket.png'),
        const AvatarVariant(id: 'glowie_cap', assetPath: 'assets/glowie/glowie-cap.png'),
        const AvatarVariant(id: 'glowie_crown', assetPath: 'assets/glowie/glowie-crown.png'),
        const AvatarVariant(id: 'glowie_hat', assetPath: 'assets/glowie/glowie_hat.png'),
        const AvatarVariant(id: 'glowie_jacket', assetPath: 'assets/glowie/glowie-jacket.png'),
        const AvatarVariant(id: 'glowie_mask', assetPath: 'assets/glowie/glowie-mask.png'),
        const AvatarVariant(id: 'glowie_shades', assetPath: 'assets/glowie/glowie-shades.png'),
        const AvatarVariant(id: 'glowie_shoes', assetPath: 'assets/glowie/glowie_shoes.png'),
        const AvatarVariant(id: 'glowie_snack', assetPath: 'assets/glowie/glowie_snack.png'),
        const AvatarVariant(id: 'glowie_water', assetPath: 'assets/glowie/glowie_water.png'),
      ],
    ),
    AvatarModel(
      id: 'bouncy',
      name: 'Bouncy',
      role: 'Energetic Bloom',
      assetPath: 'assets/bouncy/normal_bouncy.png',
      speed: 75,
      stamina: 75,
      variants: [
        const AvatarVariant(id: 'bouncy_barong', assetPath: 'assets/bouncy/bouncy-barong.png'),
        const AvatarVariant(id: 'bouncy_brown_jacket', assetPath: 'assets/bouncy/bouncy-brown_jacket.png'),
        const AvatarVariant(id: 'bouncy_cap', assetPath: 'assets/bouncy/bouncy-cap.png'),
        const AvatarVariant(id: 'bouncy_crown', assetPath: 'assets/bouncy/bouncy-crown.png'),
        const AvatarVariant(id: 'bouncy_hat', assetPath: 'assets/bouncy/bouncy-hat.png'),
        const AvatarVariant(id: 'bouncy_mask', assetPath: 'assets/bouncy/bouncy-mask.png'),
        const AvatarVariant(id: 'bouncy_shades', assetPath: 'assets/bouncy/bouncy-shades.png'),
        const AvatarVariant(id: 'bouncy_snack', assetPath: 'assets/bouncy/bouncy-snack.png'),
        const AvatarVariant(id: 'bouncy_water', assetPath: 'assets/bouncy/bouncy-water.png'),
      ],
    ),
    AvatarModel(
      id: 'circuit',
      name: 'Circuit',
      role: 'Techno-Soul',
      assetPath: 'assets/circuit/normal_circuit.png',
      speed: 90,
      stamina: 55,
      variants: [
        const AvatarVariant(id: 'circuit_barong', assetPath: 'assets/circuit/circuit-barong.png'),
        const AvatarVariant(id: 'circuit_brown_jacket', assetPath: 'assets/circuit/circuit-brown_jacket.png'),
        const AvatarVariant(id: 'circuit_cap', assetPath: 'assets/circuit/circuit-cap.png'),
        const AvatarVariant(id: 'circuit_crown', assetPath: 'assets/circuit/circuit-crown.png'),
        const AvatarVariant(id: 'circuit_jacket', assetPath: 'assets/circuit/circuit-jacket.png'),
        const AvatarVariant(id: 'circuit_mask', assetPath: 'assets/circuit/circuit-mask.png'),
        const AvatarVariant(id: 'circuit_shades', assetPath: 'assets/circuit/circuit-shades.png'),
        const AvatarVariant(id: 'circuit_shoes', assetPath: 'assets/circuit/circuit-shoes.png'),
        const AvatarVariant(id: 'circuit_snack', assetPath: 'assets/circuit/circuit-snack.png'),
        const AvatarVariant(id: 'circuit_tophat', assetPath: 'assets/circuit/circuit-tophat.png'),
        const AvatarVariant(id: 'circuit_water', assetPath: 'assets/circuit/circuit-water.png'),
      ],
    ),
  ];

  static String getAssetPath({
    String? avatarId,
    String? avatarVariantId,
    String? equippedItemId,
  }) {
    // 1. Check if user has a selected variant from Dress Up
    if (avatarVariantId != null) {
      for (var avatar in defaults) {
        for (var variant in avatar.variants) {
          if (variant.id == avatarVariantId) {
            return variant.assetPath;
          }
        }
      }
    }

    // 2. Check for shop-equipped items (legacy/other system)
    if (equippedItemId != null) {
      final equippedItem = ShopItemModel.all
          .where((i) => i.id == equippedItemId)
          .firstOrNull;
      
      if (equippedItem?.avatarAsset != null) {
        // IMPORTANT: Only return the shop asset if it's compatible with our avatar
        // This stops a 'bouncy' item from overriding our 'glowie' base avatar.
        if (avatarId == null || 
            equippedItemId.startsWith(avatarId) || 
            equippedItemId == 'normal_$avatarId') {
          return equippedItem!.avatarAsset!;
        }
      }
    }

    // 3. User base avatar
    if (avatarId != null) {
      final baseAvatar = defaults.where((a) => a.id == avatarId).firstOrNull;
      if (baseAvatar != null) {
        return baseAvatar.assetPath;
      }
    }

    return defaults.first.assetPath; // Default: normal_oakley.png
  }
}