// test/unit/viewmodels/stats_viewmodel_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dhikratwork/viewmodels/stats_viewmodel.dart';
import 'package:dhikratwork/models/daily_summary.dart';
import '../../fakes/fake_stats_repository.dart';

void main() {
  late FakeStatsRepository fakeRepo;
  late StatsViewModel vm;

  setUp(() {
    fakeRepo = FakeStatsRepository();
    vm = StatsViewModel(statsRepository: fakeRepo);
  });

  group('StatsViewModel', () {
    test('initial state: period is day, data empty, isLoading false', () {
      expect(vm.selectedPeriod, 'day');
      expect(vm.barChartData, isEmpty);
      expect(vm.lineChartData, isEmpty);
      expect(vm.isLoading, false);
    });

    test('loadStats sets isLoading true then false', () async {
      final states = <bool>[];
      vm.addListener(() => states.add(vm.isLoading));
      await vm.loadStats();
      expect(states, containsAllInOrder([true, false]));
    });

    test('loadStats populates barChartData from repository summaries', () async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      // dhikrId 1 gets 42 counts, dhikrId 2 gets 17 counts today.
      fakeRepo.seed(DailySummary(id: 1, dhikrId: 1, date: today, totalCount: 42, sessionCount: 1));
      fakeRepo.seed(DailySummary(id: 2, dhikrId: 2, date: today, totalCount: 17, sessionCount: 1));

      vm.selectedPeriod = 'day';
      await vm.loadStats();

      // barChartData keys are dhikrId as string.
      expect(vm.barChartData['1'], 42);
      expect(vm.barChartData['2'], 17);
    });

    test('loadStats populates lineChartData aggregated by date', () async {
      // Seed 3 days of data for a single dhikr.
      fakeRepo.seed(DailySummary(id: 1, dhikrId: 1, date: '2026-03-17', totalCount: 10, sessionCount: 1));
      fakeRepo.seed(DailySummary(id: 2, dhikrId: 1, date: '2026-03-18', totalCount: 25, sessionCount: 1));
      fakeRepo.seed(DailySummary(id: 3, dhikrId: 1, date: '2026-03-19', totalCount: 8,  sessionCount: 1));

      vm.selectedPeriod = 'month'; // covers March
      await vm.loadStats();

      expect(vm.lineChartData.length, greaterThanOrEqualTo(3));
      final entry = vm.lineChartData.firstWhere((e) => e.key == '2026-03-17');
      expect(entry.value, 10);
    });

    test('setPeriod changes period and triggers loadStats', () async {
      await vm.setPeriod('week');
      expect(vm.selectedPeriod, 'week');
    });

    test('getDateRange returns correct day range', () {
      vm.selectedPeriod = 'day';
      final (start, end) = vm.getDateRange();
      final today = DateTime.now();
      expect(start.year, today.year);
      expect(start.month, today.month);
      expect(start.day, today.day);
      expect(end.year, today.year);
      expect(end.month, today.month);
      expect(end.day, today.day);
    });

    test('getDateRange returns 7-day range for week', () {
      vm.selectedPeriod = 'week';
      final (start, end) = vm.getDateRange();
      final diff = end.difference(start).inDays;
      expect(diff, 6);
    });

    test('getDateRange returns correct month range', () {
      vm.selectedPeriod = 'month';
      final (start, end) = vm.getDateRange();
      // start is always the first day of the current month.
      expect(start.day, 1);
      // end is always today.
      final today = DateTime.now();
      expect(end.year, today.year);
      expect(end.month, today.month);
      expect(end.day, today.day);
      // range spans at most 30 or 31 days.
      final diff = end.difference(start).inDays;
      expect(diff, greaterThanOrEqualTo(0));
      expect(diff, lessThanOrEqualTo(30));
    });

    test('notifyListeners called after loadStats completes', () async {
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);
      await vm.loadStats();
      expect(notifyCount, greaterThanOrEqualTo(2)); // loading true + loading false
    });
  });
}
