// test/unit/viewmodels/dashboard_viewmodel_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:dhikratwork/models/streak.dart';
import 'package:dhikratwork/viewmodels/dashboard_viewmodel.dart';
import '../../fakes/fake_dhikr_repository.dart';
import '../../fakes/fake_stats_repository.dart';
import '../../fakes/fake_streak_repository.dart';
import '../../fakes/fake_settings_repository.dart';

void main() {
  late DashboardViewModel vm;
  late FakeStatsRepository statsRepo;
  late FakeStreakRepository streakRepo;

  setUp(() {
    statsRepo = FakeStatsRepository();
    streakRepo = FakeStreakRepository();
    vm = DashboardViewModel(
      dhikrRepository: FakeDhikrRepository(),
      statsRepository: statsRepo,
      streakRepository: streakRepo,
      settingsRepository: FakeSettingsRepository(),
    );
  });

  test('initial state: all zeroed out, not loading', () {
    expect(vm.totalTodayCount, equals(0));
    expect(vm.currentStreak, equals(0));
    expect(vm.activeDhikr, isNull);
    expect(vm.quickAccessDhikrs, isEmpty);
    expect(vm.isLoading, isFalse);
    expect(vm.dailyGoalProgress, equals(0.0));
  });

  test('loadDashboard sets isLoading then resolves', () async {
    final loadingStates = <bool>[];
    vm.addListener(() => loadingStates.add(vm.isLoading));

    await vm.loadDashboard();

    expect(loadingStates.first, isTrue);
    expect(loadingStates.last, isFalse);
  });

  test('loadDashboard populates quickAccessDhikrs', () async {
    await vm.loadDashboard();
    // FakeDhikrRepository has 2 dhikrs; quick access loads up to 6.
    expect(vm.quickAccessDhikrs, hasLength(2));
  });

  test('loadDashboard reads currentStreak from streakRepository', () async {
    streakRepo.seed(
      const Streak(id: 1, currentStreak: 7, longestStreak: 14, lastActiveDate: '2026-03-18'),
    );
    await vm.loadDashboard();
    expect(vm.currentStreak, equals(7));
  });

  test('totalTodayCount aggregates all dhikr counts', () async {
    final today = _todayString();
    await statsRepo.upsertDailySummary(1, today, 33);
    await statsRepo.upsertDailySummary(2, today, 17);

    await vm.loadDashboard();
    expect(vm.totalTodayCount, equals(50));
  });

  test('dailyGoalProgress clamps to 0.0–1.0', () async {
    await vm.loadDashboard();
    expect(vm.dailyGoalProgress, greaterThanOrEqualTo(0.0));
    expect(vm.dailyGoalProgress, lessThanOrEqualTo(1.0));
  });

  test('refreshSummary updates totalTodayCount without full reload', () async {
    await vm.loadDashboard();
    final today = _todayString();
    await statsRepo.upsertDailySummary(1, today, 100);

    await vm.refreshSummary();
    expect(vm.totalTodayCount, equals(100));
  });
}

String _todayString() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
