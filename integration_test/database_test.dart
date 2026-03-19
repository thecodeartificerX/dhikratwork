// integration_test/database_test.dart
//
// Integration tests for database schema creation, seed data, and CRUD operations.
//
// These tests use DatabaseService backed by an in-memory SQLite database via
// sqflite_common_ffi. No UI device is required.
//
// Run with: flutter test integration_test/database_test.dart -d windows

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/utils/constants.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = DatabaseService(dbPath: inMemoryDatabasePath);
    await db.open();
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Schema Creation & Seed Data
  // ---------------------------------------------------------------------------
  group('Schema creation', () {
    test('all required tables exist after init', () async {
      final tables = await db.getTables();
      expect(
        tables,
        containsAll([
          'dhikr',
          'dhikr_session',
          'daily_summary',
          'goal',
          'achievement',
          'user_settings',
          'streak',
        ]),
      );
    });

    test('seed data populates default dhikr entries', () async {
      final rows = await db.rawQuery(
        'SELECT * FROM $tDhikr WHERE $cDhikrIsPreloaded = 1',
        [],
      );
      // Seeded entries: SubhanAllah, Alhamdulillah, Allahu Akbar, etc.
      expect(rows.length, greaterThanOrEqualTo(3));
    });

    test('seed data populates default user_settings row', () async {
      final rows = await db.rawQuery(
        'SELECT * FROM $tUserSettings',
        [],
      );
      expect(rows.length, equals(1));
      expect(rows.first[cSettingsId], equals(kSingleRowId));
    });

    test('seed data populates default streak row', () async {
      final rows = await db.rawQuery(
        'SELECT * FROM $tStreak',
        [],
      );
      expect(rows.length, equals(1));
      expect(rows.first[cStreakCurrentStreak], equals(0));
      expect(rows.first[cStreakLongestStreak], equals(0));
    });

    test('seed data populates achievement definitions', () async {
      final rows = await db.rawQuery(
        'SELECT * FROM $tAchievement',
        [],
      );
      // All 13 achievements defined in DatabaseService._seedAchievements().
      expect(rows.length, greaterThanOrEqualTo(13));

      // All achievements start locked (unlocked_at is null).
      for (final row in rows) {
        expect(row[cAchievementUnlockedAt], isNull);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Dhikr CRUD
  // ---------------------------------------------------------------------------
  group('Dhikr CRUD', () {
    test('insert and retrieve a custom dhikr', () async {
      final id = await db.insert(tDhikr, {
        cDhikrName: 'Astaghfirullah',
        cDhikrArabicText: 'أستغفر الله',
        cDhikrTransliteration: 'Astaghfirullah',
        cDhikrTranslation: 'I seek forgiveness from Allah',
        cDhikrCategory: kCategoryIstighfar,
        cDhikrIsPreloaded: 0,
        cDhikrIsHidden: 0,
        cDhikrSortOrder: 99,
        cDhikrCreatedAt: DateTime.now().toIso8601String(),
      });
      expect(id, greaterThan(0));

      final rows = await db.rawQuery(
        'SELECT * FROM $tDhikr WHERE $cDhikrId = ?',
        [id],
      );
      expect(rows.length, equals(1));
      expect(rows.first[cDhikrName], equals('Astaghfirullah'));
      expect(rows.first[cDhikrCategory], equals(kCategoryIstighfar));
    });

    test('update dhikr sort_order', () async {
      final id = await db.insert(tDhikr, {
        cDhikrName: 'TestDhikr',
        cDhikrArabicText: 'ت',
        cDhikrTransliteration: 't',
        cDhikrTranslation: 't',
        cDhikrCategory: kCategoryGeneralTasbih,
        cDhikrIsPreloaded: 0,
        cDhikrIsHidden: 0,
        cDhikrSortOrder: 33,
        cDhikrCreatedAt: DateTime.now().toIso8601String(),
      });

      await db.update(
        tDhikr,
        {cDhikrSortOrder: 99},
        where: '$cDhikrId = ?',
        whereArgs: [id],
      );

      final rows = await db.rawQuery(
        'SELECT $cDhikrSortOrder FROM $tDhikr WHERE $cDhikrId = ?',
        [id],
      );
      expect(rows.first[cDhikrSortOrder], equals(99));
    });

    test('delete a custom dhikr', () async {
      final id = await db.insert(tDhikr, {
        cDhikrName: 'ToDelete',
        cDhikrArabicText: 'ت',
        cDhikrTransliteration: 't',
        cDhikrTranslation: 't',
        cDhikrCategory: kCategoryGeneralTasbih,
        cDhikrIsPreloaded: 0,
        cDhikrIsHidden: 0,
        cDhikrSortOrder: 0,
        cDhikrCreatedAt: DateTime.now().toIso8601String(),
      });

      await db.delete(tDhikr, where: '$cDhikrId = ?', whereArgs: [id]);

      final rows = await db.rawQuery(
        'SELECT * FROM $tDhikr WHERE $cDhikrId = ?',
        [id],
      );
      expect(rows.isEmpty, isTrue);
    });

    test('hiding a preloaded dhikr sets is_hidden = 1', () async {
      // Preloaded dhikr id=1 (SubhanAllah) is seeded.
      await db.update(
        tDhikr,
        {cDhikrIsHidden: 1},
        where: '$cDhikrId = ? AND $cDhikrIsPreloaded = ?',
        whereArgs: [1, 1],
      );

      final rows = await db.rawQuery(
        'SELECT $cDhikrIsHidden FROM $tDhikr WHERE $cDhikrId = ?',
        [1],
      );
      expect(rows.first[cDhikrIsHidden], equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  // Session CRUD
  // ---------------------------------------------------------------------------
  group('Session CRUD', () {
    test('insert session and query by started_at date prefix', () async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await db.insert(tDhikrSession, {
        cSessionDhikrId: 1,
        cSessionCount: 33,
        cSessionStartedAt: '${today}T10:00:00',
        cSessionEndedAt: null,
        cSessionSource: kSourceMainApp,
      });

      final rows = await db.rawQuery(
        "SELECT * FROM $tDhikrSession WHERE $cSessionStartedAt LIKE '$today%'",
        [],
      );
      expect(rows.length, equals(1));
      expect(rows.first[cSessionCount], equals(33));
    });

    test('accumulate multiple sessions for same day', () async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      for (int i = 0; i < 3; i++) {
        await db.insert(tDhikrSession, {
          cSessionDhikrId: 1,
          cSessionCount: 10,
          cSessionStartedAt: '${today}T0${i + 1}:00:00',
          cSessionEndedAt: null,
          cSessionSource: kSourceMainApp,
        });
      }

      final rows = await db.rawQuery(
        'SELECT SUM($cSessionCount) as total FROM $tDhikrSession '
        "WHERE $cSessionStartedAt LIKE '$today%'",
        [],
      );
      expect(rows.first['total'], equals(30));
    });

    test('end session sets ended_at timestamp', () async {
      final now = DateTime.now().toIso8601String();
      final id = await db.insert(tDhikrSession, {
        cSessionDhikrId: 1,
        cSessionCount: 0,
        cSessionStartedAt: now,
        cSessionEndedAt: null,
        cSessionSource: kSourceHotkey,
      });

      final endedAt = DateTime.now().toIso8601String();
      await db.update(
        tDhikrSession,
        {cSessionEndedAt: endedAt},
        where: '$cSessionId = ?',
        whereArgs: [id],
      );

      final rows = await db.rawQuery(
        'SELECT $cSessionEndedAt FROM $tDhikrSession WHERE $cSessionId = ?',
        [id],
      );
      expect(rows.first[cSessionEndedAt], isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Goal CRUD
  // ---------------------------------------------------------------------------
  group('Goal CRUD', () {
    test('insert goal and deactivate it', () async {
      final id = await db.insert(tGoal, {
        cGoalDhikrId: 1,
        cGoalTargetCount: 100,
        cGoalPeriod: kPeriodDaily,
        cGoalIsActive: 1,
        cGoalCreatedAt: DateTime.now().toIso8601String(),
      });

      await db.update(
        tGoal,
        {cGoalIsActive: 0},
        where: '$cGoalId = ?',
        whereArgs: [id],
      );

      final rows = await db.rawQuery(
        'SELECT $cGoalIsActive FROM $tGoal WHERE $cGoalId = ?',
        [id],
      );
      expect(rows.first[cGoalIsActive], equals(0));
    });

    test('insert goal without dhikr_id (any-dhikr goal)', () async {
      final id = await db.insert(tGoal, {
        cGoalDhikrId: null,
        cGoalTargetCount: 500,
        cGoalPeriod: kPeriodWeekly,
        cGoalIsActive: 1,
        cGoalCreatedAt: DateTime.now().toIso8601String(),
      });

      final rows = await db.rawQuery(
        'SELECT * FROM $tGoal WHERE $cGoalId = ?',
        [id],
      );
      expect(rows.first[cGoalDhikrId], isNull);
      expect(rows.first[cGoalPeriod], equals(kPeriodWeekly));
    });
  });

  // ---------------------------------------------------------------------------
  // Achievement CRUD
  // ---------------------------------------------------------------------------
  group('Achievement CRUD', () {
    test('unlock an achievement sets unlocked_at', () async {
      await db.execute(
        'UPDATE $tAchievement '
        "SET $cAchievementUnlockedAt = datetime('now') "
        'WHERE $cAchievementKey = ? AND $cAchievementUnlockedAt IS NULL',
        [kAchFirstDhikr],
      );

      final rows = await db.rawQuery(
        'SELECT $cAchievementUnlockedAt FROM $tAchievement '
        'WHERE $cAchievementKey = ?',
        [kAchFirstDhikr],
      );
      expect(rows.first[cAchievementUnlockedAt], isNotNull);
    });

    test('unlocking is idempotent — second unlock does not change timestamp',
        () async {
      await db.execute(
        'UPDATE $tAchievement '
        "SET $cAchievementUnlockedAt = '2026-03-19T10:00:00' "
        'WHERE $cAchievementKey = ?',
        [kAchFirstDhikr],
      );

      // Second unlock attempt — WHERE clause guards against overwrite.
      await db.execute(
        'UPDATE $tAchievement '
        "SET $cAchievementUnlockedAt = datetime('now') "
        'WHERE $cAchievementKey = ? AND $cAchievementUnlockedAt IS NULL',
        [kAchFirstDhikr],
      );

      final rows = await db.rawQuery(
        'SELECT $cAchievementUnlockedAt FROM $tAchievement '
        'WHERE $cAchievementKey = ?',
        [kAchFirstDhikr],
      );
      expect(rows.first[cAchievementUnlockedAt], equals('2026-03-19T10:00:00'));
    });
  });

  // ---------------------------------------------------------------------------
  // User Settings CRUD
  // ---------------------------------------------------------------------------
  group('UserSettings CRUD', () {
    test('update active_dhikr_id in settings', () async {
      await db.update(
        tUserSettings,
        {cSettingsActiveDhikrId: 1},
        where: '$cSettingsId = ?',
        whereArgs: [kSingleRowId],
      );

      final rows = await db.rawQuery(
        'SELECT $cSettingsActiveDhikrId FROM $tUserSettings '
        'WHERE $cSettingsId = ?',
        [kSingleRowId],
      );
      expect(rows.first[cSettingsActiveDhikrId], equals(1));
    });

    test('update global hotkey string', () async {
      await db.update(
        tUserSettings,
        {cSettingsGlobalHotkey: 'ctrl+shift+z'},
        where: '$cSettingsId = ?',
        whereArgs: [kSingleRowId],
      );

      final rows = await db.rawQuery(
        'SELECT $cSettingsGlobalHotkey FROM $tUserSettings '
        'WHERE $cSettingsId = ?',
        [kSingleRowId],
      );
      expect(rows.first[cSettingsGlobalHotkey], equals('ctrl+shift+z'));
    });
  });

  // ---------------------------------------------------------------------------
  // Migration Integrity
  // ---------------------------------------------------------------------------
  group('Migration integrity', () {
    test('re-opening database does not throw (close/open cycle)', () async {
      await db.insert(tDhikr, {
        cDhikrName: 'Persistent',
        cDhikrArabicText: 'ت',
        cDhikrTransliteration: 't',
        cDhikrTranslation: 't',
        cDhikrCategory: kCategoryGeneralTasbih,
        cDhikrIsPreloaded: 0,
        cDhikrIsHidden: 0,
        cDhikrSortOrder: 0,
        cDhikrCreatedAt: DateTime.now().toIso8601String(),
      });

      // Close and reopen (simulates app restart).
      // In-memory DB is ephemeral — this test confirms close/open cycle is safe.
      await db.close();
      db = DatabaseService(dbPath: inMemoryDatabasePath);
      await db.open();

      final tables = await db.getTables();
      expect(tables.contains('dhikr'), isTrue);
      expect(tables.contains('dhikr_session'), isTrue);
      expect(tables.contains('streak'), isTrue);
    });

    test('getTables returns no sqlite_ system tables', () async {
      final tables = await db.getTables();
      for (final name in tables) {
        expect(name.startsWith('sqlite_'), isFalse);
      }
    });

    test('database version is set correctly', () async {
      final rows = await db.rawQuery('PRAGMA user_version', []);
      expect(rows.first['user_version'], equals(kDatabaseVersion));
    });
  });
}
