// lib/viewmodels/stats_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:dhikratwork/repositories/stats_repository.dart';
import 'package:dhikratwork/repositories/streak_repository.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';

class StatsViewModel extends ChangeNotifier {
  final StatsRepository _statsRepository;
  final StreakRepository _streakRepository;
  final DhikrRepository _dhikrRepository;

  StatsViewModel({
    required StatsRepository statsRepository,
    required StreakRepository streakRepository,
    required DhikrRepository dhikrRepository,
  })  : _statsRepository = statsRepository,
        _streakRepository = streakRepository,
        _dhikrRepository = dhikrRepository;

  String selectedPeriod = 'day'; // 'day' | 'week' | 'month'
  Map<String, int> barChartData = {};
  List<MapEntry<String, int>> lineChartData = [];
  bool isLoading = false;
  String? errorMessage;

  int _currentStreak = 0;
  int get currentStreak => _currentStreak;

  int _totalCountForPeriod = 0;
  int get totalCountForPeriod => _totalCountForPeriod;

  /// ID → name lookup map, populated during [loadStats].
  Map<int, String> _dhikrNames = {};

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

      // Load summaries, streak, and dhikr list in parallel.
      final results = await Future.wait([
        _statsRepository.getDailySummariesForPeriod(startDate, endDate),
        _streakRepository.getStreak(),
        _dhikrRepository.getAll(),
      ]);

      final summaries = results[0] as List;
      final streak = results[1];
      final dhikrs = results[2] as List;

      // Populate dhikr name lookup map.
      _dhikrNames = {
        for (final d in dhikrs)
          if (d.id != null) d.id as int: d.name as String,
      };

      // Extract currentStreak from the loaded Streak model.
      _currentStreak = (streak as dynamic).currentStreak as int;

      // Build barChartData: dhikrId (as string key) -> total count for period.
      final barMap = <String, int>{};
      for (final s in summaries) {
        final key = (s.dhikrId as int).toString();
        barMap[key] = (barMap[key] ?? 0) + (s.totalCount as int);
      }
      barChartData = Map.unmodifiable(barMap);

      // Build lineChartData: date -> daily total across all dhikrs.
      final lineMap = <String, int>{};
      for (final s in summaries) {
        final date = s.date as String;
        lineMap[date] = (lineMap[date] ?? 0) + (s.totalCount as int);
      }
      final sortedDates = lineMap.keys.toList()..sort();
      lineChartData = List.unmodifiable(
        sortedDates.map((d) => MapEntry(d, lineMap[d]!)).toList(),
      );

      // Compute totalCountForPeriod as sum of all bar chart values.
      _totalCountForPeriod = barMap.values.fold(0, (sum, v) => sum + v);
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

  /// Returns the dhikr name for [id], or 'Unknown' if not found.
  String dhikrNameForId(int id) => _dhikrNames[id] ?? 'Unknown';

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
