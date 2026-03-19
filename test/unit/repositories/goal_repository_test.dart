// test/unit/repositories/goal_repository_test.dart
import 'package:dhikratwork/models/goal.dart';
import 'package:dhikratwork/repositories/goal_repository.dart';
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('GoalRepository', () {
    late DatabaseService dbService;
    late GoalRepository repo;

    // Helper: insert a minimal dhikr row for FK satisfaction.
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

    Goal makeGoal({int? dhikrId, int target = 100, String period = kPeriodDaily}) {
      return Goal(
        dhikrId: dhikrId,
        targetCount: target,
        period: period,
        isActive: true,
        createdAt: '2026-03-19T00:00:00',
      );
    }

    setUp(() async {
      dbService = DatabaseService(dbPath: inMemoryDatabasePath);
      await dbService.open();
      repo = GoalRepository(dbService);
    });

    tearDown(() async {
      await dbService.close();
    });

    // -----------------------------------------------------------------------
    // add
    // -----------------------------------------------------------------------

    group('add', () {
      test('inserts goal and returns assigned id', () async {
        final dhikrId = await insertDhikr('Add Dhikr');
        final goal = makeGoal(dhikrId: dhikrId);

        final id = await repo.add(goal);

        expect(id, greaterThan(0));
      });

      test('inserts goal with null dhikrId (any-dhikr goal)', () async {
        final goal = makeGoal(); // dhikrId is null

        final id = await repo.add(goal);

        expect(id, greaterThan(0));
      });

      test('persisted goal is retrievable by id', () async {
        final dhikrId = await insertDhikr('Persist Dhikr');
        final goal = makeGoal(dhikrId: dhikrId, target: 33);

        final id = await repo.add(goal);
        final retrieved = await repo.getById(id);

        expect(retrieved, isNotNull);
        expect(retrieved!.targetCount, equals(33));
        expect(retrieved.dhikrId, equals(dhikrId));
      });
    });

    // -----------------------------------------------------------------------
    // getById
    // -----------------------------------------------------------------------

    group('getById', () {
      test('returns null for non-existent id', () async {
        final result = await repo.getById(9999);
        expect(result, isNull);
      });

      test('returns correct goal for existing id', () async {
        final goal = makeGoal(target: 500, period: kPeriodWeekly);
        final id = await repo.add(goal);

        final result = await repo.getById(id);

        expect(result, isNotNull);
        expect(result!.targetCount, equals(500));
        expect(result.period, equals(kPeriodWeekly));
      });
    });

    // -----------------------------------------------------------------------
    // getAll
    // -----------------------------------------------------------------------

    group('getAll', () {
      test('returns empty list when no goals', () async {
        final result = await repo.getAll();
        expect(result, isEmpty);
      });

      test('returns all goals regardless of is_active', () async {
        final id1 = await repo.add(makeGoal(target: 10));
        final id2 = await repo.add(makeGoal(target: 20));
        await repo.deactivate(id2);

        final result = await repo.getAll();
        expect(result.length, equals(2));
        // Suppress unused variable warning
        expect(id1, greaterThan(0));
      });

      test('returns unmodifiable list', () async {
        final result = await repo.getAll();
        expect(
          () => (result as List<dynamic>).add(
            makeGoal(target: 0),
          ),
          throwsUnsupportedError,
        );
      });
    });

    // -----------------------------------------------------------------------
    // update
    // -----------------------------------------------------------------------

    group('update', () {
      test('updates target_count', () async {
        final id = await repo.add(makeGoal(target: 50));
        final existing = await repo.getById(id);

        final updated = Goal(
          id: existing!.id,
          dhikrId: existing.dhikrId,
          targetCount: 200,
          period: existing.period,
          isActive: existing.isActive,
          createdAt: existing.createdAt,
        );

        await repo.update(updated);

        final result = await repo.getById(id);
        expect(result!.targetCount, equals(200));
      });

      test('updates period', () async {
        final id = await repo.add(makeGoal(period: kPeriodDaily));
        final existing = await repo.getById(id);

        final updated = Goal(
          id: existing!.id,
          dhikrId: existing.dhikrId,
          targetCount: existing.targetCount,
          period: kPeriodMonthly,
          isActive: existing.isActive,
          createdAt: existing.createdAt,
        );

        await repo.update(updated);

        final result = await repo.getById(id);
        expect(result!.period, equals(kPeriodMonthly));
      });
    });

    // -----------------------------------------------------------------------
    // delete
    // -----------------------------------------------------------------------

    group('delete', () {
      test('removes goal permanently', () async {
        final id = await repo.add(makeGoal(target: 99));

        await repo.delete(id);

        final result = await repo.getById(id);
        expect(result, isNull);
      });

      test('does not affect other goals', () async {
        final idA = await repo.add(makeGoal(target: 1));
        final idB = await repo.add(makeGoal(target: 2));

        await repo.delete(idA);

        final result = await repo.getById(idB);
        expect(result, isNotNull);
      });
    });

    // -----------------------------------------------------------------------
    // deactivate
    // -----------------------------------------------------------------------

    group('deactivate', () {
      test('sets is_active to 0', () async {
        final id = await repo.add(makeGoal(target: 10));

        await repo.deactivate(id);

        final result = await repo.getById(id);
        expect(result!.isActive, isFalse);
      });

      test('deactivated goal does not appear in getActiveGoals', () async {
        final id = await repo.add(makeGoal(target: 10));

        await repo.deactivate(id);

        final active = await repo.getActiveGoals();
        expect(active.any((g) => g.id == id), isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // getActiveGoals
    // -----------------------------------------------------------------------

    group('getActiveGoals', () {
      test('returns only active goals', () async {
        final idA = await repo.add(makeGoal(target: 10));
        final idB = await repo.add(makeGoal(target: 20));
        await repo.deactivate(idB);

        final active = await repo.getActiveGoals();
        expect(active.length, equals(1));
        expect(active.first.id, equals(idA));
      });

      test('returns unmodifiable list', () async {
        final result = await repo.getActiveGoals();
        expect(
          () => (result as List<dynamic>).add(
            makeGoal(target: 0),
          ),
          throwsUnsupportedError,
        );
      });
    });

    // -----------------------------------------------------------------------
    // getGoalsForDhikr
    // -----------------------------------------------------------------------

    group('getGoalsForDhikr', () {
      test('returns goals matching dhikrId', () async {
        final dhikrId = await insertDhikr('Filter Dhikr');
        await repo.add(makeGoal(dhikrId: dhikrId, target: 33));
        await repo.add(makeGoal(target: 100)); // any-dhikr goal

        final result = await repo.getGoalsForDhikr(dhikrId);
        expect(result.length, equals(1));
        expect(result.first.dhikrId, equals(dhikrId));
      });

      test('returns empty when no goals for dhikrId', () async {
        final result = await repo.getGoalsForDhikr(9999);
        expect(result, isEmpty);
      });

      test('returns unmodifiable list', () async {
        final result = await repo.getGoalsForDhikr(1);
        expect(
          () => (result as List<dynamic>).add(
            makeGoal(target: 0),
          ),
          throwsUnsupportedError,
        );
      });
    });
  });
}
