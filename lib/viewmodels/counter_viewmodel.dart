// lib/viewmodels/counter_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/models/dhikr_session.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';
import 'package:dhikratwork/utils/constants.dart';
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

  int _sessionCount = 0;
  int get sessionCount => _sessionCount;

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
    _sessionCount = 0;
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

  /// Increments the active dhikr. Called by:
  /// - HotkeyService (source: 'hotkey')
  /// - FloatingToolbar tap (source: 'widget')
  /// - Dashboard tap (source: 'main_app')
  ///
  /// Uses Phase 2A SessionRepository API: getActiveSession + createSession +
  /// incrementCount(sessionId). incrementCount takes a session id, not a dhikr id.
  Future<void> incrementActiveDhikr({required String source}) async {
    final settings = await _settingsRepository.getSettings();
    final activeDhikrId = settings.activeDhikrId;

    if (activeDhikrId == null) return; // No active dhikr set yet.

    // Get or create the active session for this dhikr, then increment.
    var session = await _sessionRepository.getActiveSession(activeDhikrId);
    session ??=
        await _sessionRepository.createSession(activeDhikrId, source);
    await _sessionRepository.incrementCount(session.id!);

    // Persist to daily_summary for stats.
    final today = _todayDateString();
    await _statsRepository.upsertDailySummary(activeDhikrId, today, 1);

    // Update in-memory count.
    _todayCount++;
    _sessionCount++;
    notifyListeners();

    // Update streak (non-blocking).
    _updateStreak(today);

    // Check achievements (non-blocking).
    _checkAchievements(activeDhikrId);
  }

  /// Restores active dhikr and session state from DB on app startup.
  /// If an open session exists, resumes it with the persisted count.
  /// If no open session but an active dhikr is set, starts a fresh session.
  Future<void> loadActiveSession() async {
    final settings = await _settingsRepository.getSettings();
    final activeDhikrId = settings.activeDhikrId;
    if (activeDhikrId == null) return;

    _activeDhikr = await _dhikrRepository.getById(activeDhikrId);
    if (_activeDhikr == null) return;

    final openSession = await _sessionRepository.getActiveSession(activeDhikrId);
    if (openSession != null) {
      _activeSession = openSession;
      _sessionCount = openSession.count;
    } else {
      _sessionCount = 0;
      await _sessionRepository.createSession(activeDhikrId, kSourceMainApp);
      _activeSession = await _sessionRepository.getActiveSession(activeDhikrId);
    }

    final today = _todayDateString();
    _todayCount = await _statsRepository.getTotalCountForDate(today);
    notifyListeners();
  }

  /// Ends the current session and starts a fresh one for the same dhikr.
  Future<void> resetSessionCount() async {
    if (_activeDhikr?.id == null) return;
    final dhikrId = _activeDhikr!.id!;

    if (_activeSession?.id != null) {
      await _sessionRepository.endSession(_activeSession!.id!);
    }

    _sessionCount = 0;
    await _sessionRepository.createSession(dhikrId, kSourceMainApp);
    _activeSession = await _sessionRepository.getActiveSession(dhikrId);
    notifyListeners();
  }

  /// Resets the daily_summary total for the active dhikr to 0 for today.
  Future<void> resetTodayCount() async {
    if (_activeDhikr?.id == null) return;
    final dhikrId = _activeDhikr!.id!;
    final today = _todayDateString();

    await _statsRepository.resetDailySummary(dhikrId, today);
    _todayCount = 0;
    notifyListeners();
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
