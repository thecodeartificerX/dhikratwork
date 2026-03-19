// test/unit/repositories/stats_repository_test.dart
import 'package:dhikratwork/repositories/stats_repository.dart';
import 'package:dhikratwork/models/daily_summary.dart';
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('StatsRepository', () {
    late DatabaseService dbService;
    late StatsRepository repo;

    // Helper: insert a minimal dhikr row so FK constraint is satisfied.
    Future<int> insertDhikr(String name) async {
      return dbService.insert(tDhikr, {
        cDhikrName: name,
        cDhikrArabicText: 'ت',
        cDhikrTransliteration: 't',
        cDhikrTranslation: 't',
        cDhikrCategory: kCategoryGeneralTasbih,
        cDhikrIsPreloaded: 0,
        cDhikrIsHidden: 0,
        cDhikrSortOrder: 0,
        cDhikrCreatedAt: '2026-03-19T00:00:00',
      });
    }

    setUp(() async {
      dbService = DatabaseService(dbPath: inMemoryDatabasePath);
      await dbService.open();
      repo = StatsRepository(dbService);
    });

    tearDown(() async {
      await dbService.close();
    });

    // -----------------------------------------------------------------------
    // upsertDailySummary
    // -----------------------------------------------------------------------

    group('upsertDailySummary', () {
      test('inserts new row when none exists', () async {
        final dhikrId = await insertDhikr('Dhikr A');

        await repo.upsertDailySummary(dhikrId, '2026-03-19', 10);

        final summaries = await repo.getDailySummaries('2026-03-19');
        expect(summaries.length, equals(1));
        expect(summaries.first.dhikrId, equals(dhikrId));
        expect(summaries.first.totalCount, equals(10));
      });

      test('accumulates count on subsequent upserts for same dhikr+date', () async {
        final dhikrId = await insertDhikr('Dhikr B');

        await repo.upsertDailySummary(dhikrId, '2026-03-19', 5);
        await repo.upsertDailySummary(dhikrId, '2026-03-19', 3);

        final summaries = await repo.getDailySummaries('2026-03-19');
        expect(summaries.first.totalCount, equals(8));
      });

      test('increments session_count on each upsert', () async {
        final dhikrId = await insertDhikr('Dhikr C');

        await repo.upsertDailySummary(dhikrId, '2026-03-19', 1);
        await repo.upsertDailySummary(dhikrId, '2026-03-19', 1);
        await repo.upsertDailySummary(dhikrId, '2026-03-19', 1);

        final summaries = await repo.getDailySummaries('2026-03-19');
        expect(summaries.first.sessionCount, equals(3));
      });

      test('does not affect rows for other dates', () async {
        final dhikrId = await insertDhikr('Dhikr D');

        await repo.upsertDailySummary(dhikrId, '2026-03-19', 10);
        await repo.upsertDailySummary(dhikrId, '2026-03-18', 20);

        final todaySummaries = await repo.getDailySummaries('2026-03-19');
        expect(todaySummaries.length, equals(1));
        expect(todaySummaries.first.totalCount, equals(10));
      });
    });

    // -----------------------------------------------------------------------
    // getDailySummaries
    // -----------------------------------------------------------------------

    group('getDailySummaries', () {
      test('returns empty list when no rows for date', () async {
        final result = await repo.getDailySummaries('2099-01-01');
        expect(result, isEmpty);
      });

      test('returns all summaries for the given date', () async {
        final idA = await insertDhikr('Multi A');
        final idB = await insertDhikr('Multi B');

        await repo.upsertDailySummary(idA, '2026-03-20', 5);
        await repo.upsertDailySummary(idB, '2026-03-20', 7);

        final result = await repo.getDailySummaries('2026-03-20');
        expect(result.length, equals(2));
      });

      test('returns unmodifiable list', () async {
        final result = await repo.getDailySummaries('2099-01-02');
        expect(
          () => (result as List<dynamic>).add(
            DailySummary(dhikrId: 0, date: '2099-01-02'),
          ),
          throwsUnsupportedError,
        );
      });
    });

    // -----------------------------------------------------------------------
    // getDailySummariesForPeriod
    // -----------------------------------------------------------------------

    group('getDailySummariesForPeriod', () {
      test('returns rows within inclusive date range', () async {
        final dhikrId = await insertDhikr('Period Dhikr');

        await repo.upsertDailySummary(dhikrId, '2026-03-01', 1);
        await repo.upsertDailySummary(dhikrId, '2026-03-15', 2);
        await repo.upsertDailySummary(dhikrId, '2026-03-31', 3);

        final result = await repo.getDailySummariesForPeriod(
          '2026-03-01',
          '2026-03-15',
        );
        expect(result.length, equals(2));
      });

      test('excludes rows outside range', () async {
        final dhikrId = await insertDhikr('Exclude Dhikr');

        await repo.upsertDailySummary(dhikrId, '2026-02-28', 99);
        await repo.upsertDailySummary(dhikrId, '2026-04-01', 99);

        final result = await repo.getDailySummariesForPeriod(
          '2026-03-01',
          '2026-03-31',
        );
        expect(result, isEmpty);
      });

      test('returns unmodifiable list', () async {
        final result = await repo.getDailySummariesForPeriod(
          '2026-01-01',
          '2026-01-31',
        );
        expect(
          () => (result as List<dynamic>).add(
            DailySummary(dhikrId: 0, date: '2026-01-01'),
          ),
          throwsUnsupportedError,
        );
      });
    });

    // -----------------------------------------------------------------------
    // getTotalCountForDate
    // -----------------------------------------------------------------------

    group('getTotalCountForDate', () {
      test('returns 0 when no rows', () async {
        final total = await repo.getTotalCountForDate('2099-12-31');
        expect(total, equals(0));
      });

      test('sums total_count across all dhikrs for date', () async {
        final idA = await insertDhikr('Sum A');
        final idB = await insertDhikr('Sum B');

        await repo.upsertDailySummary(idA, '2026-03-10', 10);
        await repo.upsertDailySummary(idB, '2026-03-10', 25);

        final total = await repo.getTotalCountForDate('2026-03-10');
        expect(total, equals(35));
      });
    });

    // -----------------------------------------------------------------------
    // getTotalCountForDhikr
    // -----------------------------------------------------------------------

    group('getTotalCountForDhikr', () {
      test('returns 0 when no rows for dhikr', () async {
        final dhikrId = await insertDhikr('No Count Dhikr');
        final total = await repo.getTotalCountForDhikr(dhikrId);
        expect(total, equals(0));
      });

      test('returns sum of total_count across all dates for dhikr', () async {
        final dhikrId = await insertDhikr('All Time Dhikr');

        await repo.upsertDailySummary(dhikrId, '2026-01-01', 100);
        await repo.upsertDailySummary(dhikrId, '2026-02-01', 200);
        await repo.upsertDailySummary(dhikrId, '2026-03-01', 50);

        final total = await repo.getTotalCountForDhikr(dhikrId);
        expect(total, equals(350));
      });

      test('does not include counts from other dhikrs', () async {
        final idA = await insertDhikr('Isolated A');
        final idB = await insertDhikr('Isolated B');

        await repo.upsertDailySummary(idA, '2026-03-19', 100);
        await repo.upsertDailySummary(idB, '2026-03-19', 999);

        final total = await repo.getTotalCountForDhikr(idA);
        expect(total, equals(100));
      });
    });

    // -----------------------------------------------------------------------
    // getCountsByDhikrForPeriod
    // -----------------------------------------------------------------------

    group('getCountsByDhikrForPeriod', () {
      test('returns empty list when no rows in period', () async {
        final dhikrId = await insertDhikr('Chart Dhikr Empty');
        final result = await repo.getCountsByDhikrForPeriod(
          dhikrId,
          '2099-01-01',
          '2099-01-31',
        );
        expect(result, isEmpty);
      });

      test('returns summaries for dhikr within period', () async {
        final dhikrId = await insertDhikr('Chart Dhikr');

        await repo.upsertDailySummary(dhikrId, '2026-03-01', 10);
        await repo.upsertDailySummary(dhikrId, '2026-03-05', 20);
        await repo.upsertDailySummary(dhikrId, '2026-04-01', 30); // outside range

        final result = await repo.getCountsByDhikrForPeriod(
          dhikrId,
          '2026-03-01',
          '2026-03-31',
        );
        expect(result.length, equals(2));
        expect(result.every((s) => s.dhikrId == dhikrId), isTrue);
      });

      test('returns unmodifiable list', () async {
        final dhikrId = await insertDhikr('Chart Unmod');
        final result = await repo.getCountsByDhikrForPeriod(
          dhikrId, '2026-01-01', '2026-01-31',
        );
        expect(
          () => (result as List<dynamic>).add(
            DailySummary(dhikrId: dhikrId, date: '2026-01-01'),
          ),
          throwsUnsupportedError,
        );
      });
    });
  });
}
