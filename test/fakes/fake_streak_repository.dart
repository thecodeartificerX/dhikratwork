// test/fakes/fake_streak_repository.dart

import 'package:dhikratwork/models/streak.dart';
import 'package:dhikratwork/repositories/streak_repository.dart';
import 'package:dhikratwork/utils/constants.dart';

/// In-memory fake of [StreakRepository] for use in ViewModel unit tests.
class FakeStreakRepository implements StreakRepository {
  Streak _streak = const Streak(
    id: kSingleRowId,
    currentStreak: 0,
    longestStreak: 0,
    lastActiveDate: null,
  );

  /// Override the initial streak for tests that need specific state.
  void seed(Streak streak) => _streak = streak;

  @override
  Future<Streak> getStreak() async => _streak;

  @override
  Future<void> updateStreak(String todayDate) async {
    final last = _streak.lastActiveDate;
    if (last == todayDate) return;

    final int newCurrent;
    if (last != null && _isYesterday(last, todayDate)) {
      newCurrent = _streak.currentStreak + 1;
    } else {
      newCurrent = 1;
    }

    final int newLongest =
        newCurrent > _streak.longestStreak ? newCurrent : _streak.longestStreak;

    _streak = Streak(
      id: _streak.id,
      currentStreak: newCurrent,
      longestStreak: newLongest,
      lastActiveDate: todayDate,
    );
  }

  @override
  Future<void> resetStreak() async {
    // Construct directly to support null-clearing of lastActiveDate,
    // since copyWith cannot null out nullable fields.
    _streak = Streak(
      id: _streak.id,
      currentStreak: 0,
      longestStreak: _streak.longestStreak,
      lastActiveDate: null,
    );
  }

  bool _isYesterday(String lastDate, String todayDate) {
    try {
      final last = DateTime.parse(lastDate);
      final today = DateTime.parse(todayDate);
      return today.difference(last).inDays == 1;
    } catch (_) {
      return false;
    }
  }
}
