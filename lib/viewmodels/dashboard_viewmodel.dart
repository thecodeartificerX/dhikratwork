// lib/viewmodels/dashboard_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:dhikratwork/models/daily_summary.dart';
import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/models/streak.dart';
import 'package:dhikratwork/models/user_settings.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';
import 'package:dhikratwork/repositories/stats_repository.dart';
import 'package:dhikratwork/repositories/streak_repository.dart';
import 'package:dhikratwork/repositories/settings_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final DhikrRepository _dhikrRepository;
  final StatsRepository _statsRepository;
  final StreakRepository _streakRepository;
  final SettingsRepository _settingsRepository;

  DashboardViewModel({
    required DhikrRepository dhikrRepository,
    required StatsRepository statsRepository,
    required StreakRepository streakRepository,
    required SettingsRepository settingsRepository,
  })  : _dhikrRepository = dhikrRepository,
        _statsRepository = statsRepository,
        _streakRepository = streakRepository,
        _settingsRepository = settingsRepository;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  List<DailySummary> _todaySummaries = const [];
  List<DailySummary> get todaySummaries => List.unmodifiable(_todaySummaries);

  int _totalTodayCount = 0;
  int get totalTodayCount => _totalTodayCount;

  int _currentStreak = 0;
  int get currentStreak => _currentStreak;

  Dhikr? _activeDhikr;
  Dhikr? get activeDhikr => _activeDhikr;

  List<Dhikr> _quickAccessDhikrs = const [];
  List<Dhikr> get quickAccessDhikrs => List.unmodifiable(_quickAccessDhikrs);

  double _dailyGoalProgress = 0.0;

  /// Value between 0.0 and 1.0 representing overall daily goal completion.
  double get dailyGoalProgress => _dailyGoalProgress;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ---------------------------------------------------------------------------
  // Commands
  // ---------------------------------------------------------------------------

  /// Full load: settings, streak, today's summaries, quick-access dhikr list.
  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final today = _todayDateString();

      // Load in parallel where possible.
      final results = await Future.wait([
        _statsRepository.getDailySummaries(today),
        _statsRepository.getTotalCountForDate(today),
        _streakRepository.getStreak(),
        _settingsRepository.getSettings(),
        _dhikrRepository.getAll(),
      ]);

      _todaySummaries = results[0] as List<DailySummary>;
      _totalTodayCount = results[1] as int;
      final streak = results[2] as Streak;
      _currentStreak = streak.currentStreak;
      final settings = results[3] as UserSettings;
      final allDhikr = results[4] as List<Dhikr>;

      // Resolve active dhikr.
      if (settings.activeDhikrId != null) {
        _activeDhikr = allDhikr
            .where((d) => d.id == settings.activeDhikrId)
            .firstOrNull;
      }

      // Quick-access grid: up to 6 non-hidden dhikr.
      _quickAccessDhikrs = List.unmodifiable(
        allDhikr.where((d) => !d.isHidden).take(6).toList(),
      );

      // Goal progress: simple ratio of totalTodayCount to a default 100-count
      // daily goal (will be replaced by GoalViewModel in Phase 4).
      const defaultDailyGoal = 100;
      _dailyGoalProgress =
          (_totalTodayCount / defaultDailyGoal).clamp(0.0, 1.0);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lightweight refresh: only reload today's counts and streak.
  Future<void> refreshSummary() async {
    final today = _todayDateString();

    final results = await Future.wait([
      _statsRepository.getTotalCountForDate(today),
      _statsRepository.getDailySummaries(today),
      _streakRepository.getStreak(),
    ]);

    _totalTodayCount = results[0] as int;
    _todaySummaries = results[1] as List<DailySummary>;
    final streak = results[2] as Streak;
    _currentStreak = streak.currentStreak;

    const defaultDailyGoal = 100;
    _dailyGoalProgress =
        (_totalTodayCount / defaultDailyGoal).clamp(0.0, 1.0);

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _todayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
