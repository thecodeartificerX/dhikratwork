// test/unit/viewmodels/goal_viewmodel_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dhikratwork/viewmodels/goal_viewmodel.dart';
import 'package:dhikratwork/models/goal.dart';
import 'package:dhikratwork/models/daily_summary.dart';
import 'package:dhikratwork/utils/constants.dart';
import '../../fakes/fake_goal_repository.dart';
import '../../fakes/fake_stats_repository.dart';

void main() {
  late FakeGoalRepository fakeGoalRepo;
  late FakeStatsRepository fakeStatsRepo;
  late GoalViewModel vm;

  setUp(() {
    fakeGoalRepo = FakeGoalRepository();
    fakeStatsRepo = FakeStatsRepository();
    vm = GoalViewModel(
      goalRepository: fakeGoalRepo,
      statsRepository: fakeStatsRepo,
    );
  });

  group('GoalViewModel', () {
    test('initial state: goals empty, isLoading false', () {
      expect(vm.goals, isEmpty);
      expect(vm.isLoading, false);
      expect(vm.goalProgress, isEmpty);
    });

    test('loadGoals populates goals list and calculates progress', () async {
      // Seed the goal using the Phase 2B fake's seed() helper.
      final goal = Goal(
        id: 1,
        dhikrId: 10,
        targetCount: 100,
        period: kPeriodDaily,
        isActive: true,
        createdAt: '2026-03-19T00:00:00',
      );
      fakeGoalRepo.seed(goal);
      fakeGoalRepo.stubbedGoals = [goal];

      // Seed 50 counts for dhikrId=10 to yield 50% progress.
      final today = DateTime.now().toIso8601String().substring(0, 10);
      fakeStatsRepo.seed(DailySummary(
        id: 1,
        dhikrId: 10,
        date: today,
        totalCount: 50,
        sessionCount: 1,
      ));

      await vm.loadGoals();
      expect(vm.goals.length, 1);
      expect(vm.goalProgress[1], closeTo(0.5, 0.01));
    });

    test('addGoal calls GoalRepository.add() and reloads', () async {
      final goal = Goal(
        id: null,
        dhikrId: 2,
        targetCount: 33,
        period: kPeriodDaily,
        isActive: true,
        createdAt: '2026-03-19T00:00:00',
      );
      await vm.addGoal(goal);
      // savedGoals is a tracking field added to FakeGoalRepository (see Task 7).
      expect(fakeGoalRepo.savedGoals.any((g) => g.targetCount == 33), isTrue);
    });

    test('addGoal notifies listeners', () async {
      int count = 0;
      vm.addListener(() => count++);
      await vm.addGoal(Goal(
        id: null,
        dhikrId: null,
        targetCount: 50,
        period: kPeriodWeekly,
        isActive: true,
        createdAt: '2026-03-19T00:00:00',
      ));
      expect(count, greaterThan(0));
    });

    test('deleteGoal calls GoalRepository.delete(id) and reloads', () async {
      final goal = Goal(
        id: 5,
        dhikrId: null,
        targetCount: 100,
        period: kPeriodDaily,
        isActive: true,
        createdAt: '2026-03-19T00:00:00',
      );
      fakeGoalRepo.seed(goal);
      fakeGoalRepo.stubbedGoals = [goal];
      await vm.loadGoals();
      await vm.deleteGoal(5);
      // deletedIds is a tracking field added to FakeGoalRepository (see Task 7).
      expect(fakeGoalRepo.deletedIds, contains(5));
    });

    test('deactivateGoal calls GoalRepository.deactivate(id)', () async {
      await vm.deactivateGoal(3);
      // deactivatedIds is a tracking field added to FakeGoalRepository (see Task 7).
      expect(fakeGoalRepo.deactivatedIds, contains(3));
    });

    test('calculateProgress returns 0.0 when no counts exist', () async {
      final goal = Goal(
        id: 1,
        dhikrId: 99,
        targetCount: 100,
        period: kPeriodDaily,
        isActive: true,
        createdAt: '2026-03-19T00:00:00',
      );
      // No DailySummary seeded for dhikrId=99 → getTotalCountForDhikr returns 0.
      final progress = await vm.calculateProgress(goal);
      expect(progress, 0.0);
    });

    test('calculateProgress returns 1.0 when target met', () async {
      final goal = Goal(
        id: 1,
        dhikrId: 10,
        targetCount: 100,
        period: kPeriodDaily,
        isActive: true,
        createdAt: '2026-03-19T00:00:00',
      );
      fakeStatsRepo.seed(DailySummary(
        id: 1,
        dhikrId: 10,
        date: '2026-03-19',
        totalCount: 100,
        sessionCount: 1,
      ));
      final progress = await vm.calculateProgress(goal);
      expect(progress, 1.0);
    });

    test('calculateProgress clamps at 1.0 when over target', () async {
      final goal = Goal(
        id: 1,
        dhikrId: 10,
        targetCount: 50,
        period: kPeriodDaily,
        isActive: true,
        createdAt: '2026-03-19T00:00:00',
      );
      fakeStatsRepo.seed(DailySummary(
        id: 1,
        dhikrId: 10,
        date: '2026-03-19',
        totalCount: 200,
        sessionCount: 1,
      ));
      final progress = await vm.calculateProgress(goal);
      expect(progress, 1.0);
    });
  });
}
