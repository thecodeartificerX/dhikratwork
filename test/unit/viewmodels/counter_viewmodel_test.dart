// test/unit/viewmodels/counter_viewmodel_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
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

  setUp(() {
    sessionRepo = FakeSessionRepository();
    statsRepo = FakeStatsRepository();
    streakRepo = FakeStreakRepository();

    vm = CounterViewModel(
      dhikrRepository: FakeDhikrRepository(),
      sessionRepository: sessionRepo,
      statsRepository: statsRepo,
      streakRepository: streakRepo,
      achievementRepository: FakeAchievementRepository(),
      settingsRepository: FakeSettingsRepository(),
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
}
