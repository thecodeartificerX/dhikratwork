// test/unit/repositories/achievement_repository_test.dart
import 'package:dhikratwork/models/achievement.dart';
import 'package:dhikratwork/repositories/achievement_repository.dart';
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AchievementRepository', () {
    late DatabaseService dbService;
    late AchievementRepository repo;

    setUp(() async {
      // Fresh in-memory DB for each test — seed data is populated by onCreate.
      dbService = DatabaseService(dbPath: inMemoryDatabasePath);
      await dbService.open();
      repo = AchievementRepository(dbService);
    });

    tearDown(() async {
      await dbService.close();
    });

    // -----------------------------------------------------------------------
    // getAll
    // -----------------------------------------------------------------------

    group('getAll', () {
      test('returns all seeded achievements', () async {
        final result = await repo.getAll();
        // Phase 1 seeds all achievement constants — expect at least the known ones.
        expect(result.length, greaterThan(0));
      });

      test('returns both locked and unlocked achievements', () async {
        // Unlock one, then verify getAll still returns all.
        await repo.unlock(kAchFirstDhikr);

        final result = await repo.getAll();
        expect(result.any((a) => a.unlockedAt != null), isTrue);
        expect(result.any((a) => a.unlockedAt == null), isTrue);
      });

      test('returns unmodifiable list', () async {
        final result = await repo.getAll();
        expect(
          () => (result as List<dynamic>).add(
            const Achievement(
              key: 'test',
              name: 'test',
              description: 'test',
              iconAsset: 'test',
            ),
          ),
          throwsUnsupportedError,
        );
      });
    });

    // -----------------------------------------------------------------------
    // getUnlocked
    // -----------------------------------------------------------------------

    group('getUnlocked', () {
      test('returns empty list when none are unlocked', () async {
        final result = await repo.getUnlocked();
        expect(result, isEmpty);
      });

      test('returns only achievements where unlocked_at IS NOT NULL', () async {
        await repo.unlock(kAchFirstDhikr);
        await repo.unlock(kAchCount100);

        final result = await repo.getUnlocked();
        expect(result.length, equals(2));
        expect(result.every((a) => a.unlockedAt != null), isTrue);
      });

      test('returns unmodifiable list', () async {
        final result = await repo.getUnlocked();
        expect(
          () => (result as List<dynamic>).add(
            const Achievement(
              key: 'test',
              name: 'test',
              description: 'test',
              iconAsset: 'test',
            ),
          ),
          throwsUnsupportedError,
        );
      });
    });

    // -----------------------------------------------------------------------
    // getLocked
    // -----------------------------------------------------------------------

    group('getLocked', () {
      test('initially all achievements are locked', () async {
        final all = await repo.getAll();
        final locked = await repo.getLocked();
        expect(locked.length, equals(all.length));
      });

      test('returns only achievements where unlocked_at IS NULL', () async {
        await repo.unlock(kAchFirstDhikr);

        final all = await repo.getAll();
        final locked = await repo.getLocked();

        expect(locked.length, equals(all.length - 1));
        expect(locked.every((a) => a.unlockedAt == null), isTrue);
      });

      test('returns unmodifiable list', () async {
        final result = await repo.getLocked();
        expect(
          () => (result as List<dynamic>).add(
            const Achievement(
              key: 'test',
              name: 'test',
              description: 'test',
              iconAsset: 'test',
            ),
          ),
          throwsUnsupportedError,
        );
      });
    });

    // -----------------------------------------------------------------------
    // unlock
    // -----------------------------------------------------------------------

    group('unlock', () {
      test('sets unlocked_at to a non-null datetime string', () async {
        await repo.unlock(kAchFirstDhikr);

        final unlocked = await repo.getUnlocked();
        final ach = unlocked.firstWhere((a) => a.key == kAchFirstDhikr);
        expect(ach.unlockedAt, isNotNull);
        expect(ach.unlockedAt, isNotEmpty);
      });

      test('unlocked_at is formatted as ISO-8601', () async {
        await repo.unlock(kAchCount100);

        final unlocked = await repo.getUnlocked();
        final ach = unlocked.firstWhere((a) => a.key == kAchCount100);

        // datetime() in SQLite returns 'YYYY-MM-DD HH:MM:SS' — parseable.
        expect(() => DateTime.parse(ach.unlockedAt!), returnsNormally);
      });

      test('calling unlock twice on same key is idempotent', () async {
        await repo.unlock(kAchStreak3);
        final firstUnlockedAt = (await repo.getUnlocked())
            .firstWhere((a) => a.key == kAchStreak3)
            .unlockedAt;

        await repo.unlock(kAchStreak3);
        final secondUnlockedAt = (await repo.getUnlocked())
            .firstWhere((a) => a.key == kAchStreak3)
            .unlockedAt;

        // Second unlock must not overwrite the original timestamp.
        expect(secondUnlockedAt, equals(firstUnlockedAt));
      });

      test('unlocking one key does not affect other achievements', () async {
        final totalBefore = (await repo.getAll()).length;
        await repo.unlock(kAchFirstDhikr);
        final totalAfter = (await repo.getAll()).length;

        expect(totalAfter, equals(totalBefore));
        expect((await repo.getLocked()).length, equals(totalBefore - 1));
      });
    });

    // -----------------------------------------------------------------------
    // isUnlocked
    // -----------------------------------------------------------------------

    group('isUnlocked', () {
      test('returns false for locked achievement', () async {
        final result = await repo.isUnlocked(kAchCount10000);
        expect(result, isFalse);
      });

      test('returns true after unlocking', () async {
        await repo.unlock(kAchFirstDhikr);
        final result = await repo.isUnlocked(kAchFirstDhikr);
        expect(result, isTrue);
      });

      test('returns false for unknown key', () async {
        final result = await repo.isUnlocked('nonexistent_key_xyz');
        expect(result, isFalse);
      });
    });
  });
}
