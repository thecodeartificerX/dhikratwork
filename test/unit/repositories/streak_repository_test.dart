// test/unit/repositories/streak_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:dhikratwork/repositories/streak_repository.dart';
import 'package:dhikratwork/utils/constants.dart';
import '../../fakes/fake_database_service.dart';

void main() {
  late FakeDatabaseService fakeDb;
  late StreakRepository repo;

  final String today = DateTime.now().toIso8601String().substring(0, 10);
  final String yesterday = DateTime.now()
      .subtract(const Duration(days: 1))
      .toIso8601String()
      .substring(0, 10);
  final String twoDaysAgo = DateTime.now()
      .subtract(const Duration(days: 2))
      .toIso8601String()
      .substring(0, 10);

  setUp(() {
    fakeDb = FakeDatabaseService();
    repo = StreakRepository(fakeDb);
  });

  tearDown(() => fakeDb.reset());

  // -------------------------------------------------------------------------
  // getStreak — initial state
  // -------------------------------------------------------------------------

  group('getStreak — no row exists', () {
    test('creates and returns a default zero streak', () async {
      final streak = await repo.getStreak();
      expect(streak.id, kSingleRowId);
      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
      expect(streak.lastActiveDate, isNull);
    });

    test('inserts the default row into the database', () async {
      await repo.getStreak();
      final rows = fakeDb.tableRows(tStreak);
      expect(rows.length, 1);
    });
  });

  group('getStreak — row already exists', () {
    test('reads existing row without creating a duplicate', () async {
      await repo.getStreak(); // Creates the row
      await repo.getStreak(); // Should reuse it
      final rows = fakeDb.tableRows(tStreak);
      expect(rows.length, 1);
    });
  });

  // -------------------------------------------------------------------------
  // updateStreak — called with today's date
  // -------------------------------------------------------------------------

  group('updateStreak — first activity (no prior date)', () {
    test('sets current_streak to 1 when last_active_date is null', () async {
      await repo.getStreak();
      await repo.updateStreak(today);
      final streak = await repo.getStreak();
      expect(streak.currentStreak, 1);
      expect(streak.lastActiveDate, today);
    });

    test('sets longest_streak to 1 on first activity', () async {
      await repo.getStreak();
      await repo.updateStreak(today);
      final streak = await repo.getStreak();
      expect(streak.longestStreak, 1);
    });
  });

  group('updateStreak — already active today', () {
    test('is a no-op when last_active_date == today', () async {
      fakeDb.seedTable(tStreak, [
        {
          'id': kSingleRowId,
          cStreakCurrentStreak: 5,
          cStreakLongestStreak: 10,
          cStreakLastActiveDate: today,
        }
      ]);
      await repo.updateStreak(today);
      final streak = await repo.getStreak();
      expect(streak.currentStreak, 5);
      expect(streak.longestStreak, 10);
    });
  });

  group('updateStreak — consecutive day', () {
    test('increments current_streak when last_active_date == yesterday',
        () async {
      fakeDb.seedTable(tStreak, [
        {
          'id': kSingleRowId,
          cStreakCurrentStreak: 4,
          cStreakLongestStreak: 10,
          cStreakLastActiveDate: yesterday,
        }
      ]);
      await repo.updateStreak(today);
      final streak = await repo.getStreak();
      expect(streak.currentStreak, 5);
      expect(streak.lastActiveDate, today);
    });

    test('updates longest_streak when current exceeds it', () async {
      fakeDb.seedTable(tStreak, [
        {
          'id': kSingleRowId,
          cStreakCurrentStreak: 10,
          cStreakLongestStreak: 10,
          cStreakLastActiveDate: yesterday,
        }
      ]);
      await repo.updateStreak(today);
      final streak = await repo.getStreak();
      expect(streak.currentStreak, 11);
      expect(streak.longestStreak, 11);
    });

    test('does not decrease longest_streak', () async {
      fakeDb.seedTable(tStreak, [
        {
          'id': kSingleRowId,
          cStreakCurrentStreak: 3,
          cStreakLongestStreak: 20,
          cStreakLastActiveDate: yesterday,
        }
      ]);
      await repo.updateStreak(today);
      final streak = await repo.getStreak();
      expect(streak.currentStreak, 4);
      expect(streak.longestStreak, 20); // unchanged
    });
  });

  group('updateStreak — broken streak', () {
    test('resets current_streak to 1 when gap > 1 day', () async {
      fakeDb.seedTable(tStreak, [
        {
          'id': kSingleRowId,
          cStreakCurrentStreak: 7,
          cStreakLongestStreak: 15,
          cStreakLastActiveDate: twoDaysAgo,
        }
      ]);
      await repo.updateStreak(today);
      final streak = await repo.getStreak();
      expect(streak.currentStreak, 1);
      expect(streak.longestStreak, 15); // preserved
      expect(streak.lastActiveDate, today);
    });
  });

  // -------------------------------------------------------------------------
  // resetStreak
  // -------------------------------------------------------------------------

  group('resetStreak', () {
    test('sets current_streak to 0 and clears last_active_date', () async {
      fakeDb.seedTable(tStreak, [
        {
          'id': kSingleRowId,
          cStreakCurrentStreak: 7,
          cStreakLongestStreak: 15,
          cStreakLastActiveDate: today,
        }
      ]);
      await repo.resetStreak();
      final streak = await repo.getStreak();
      expect(streak.currentStreak, 0);
      expect(streak.lastActiveDate, isNull);
    });

    test('preserves longest_streak after reset', () async {
      fakeDb.seedTable(tStreak, [
        {
          'id': kSingleRowId,
          cStreakCurrentStreak: 7,
          cStreakLongestStreak: 15,
          cStreakLastActiveDate: today,
        }
      ]);
      await repo.resetStreak();
      final streak = await repo.getStreak();
      expect(streak.longestStreak, 15);
    });
  });
}
