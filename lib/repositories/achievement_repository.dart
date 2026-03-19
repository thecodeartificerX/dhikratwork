// lib/repositories/achievement_repository.dart
import 'package:dhikratwork/models/achievement.dart';
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/utils/constants.dart';

/// Repository for [Achievement] data. Acts as the Single Source of Truth for
/// all gamification achievements. Achievements are seeded at DB creation time
/// and never created at runtime — only [unlocked_at] is mutable.
class AchievementRepository {
  AchievementRepository(this._db);

  final DatabaseService _db;

  // -------------------------------------------------------------------------
  // getAll
  // -------------------------------------------------------------------------

  /// Returns all [Achievement] rows (both locked and unlocked).
  Future<List<Achievement>> getAll() async {
    final rows = await _db.query(tAchievement, orderBy: '$cAchievementId ASC');
    return List.unmodifiable(rows.map(Achievement.fromMap).toList());
  }

  // -------------------------------------------------------------------------
  // getUnlocked
  // -------------------------------------------------------------------------

  /// Returns all [Achievement] rows where [unlocked_at] IS NOT NULL.
  Future<List<Achievement>> getUnlocked() async {
    final rows = await _db.rawQuery(
      'SELECT * FROM $tAchievement '
      'WHERE $cAchievementUnlockedAt IS NOT NULL '
      'ORDER BY $cAchievementUnlockedAt ASC',
      [],
    );
    return List.unmodifiable(rows.map(Achievement.fromMap).toList());
  }

  // -------------------------------------------------------------------------
  // getLocked
  // -------------------------------------------------------------------------

  /// Returns all [Achievement] rows where [unlocked_at] IS NULL.
  Future<List<Achievement>> getLocked() async {
    final rows = await _db.rawQuery(
      'SELECT * FROM $tAchievement '
      'WHERE $cAchievementUnlockedAt IS NULL '
      'ORDER BY $cAchievementId ASC',
      [],
    );
    return List.unmodifiable(rows.map(Achievement.fromMap).toList());
  }

  // -------------------------------------------------------------------------
  // unlock
  // -------------------------------------------------------------------------

  /// Sets [unlocked_at] to the current UTC datetime for the achievement
  /// identified by [key]. If the achievement is already unlocked, this is a
  /// no-op (the original timestamp is preserved). Safe to call multiple times.
  Future<void> unlock(String key) async {
    // Only update if unlocked_at is still NULL to preserve the original timestamp.
    await _db.execute(
      'UPDATE $tAchievement '
      "SET $cAchievementUnlockedAt = datetime('now') "
      "WHERE $cAchievementKey = ? AND $cAchievementUnlockedAt IS NULL",
      [key],
    );
  }

  // -------------------------------------------------------------------------
  // isUnlocked
  // -------------------------------------------------------------------------

  /// Returns `true` if the achievement with [key] has a non-null [unlocked_at].
  /// Returns `false` for missing keys.
  Future<bool> isUnlocked(String key) async {
    final rows = await _db.rawQuery(
      'SELECT $cAchievementUnlockedAt FROM $tAchievement '
      'WHERE $cAchievementKey = ?',
      [key],
    );
    if (rows.isEmpty) return false;
    return rows.first[cAchievementUnlockedAt] != null;
  }
}
