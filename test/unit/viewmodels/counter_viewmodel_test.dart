// test/unit/viewmodels/counter_viewmodel_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/models/dhikr_session.dart';
import 'package:dhikratwork/models/user_settings.dart';
import '../../fakes/fake_dhikr_repository.dart';
import '../../fakes/fake_session_repository.dart';
import '../../fakes/fake_stats_repository.dart';
import '../../fakes/fake_streak_repository.dart';
import '../../fakes/fake_achievement_repository.dart';
import '../../fakes/fake_settings_repository.dart';

void main() {
  late CounterViewModel vm;
  late FakeSessionRepository sessionRepo;
  late FakeStatsRepository statsRepo;
  late FakeStreakRepository streakRepo;
  late FakeSettingsRepository settingsRepo;

  setUp(() {
    sessionRepo = FakeSessionRepository();
    statsRepo = FakeStatsRepository();
    streakRepo = FakeStreakRepository();
    settingsRepo = FakeSettingsRepository();

    vm = CounterViewModel(
      dhikrRepository: FakeDhikrRepository(),
      sessionRepository: sessionRepo,
      statsRepository: statsRepo,
      streakRepository: streakRepo,
      achievementRepository: FakeAchievementRepository(),
      settingsRepository: settingsRepo,
    );
  });

  test('initial state: activeDhikr is null, todayCount is 0', () {
    expect(vm.activeDhikr, isNull);
    expect(vm.todayCount, equals(0));
    expect(vm.isLoading, isFalse);
  });

  test('setActiveDhikr loads dhikr by id and notifies listeners', () async {
    int notifyCount = 0;
    vm.addListener(() => notifyCount++);

    await vm.setActiveDhikr(1);

    expect(vm.activeDhikr, isNotNull);
    expect(vm.activeDhikr!.id, equals(1));
    expect(notifyCount, greaterThan(0));
  });

  test('increment increases todayCount and notifies', () async {
    await vm.setActiveDhikr(1);
    final before = vm.todayCount;

    await vm.increment();

    expect(vm.todayCount, equals(before + 1));
  });

  test('increment without active dhikr is a no-op', () async {
    await vm.increment(); // activeDhikr is null
    expect(vm.todayCount, equals(0));
  });

  test('startSession creates a session in repository', () async {
    await vm.setActiveDhikr(1);
    await vm.startSession(1);

    final sessions = await sessionRepo.getSessionsByDhikr(1);
    expect(sessions, isNotEmpty);
    expect(sessions.first.dhikrId, equals(1));
  });

  test('endSession marks session ended', () async {
    await vm.setActiveDhikr(1);
    await vm.startSession(1);
    await vm.endSession();

    final sessions = await sessionRepo.getSessionsByDhikr(1);
    final session = sessions.first;
    expect(session.endedAt, isNotNull);
  });

  test('increment updates daily stats via statsRepository', () async {
    await vm.setActiveDhikr(1);
    await vm.increment();

    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final total = await statsRepo.getTotalCountForDate(dateStr);
    expect(total, equals(1));
  });

  test('incrementActiveDhikr increments sessionCount', () async {
    settingsRepo.seed(const UserSettings(
      activeDhikrId: 1,
      createdAt: '2026-01-01T00:00:00',
    ));

    expect(vm.sessionCount, equals(0));
    await vm.incrementActiveDhikr(source: 'hotkey');
    expect(vm.sessionCount, equals(1));
    await vm.incrementActiveDhikr(source: 'hotkey');
    expect(vm.sessionCount, equals(2));
  });

  test('loadActiveSession resumes open session and restores sessionCount',
      () async {
    settingsRepo.seed(const UserSettings(
      activeDhikrId: 1,
      createdAt: '2026-01-01T00:00:00',
    ));
    // Pre-seed an open session with count = 5.
    sessionRepo.seed([
      DhikrSession(
        id: 10,
        dhikrId: 1,
        count: 5,
        startedAt: DateTime.now().toIso8601String(),
        source: 'main_app',
      ),
    ]);

    await vm.loadActiveSession();

    expect(vm.activeDhikr, isNotNull);
    expect(vm.activeDhikr!.id, equals(1));
    expect(vm.activeSession, isNotNull);
    expect(vm.sessionCount, equals(5));
  });

  test('resetSessionCount ends current and starts new session', () async {
    await vm.setActiveDhikr(1);
    await vm.startSession(1);
    // Simulate some counts in the current session.
    await vm.increment();
    await vm.increment();
    expect(vm.sessionCount, equals(0)); // increment() does not touch sessionCount

    settingsRepo.seed(const UserSettings(
      activeDhikrId: 1,
      createdAt: '2026-01-01T00:00:00',
    ));
    await vm.incrementActiveDhikr(source: 'main_app');
    expect(vm.sessionCount, equals(1));

    await vm.resetSessionCount();

    expect(vm.sessionCount, equals(0));
    expect(vm.activeSession, isNotNull);
    // The old session should now be ended.
    final sessions = await sessionRepo.getSessionsByDhikr(1);
    final ended = sessions.where((s) => s.endedAt != null).toList();
    expect(ended, isNotEmpty);
  });

  test('setActiveDhikr loads per-dhikr today count, not global', () async {
    // Seed counts: dhikr 1 has 33 today, dhikr 2 has 11 today.
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await statsRepo.upsertDailySummary(1, dateStr, 33);
    await statsRepo.upsertDailySummary(2, dateStr, 11);

    await vm.setActiveDhikr(1);
    expect(vm.todayCount, equals(33)); // Should be 33, not 44

    await vm.setActiveDhikr(2);
    expect(vm.todayCount, equals(11)); // Should be 11, not 44
  });

  test('setActiveDhikr resets session count for new dhikr', () async {
    settingsRepo.seed(const UserSettings(
      activeDhikrId: 1,
      createdAt: '2026-01-01T00:00:00',
    ));

    // Increment dhikr 1 session count to 3.
    await vm.incrementActiveDhikr(source: 'hotkey');
    await vm.incrementActiveDhikr(source: 'hotkey');
    await vm.incrementActiveDhikr(source: 'hotkey');
    expect(vm.sessionCount, equals(3));

    // Switch to dhikr 2 — session count should reset to 0.
    await vm.setActiveDhikr(2);
    expect(vm.sessionCount, equals(0));
  });

  test('loadActiveSession loads per-dhikr today count, not global', () async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    // Seed counts: dhikr 1 has 20, dhikr 2 has 30.
    await statsRepo.upsertDailySummary(1, dateStr, 20);
    await statsRepo.upsertDailySummary(2, dateStr, 30);

    settingsRepo.seed(const UserSettings(
      activeDhikrId: 1,
      createdAt: '2026-01-01T00:00:00',
    ));

    await vm.loadActiveSession();

    // Should be 20 (dhikr 1 only), not 50 (global).
    expect(vm.todayCount, equals(20));
  });

  test('resetTodayCount resets todayCount to 0', () async {
    await vm.setActiveDhikr(1);
    await vm.increment();
    await vm.increment();
    expect(vm.todayCount, equals(2));

    await vm.resetTodayCount();

    expect(vm.todayCount, equals(0));
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final total = await statsRepo.getTotalCountForDate(dateStr);
    expect(total, equals(0));
  });
}
