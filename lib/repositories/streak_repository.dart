// lib/repositories/streak_repository.dart

import 'package:dhikratwork/models/streak.dart';
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/utils/constants.dart';

/// SSOT for [Streak] domain data.
///
/// The [streak] table is a single-row table (id = 1). The repository handles
/// the consecutive-day increment logic so ViewModels only need to call
/// [updateStreak(today)] on every count increment.
class StreakRepository {
  final DatabaseService _db;

  StreakRepository(this._db);

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Returns the current [Streak]. Creates the default row on first call.
  Future<Streak> getStreak() async {
    final rows = await _db.query(
      tStreak,
      where: '$cStreakId = ?',
      whereArgs: [kSingleRowId],
      limit: 1,
    );
    if (rows.isNotEmpty) return Streak.fromMap(rows.first);

    // First launch: create default row
    final defaults = _defaultStreakMap();
    await _db.insert(tStreak, defaults);
    return Streak.fromMap(defaults);
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Update the streak for [todayDate] (format: `'YYYY-MM-DD'`).
  ///
  /// Business rules:
  /// - [lastActiveDate] == [todayDate] → no-op (already counted today)
  /// - [lastActiveDate] == yesterday → increment [currentStreak]
  /// - any other case → reset [currentStreak] to 1
  ///
  /// After increment/reset, update [longestStreak] if [currentStreak] exceeds it.
  Future<void> updateStreak(String todayDate) async {
    final streak = await getStreak();
    final last = streak.lastActiveDate;

    // No-op if already updated today
    if (last == todayDate) return;

    final int newCurrent;
    if (last != null && _isYesterday(last, todayDate)) {
      newCurrent = streak.currentStreak + 1;
    } else {
      newCurrent = 1;
    }

    final int newLongest =
        newCurrent > streak.longestStreak ? newCurrent : streak.longestStreak;

    await _db.update(
      tStreak,
      {
        cStreakCurrentStreak: newCurrent,
        cStreakLongestStreak: newLongest,
        cStreakLastActiveDate: todayDate,
      },
      where: '$cStreakId = ?',
      whereArgs: [kSingleRowId],
    );
  }

  /// Reset [currentStreak] to 0 and clear [lastActiveDate].
  /// [longestStreak] is preserved.
  Future<void> resetStreak() async {
    await _db.update(
      tStreak,
      {
        cStreakCurrentStreak: 0,
        cStreakLastActiveDate: null,
      },
      where: '$cStreakId = ?',
      whereArgs: [kSingleRowId],
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _defaultStreakMap() {
    return <String, dynamic>{
      cStreakId: kSingleRowId,
      cStreakCurrentStreak: 0,
      cStreakLongestStreak: 0,
      cStreakLastActiveDate: null,
    };
  }

  /// Returns true if [lastDate] is exactly one day before [todayDate].
  bool _isYesterday(String lastDate, String todayDate) {
    try {
      final last = DateTime.parse(lastDate);
      final today = DateTime.parse(todayDate);
      final diff = today.difference(last).inDays;
      return diff == 1;
    } catch (_) {
      return false;
    }
  }
}
