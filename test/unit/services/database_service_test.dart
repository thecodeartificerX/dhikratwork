// test/unit/services/database_service_test.dart
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize sqflite_common_ffi for in-memory testing on desktop/CI.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseService', () {
    late DatabaseService service;

    setUp(() async {
      // Pass ':memory:' so each test gets a fresh, isolated database.
      service = DatabaseService(dbPath: inMemoryDatabasePath);
      await service.open();
    });

    tearDown(() async {
      await service.close();
    });

    // -----------------------------------------------------------------------
    // Schema creation
    // -----------------------------------------------------------------------

    group('schema creation', () {
      test('opens without throwing', () async {
        // open() is called in setUp — if we reach here, it succeeded.
        expect(service.isOpen, isTrue);
      });

      test('creates dhikr table', () async {
        final rows = await service.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tDhikr],
        );
        expect(rows, isNotEmpty);
      });

      test('creates dhikr_session table', () async {
        final rows = await service.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tDhikrSession],
        );
        expect(rows, isNotEmpty);
      });

      test('creates daily_summary table', () async {
        final rows = await service.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tDailySummary],
        );
        expect(rows, isNotEmpty);
      });

      test('creates goal table', () async {
        final rows = await service.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tGoal],
        );
        expect(rows, isNotEmpty);
      });

      test('creates achievement table', () async {
        final rows = await service.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tAchievement],
        );
        expect(rows, isNotEmpty);
      });

      test('creates user_settings table', () async {
        final rows = await service.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tUserSettings],
        );
        expect(rows, isNotEmpty);
      });

      test('creates streak table', () async {
        final rows = await service.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tStreak],
        );
        expect(rows, isNotEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // Seed data
    // -----------------------------------------------------------------------

    group('seed data', () {
      test('seeds preloaded dhikr rows', () async {
        final rows = await service.rawQuery(
          'SELECT COUNT(*) as c FROM $tDhikr WHERE $cDhikrIsPreloaded = 1',
          [],
        );
        final count = rows.first['c'] as int;
        expect(count, greaterThan(0));
      });

      test('seeds achievement rows', () async {
        final rows = await service.rawQuery(
          'SELECT COUNT(*) as c FROM $tAchievement',
          [],
        );
        final count = rows.first['c'] as int;
        expect(count, greaterThan(0));
      });

      test('seeds user_settings singleton row', () async {
        final rows = await service.rawQuery(
          'SELECT COUNT(*) as c FROM $tUserSettings WHERE $cSettingsId = ?',
          [kSingleRowId],
        );
        final count = rows.first['c'] as int;
        expect(count, equals(1));
      });

      test('seeds streak singleton row', () async {
        final rows = await service.rawQuery(
          'SELECT COUNT(*) as c FROM $tStreak WHERE $cStreakId = ?',
          [kSingleRowId],
        );
        final count = rows.first['c'] as int;
        expect(count, equals(1));
      });
    });

    // -----------------------------------------------------------------------
    // CRUD operations via DatabaseService helpers
    // -----------------------------------------------------------------------

    group('CRUD', () {
      test('insert and query dhikr', () async {
        final id = await service.insert(tDhikr, {
          cDhikrName: 'Test Dhikr',
          cDhikrArabicText: 'سبحان الله',
          cDhikrTransliteration: 'SubhanAllah',
          cDhikrTranslation: 'Glory be to Allah',
          cDhikrCategory: kCategoryGeneralTasbih,
          cDhikrIsPreloaded: 0,
          cDhikrIsHidden: 0,
          cDhikrSortOrder: 99,
          cDhikrCreatedAt: '2026-03-19T12:00:00',
        });
        expect(id, greaterThan(0));

        final rows = await service.query(
          tDhikr,
          where: '$cDhikrId = ?',
          whereArgs: [id],
        );
        expect(rows.length, equals(1));
        expect(rows.first[cDhikrName], equals('Test Dhikr'));
      });

      test('update dhikr', () async {
        final id = await service.insert(tDhikr, {
          cDhikrName: 'Before Update',
          cDhikrArabicText: 'الحمد لله',
          cDhikrTransliteration: 'Alhamdulillah',
          cDhikrTranslation: 'Praise be to Allah',
          cDhikrCategory: kCategoryGeneralTasbih,
          cDhikrIsPreloaded: 0,
          cDhikrIsHidden: 0,
          cDhikrSortOrder: 0,
          cDhikrCreatedAt: '2026-03-19T12:00:00',
        });

        final affected = await service.update(
          tDhikr,
          {cDhikrName: 'After Update'},
          where: '$cDhikrId = ?',
          whereArgs: [id],
        );
        expect(affected, equals(1));

        final rows = await service.query(
          tDhikr,
          where: '$cDhikrId = ?',
          whereArgs: [id],
        );
        expect(rows.first[cDhikrName], equals('After Update'));
      });

      test('delete dhikr', () async {
        final id = await service.insert(tDhikr, {
          cDhikrName: 'To Delete',
          cDhikrArabicText: 'الله أكبر',
          cDhikrTransliteration: 'Allahu Akbar',
          cDhikrTranslation: 'Allah is the Greatest',
          cDhikrCategory: kCategoryGeneralTasbih,
          cDhikrIsPreloaded: 0,
          cDhikrIsHidden: 0,
          cDhikrSortOrder: 0,
          cDhikrCreatedAt: '2026-03-19T12:00:00',
        });

        final affected = await service.delete(
          tDhikr,
          where: '$cDhikrId = ?',
          whereArgs: [id],
        );
        expect(affected, equals(1));

        final rows = await service.query(
          tDhikr,
          where: '$cDhikrId = ?',
          whereArgs: [id],
        );
        expect(rows, isEmpty);
      });

      test('rawQuery returns correct aggregate', () async {
        await service.insert(tDhikr, {
          cDhikrName: 'Agg Dhikr',
          cDhikrArabicText: 'لا إله إلا الله',
          cDhikrTransliteration: 'La ilaha illallah',
          cDhikrTranslation: 'There is no god but Allah',
          cDhikrCategory: kCategoryGeneralTasbih,
          cDhikrIsPreloaded: 0,
          cDhikrIsHidden: 0,
          cDhikrSortOrder: 0,
          cDhikrCreatedAt: '2026-03-19T12:00:00',
        });

        final rows = await service.rawQuery(
          'SELECT COUNT(*) as c FROM $tDhikr WHERE $cDhikrIsPreloaded = 0',
          [],
        );
        final count = rows.first['c'] as int;
        expect(count, greaterThanOrEqualTo(1));
      });
    });

    // -----------------------------------------------------------------------
    // Double-open guard
    // -----------------------------------------------------------------------

    test('calling open() twice is idempotent', () async {
      // Should not throw — second open is a no-op.
      await service.open();
      expect(service.isOpen, isTrue);
    });
  });
}
