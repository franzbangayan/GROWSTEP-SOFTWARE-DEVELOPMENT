import 'dart:convert';
import '../core/constants/app_constants.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final String securityQuestion;
  final String securityAnswer;
  int coins;
  int totalMeters;
  int streak;
  String? avatarId;
  bool hasSelectedAvatar;
  List<String> purchasedItemIds;
  int completedQuizCount;
  String? equippedItemId; // ← NEW

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.securityQuestion = '',
    this.securityAnswer = '',
    this.coins = 0,
    this.totalMeters = 0,
    this.streak = 0,
    this.avatarId,
    this.hasSelectedAvatar = false,
    List<String>? purchasedItemIds,
    this.completedQuizCount = 0,
    this.equippedItemId, // ← NEW
  }) : purchasedItemIds = purchasedItemIds ?? [];

  // ─── Computed ──────────────────────────────────────────────

  int get milestonesReached => totalMeters ~/ AppConstants.quizTriggerMeters;

  bool hasItem(String itemId) => purchasedItemIds.contains(itemId);

  // ─── JSON (SharedPreferences / in-memory) ──────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'securityQuestion': securityQuestion,
        'securityAnswer': securityAnswer,
        'coins': coins,
        'totalMeters': totalMeters,
        'streak': streak,
        'avatarId': avatarId,
        'hasSelectedAvatar': hasSelectedAvatar,
        'purchasedItemIds': purchasedItemIds,
        'completedQuizCount': completedQuizCount,
        'equippedItemId': equippedItemId, // ← NEW
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        password: map['password'] ?? '',
        securityQuestion: map['securityQuestion'] ?? '',
        securityAnswer: map['securityAnswer'] ?? '',
        coins: map['coins'] ?? 0,
        totalMeters: map['totalMeters'] ?? 0,
        streak: map['streak'] ?? 0,
        avatarId: map['avatarId'],
        hasSelectedAvatar: map['hasSelectedAvatar'] ?? false,
        purchasedItemIds: List<String>.from(map['purchasedItemIds'] ?? []),
        completedQuizCount: map['completedQuizCount'] ?? 0,
        equippedItemId: map['equippedItemId'], // ← NEW
      );

  String toJson() => jsonEncode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(jsonDecode(source));

  // ─── SQLite (flat row — bools as int, list as JSON string) ─

  Map<String, dynamic> toSqlMap() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'security_question': securityQuestion,
        'security_answer': securityAnswer,
        'coins': coins,
        'total_meters': totalMeters,
        'streak': streak,
        'avatar_id': avatarId,
        'has_selected_avatar': hasSelectedAvatar ? 1 : 0,
        'purchased_item_ids': jsonEncode(purchasedItemIds),
        'completed_quiz_count': completedQuizCount,
        'equipped_item_id': equippedItemId, // ← NEW
      };

  factory UserModel.fromSqlMap(Map<String, dynamic> row) => UserModel(
        id: row['id'] as String,
        name: row['name'] as String,
        email: row['email'] as String,
        password: row['password'] as String,
        securityQuestion: row['security_question'] as String? ?? '',
        securityAnswer: row['security_answer'] as String? ?? '',
        coins: row['coins'] as int? ?? 0,
        totalMeters: row['total_meters'] as int? ?? 0,
        streak: row['streak'] as int? ?? 0,
        avatarId: row['avatar_id'] as String?,
        hasSelectedAvatar: (row['has_selected_avatar'] as int? ?? 0) == 1,
        purchasedItemIds: List<String>.from(
          jsonDecode(row['purchased_item_ids'] as String? ?? '[]'),
        ),
        completedQuizCount: row['completed_quiz_count'] as int? ?? 0,
        equippedItemId: row['equipped_item_id'] as String?, // ← NEW
      );
static const String _unequip = '__unequip__';

UserModel copyWithUnequip() => copyWith()..equippedItemId = null;
  // ─── copyWith ──────────────────────────────────────────────

  UserModel copyWith({
    String? name,
    String? email,
    String? password,
    String? securityQuestion,
    String? securityAnswer,
    int? coins,
    int? totalMeters,
    int? streak,
    String? avatarId,
    bool? hasSelectedAvatar,
    List<String>? purchasedItemIds,
    int? completedQuizCount,
    String? equippedItemId, // ← NEW
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        password: password ?? this.password,
        securityQuestion: securityQuestion ?? this.securityQuestion,
        securityAnswer: securityAnswer ?? this.securityAnswer,
        coins: coins ?? this.coins,
        totalMeters: totalMeters ?? this.totalMeters,
        streak: streak ?? this.streak,
        avatarId: avatarId ?? this.avatarId,
        hasSelectedAvatar: hasSelectedAvatar ?? this.hasSelectedAvatar,
        purchasedItemIds: purchasedItemIds ?? List.from(this.purchasedItemIds),
        completedQuizCount: completedQuizCount ?? this.completedQuizCount,
        equippedItemId: equippedItemId ?? this.equippedItemId, // ← NEW
      );
}