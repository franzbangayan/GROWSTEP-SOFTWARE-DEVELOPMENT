import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';

class DatabaseService {
  static Database? _db;

  // ─── Init ──────────────────────────────────────────────────

  /// Call once in main() before runApp().
  static Future<void> init() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'growstep.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id                  TEXT PRIMARY KEY,
        name                TEXT NOT NULL,
        email               TEXT NOT NULL UNIQUE,
        password            TEXT NOT NULL,
        security_question   TEXT NOT NULL DEFAULT '',
        security_answer     TEXT NOT NULL DEFAULT '',
        coins               INTEGER NOT NULL DEFAULT 0,
        total_meters        INTEGER NOT NULL DEFAULT 0,
        streak              INTEGER NOT NULL DEFAULT 0,
        avatar_id           TEXT,
        has_selected_avatar INTEGER NOT NULL DEFAULT 0,
        purchased_item_ids  TEXT NOT NULL DEFAULT '[]',
        completed_quiz_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ─── Write ─────────────────────────────────────────────────

  /// Insert or replace a user row (upsert).
  static Future<void> upsertUser(UserModel user) async {
    await _db!.insert(
      'users',
      user.toSqlMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── Read ──────────────────────────────────────────────────

  static Future<UserModel?> getUserById(String id) async {
    final rows = await _db!.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserModel.fromSqlMap(rows.first);
  }

  static Future<UserModel?> getUserByEmail(String email) async {
    final rows = await _db!.query(
      'users',
      where: 'LOWER(email) = LOWER(?)',
      whereArgs: [email],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserModel.fromSqlMap(rows.first);
  }

  static Future<bool> emailExists(String email) async {
    final rows = await _db!.query(
      'users',
      columns: ['id'],
      where: 'LOWER(email) = LOWER(?)',
      whereArgs: [email],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}