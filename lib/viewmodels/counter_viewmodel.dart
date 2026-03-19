// lib/viewmodels/counter_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/models/dhikr_session.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';
import 'package:dhikratwork/repositories/session_repository.dart';
import 'package:dhikratwork/repositories/stats_repository.dart';
import 'package:dhikratwork/repositories/streak_repository.dart';
import 'package:dhikratwork/repositories/achievement_repository.dart';
import 'package:dhikratwork/repositories/settings_repository.dart';

class CounterViewModel extends ChangeNotifier {
  final DhikrRepository _dhikrRepository;
  final SessionRepository _sessionRepository;
  final StatsRepository _statsRepository;
  final StreakRepository _streakRepository;
  final AchievementRepository _achievementRepository;
  final SettingsRepository _settingsRepository;

  CounterViewModel({
    required DhikrRepository dhikrRepository,
    required SessionRepository sessionRepository,
    required StatsRepository statsRepository,
    required StreakRepository streakRepository,
    required AchievementRepository achievementRepository,
    required SettingsRepository settingsRepository,
  })  : _dhikrRepository = dhikrRepository,
        _sessionRepository = sessionRepository,
        _statsRepository = statsRepository,
        _streakRepository = streakRepository,
        _achievementRepository = achievementRepository,
        _settingsRepository = settingsRepository;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  Dhikr? _activeDhikr;
  Dhikr? get activeDhikr => _activeDhikr;

  DhikrSession? _activeSession;
  DhikrSession? get activeSession => _activeSession;

  int _todayCount = 0;
  int get todayCount => _todayCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ---------------------------------------------------------------------------
  // Commands
  // ---------------------------------------------------------------------------

  /// Load dhikr by [dhikrId] and set it as the active dhikr for hotkey
  /// increment. Also persists the choice to [SettingsRepository].
  Future<void> setActiveDhikr(int dhikrId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _activeDhikr = await _dhikrRepository.getById(dhikrId);
      await _settingsRepository.setActiveDhikr(dhikrId);

      // Load today's count for this dhikr.
      final today = _todayDateString();
      _todayCount = await _statsRepository.getTotalCountForDate(today);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the active dhikr (no hotkey target).
  Future<void> clearActiveDhikr() async {
    _activeDhikr = null;
    _activeSession = null;
    await _settingsRepository.setActiveDhikr(null);
    notifyListeners();
  }

  /// Start a new session for [dhikrId]. Call before the user begins counting
  /// via the widget toolbar or main window.
  Future<void> startSession(int dhikrId) async {
    await _sessionRepository.createSession(dhikrId, 'main_app');
    // Re-fetch so we have the full object including assigned id.
    _activeSession = await _sessionRepository.getActiveSession(dhikrId);
    notifyListeners();
  }

  /// End the current active session.
  Future<void> endSession() async {
    if (_activeSession?.id == null) return;
    await _sessionRepository.endSession(_activeSession!.id!);
    _activeSession = null;
    notifyListeners();
  }

  /// The primary counting action. Called by hotkey handler, widget toolbar tap,
  /// and main window tap. No-op when [_activeDhikr] is null.
  Future<void> increment() async {
    if (_activeDhikr == null) return;

    final dhikrId = _activeDhikr!.id!;
    final today = _todayDateString();

    // 1. Persist count to daily_summary.
    await _statsRepository.upsertDailySummary(dhikrId, today, 1);

    // 2. Update in-memory count immediately for snappy UI.
    _todayCount++;
    notifyListeners();

    // 3. Update session count if a session is active.
    if (_activeSession?.id != null) {
      await _sessionRepository.incrementCount(_activeSession!.id!);
    }

    // 4. Update streak (non-blocking, fire-and-forget).
    _updateStreak(today);

    // 5. Check achievements (non-blocking).
    _checkAchievements(dhikrId);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _todayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _updateStreak(String today) async {
    // StreakRepository.updateStreak handles all business logic internally.
    await _streakRepository.updateStreak(today);
  }

  Future<void> _checkAchievements(int dhikrId) async {
    final isFirstUnlocked =
        await _achievementRepository.isUnlocked('first_dhikr');
    if (!isFirstUnlocked) {
      await _achievementRepository.unlock('first_dhikr');
    }
  }
}
