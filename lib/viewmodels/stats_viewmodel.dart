// lib/viewmodels/stats_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../repositories/stats_repository.dart';

class StatsViewModel extends ChangeNotifier {
  final StatsRepository _statsRepository;

  StatsViewModel({required StatsRepository statsRepository})
      : _statsRepository = statsRepository;

  String selectedPeriod = 'day'; // 'day' | 'week' | 'month'
  Map<String, int> barChartData = {};
  List<MapEntry<String, int>> lineChartData = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadStats() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final (start, end) = getDateRange();
      final startDate = '${start.year.toString().padLeft(4, '0')}-'
          '${start.month.toString().padLeft(2, '0')}-'
          '${start.day.toString().padLeft(2, '0')}';
      final endDate = '${end.year.toString().padLeft(4, '0')}-'
          '${end.month.toString().padLeft(2, '0')}-'
          '${end.day.toString().padLeft(2, '0')}';

      final summaries = await _statsRepository.getDailySummariesForPeriod(
        startDate,
        endDate,
      );

      // Build barChartData: dhikrId (as string key) -> total count for period
      final barMap = <String, int>{};
      for (final s in summaries) {
        final key = s.dhikrId.toString();
        barMap[key] = (barMap[key] ?? 0) + s.totalCount;
      }
      barChartData = Map.unmodifiable(barMap);

      // Build lineChartData: date -> daily total across all dhikrs
      final lineMap = <String, int>{};
      for (final s in summaries) {
        lineMap[s.date] = (lineMap[s.date] ?? 0) + s.totalCount;
      }
      final sortedDates = lineMap.keys.toList()..sort();
      lineChartData = List.unmodifiable(
        sortedDates.map((d) => MapEntry(d, lineMap[d]!)).toList(),
      );
    } catch (e) {
      errorMessage = 'Failed to load stats: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPeriod(String period) async {
    assert(
      ['day', 'week', 'month'].contains(period),
      'period must be day, week, or month',
    );
    selectedPeriod = period;
    notifyListeners();
    await loadStats();
  }

  /// Returns (startDate, endDate) inclusive based on [selectedPeriod].
  (DateTime, DateTime) getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (selectedPeriod) {
      'day' => (today, today),
      'week' => (today.subtract(const Duration(days: 6)), today),
      'month' => (DateTime(today.year, today.month, 1), today),
      _ => (today, today),
    };
  }
}
