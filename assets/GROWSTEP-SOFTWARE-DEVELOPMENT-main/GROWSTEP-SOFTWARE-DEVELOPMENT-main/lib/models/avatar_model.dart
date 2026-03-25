class AvatarModel {
  final String id;
  final String name;
  final String role;
  final String assetPath;
  final int speed;
  final int stamina;

  const AvatarModel({
    required this.id,
    required this.name,
    required this.role,
    required this.assetPath,
    required this.speed,
    required this.stamina,
  });

  static const List<AvatarModel> defaults = [
    AvatarModel(
      id: 'avatar_1',
      name: 'Oakley',
      role: 'Forest Guardian',
      assetPath: 'assets/avatars/Oakley.png',
      speed: 67,
      stamina: 67,
    ),
    // add more avatars here as you create them
  ];
}