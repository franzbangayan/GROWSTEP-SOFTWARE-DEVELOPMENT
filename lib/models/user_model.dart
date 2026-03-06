import 'dart:convert';
import '../core/constants/app_constants.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;
  int coins;
  int totalMeters;             // total distance walked in meters
  int streak;                  // daily login/walk streak
  String? avatarId;            // selected avatar id
  bool hasSelectedAvatar;      // whether first-time selection is complete
  List<String> purchasedItemIds; // ids of items bought from the shop
  int completedQuizCount;      // number of quizzes actually PASSED (controls shop unlocks)

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.coins = 0,
    this.totalMeters = 0,
    this.streak = 0,
    this.avatarId,
    this.hasSelectedAvatar = false,
    List<String>? purchasedItemIds,
    this.completedQuizCount = 0,
  }) : purchasedItemIds = purchasedItemIds ?? [];

  /// How many quiz milestones have been REACHED (based on distance walked).
  /// Display-only — controls when a quiz is SHOWN, not when items unlock.
  int get milestonesReached => totalMeters ~/ AppConstants.quizTriggerMeters;

  /// Whether a specific item has been purchased
  bool hasItem(String itemId) => purchasedItemIds.contains(itemId);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'coins': coins,
        'totalMeters': totalMeters,
        'streak': streak,
        'avatarId': avatarId,
        'hasSelectedAvatar': hasSelectedAvatar,
        'purchasedItemIds': purchasedItemIds,
        'completedQuizCount': completedQuizCount,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'],
        name: map['name'],
        email: map['email'],
        password: map['password'],
        coins: map['coins'] ?? 0,
        totalMeters: map['totalMeters'] ?? 0,
        streak: map['streak'] ?? 0,
        avatarId: map['avatarId'],
        hasSelectedAvatar: map['hasSelectedAvatar'] ?? false,
        purchasedItemIds: List<String>.from(map['purchasedItemIds'] ?? []),
        completedQuizCount: map['completedQuizCount'] ?? 0,
      );

  String toJson() => jsonEncode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(jsonDecode(source));

  UserModel copyWith({
    String? name,
    String? email,
    int? coins,
    int? totalMeters,
    int? streak,
    String? avatarId,
    bool? hasSelectedAvatar,
    List<String>? purchasedItemIds,
    int? completedQuizCount,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        password: password,
        coins: coins ?? this.coins,
        totalMeters: totalMeters ?? this.totalMeters,
        streak: streak ?? this.streak,
        avatarId: avatarId ?? this.avatarId,
        hasSelectedAvatar: hasSelectedAvatar ?? this.hasSelectedAvatar,
        purchasedItemIds:
            purchasedItemIds ?? List.from(this.purchasedItemIds),
        completedQuizCount: completedQuizCount ?? this.completedQuizCount,
      );
}