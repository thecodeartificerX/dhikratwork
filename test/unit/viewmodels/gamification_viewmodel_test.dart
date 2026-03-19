// test/unit/viewmodels/gamification_viewmodel_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dhikratwork/viewmodels/gamification_viewmodel.dart';
import 'package:dhikratwork/models/streak.dart';
import '../../fakes/fake_achievement_repository.dart';
import '../../fakes/fake_streak_repository.dart';

void main() {
  late FakeAchievementRepository fakeAchievementRepo;
  late FakeStreakRepository fakeStreakRepo;
  late GamificationViewModel vm;

  setUp(() {
    fakeAchievementRepo = FakeAchievementRepository();
    fakeStreakRepo = FakeStreakRepository();
    vm = GamificationViewModel(
      achievementRepository: fakeAchievementRepo,
      streakRepository: fakeStreakRepo,
    );
  });

  group('GamificationViewModel - calculateLevel', () {
    test('0 XP is Beginner (level 0)', () {
      expect(vm.calculateLevel(0), 0);
    });

    test('99 XP is still Beginner (level 0)', () {
      expect(vm.calculateLevel(99), 0);
    });

    test('100 XP is Consistent (level 1)', () {
      expect(vm.calculateLevel(100), 1);
    });

    test('250 XP is Devoted (level 2)', () {
      expect(vm.calculateLevel(250), 2);
    });

    test('32000 XP is Muhsin (level 8, max)', () {
      expect(vm.calculateLevel(32000), 8);
    });

    test('999999 XP stays capped at Muhsin (level 8)', () {
      expect(vm.calculateLevel(999999), 8);
    });
  });

  group('GamificationViewModel - level names', () {
    test('level 0 name is Beginner', () {
      vm.totalXp = 0;
      vm.currentLevel = vm.calculateLevel(0);
      expect(vm.levelName, 'Beginner');
    });

    test('level 8 name is Muhsin', () {
      vm.totalXp = 32000;
      vm.currentLevel = vm.calculateLevel(32000);
      expect(vm.levelName, 'Muhsin');
    });
  });

  group('GamificationViewModel - xpProgress', () {
    test('at exact threshold, progress is 0.0 for next level', () {
      // 100 XP = level 1 start; next threshold is 250
      // progress = (100 - 100) / (250 - 100) = 0.0
      final progress = vm.computeXpProgress(totalXp: 100, level: 1);
      expect(progress, closeTo(0.0, 0.001));
    });

    test('halfway to next level gives ~0.5 progress', () {
      // Level 1: threshold 100, next 250; midpoint = 175
      final progress = vm.computeXpProgress(totalXp: 175, level: 1);
      expect(progress, closeTo(0.5, 0.01));
    });

    test('at max level, progress is 1.0', () {
      final progress = vm.computeXpProgress(totalXp: 99999, level: 8);
      expect(progress, 1.0);
    });
  });

  group('GamificationViewModel - checkAndUnlockAchievements', () {
    // Helper: returns the set of keys with non-null unlockedAt in the fake repo.
    Future<Set<String>> unlockedKeys() async {
      final unlocked = await fakeAchievementRepo.getUnlocked();
      return unlocked.map((a) => a.key).toSet();
    }

    test('first_dhikr unlocked when totalCount >= 1', () async {
      await vm.checkAndUnlockAchievements(totalCount: 1, streakDays: 0);
      expect(await unlockedKeys(), contains('first_dhikr'));
    });

    test('count_100 unlocked at 100 total', () async {
      await vm.checkAndUnlockAchievements(totalCount: 100, streakDays: 0);
      expect(await unlockedKeys(), contains('count_100'));
    });

    test('count_1000 unlocked at 1000 total', () async {
      await vm.checkAndUnlockAchievements(totalCount: 1000, streakDays: 0);
      expect(await unlockedKeys(), contains('count_1000'));
    });

    test('count_10000 unlocked at 10000 total', () async {
      await vm.checkAndUnlockAchievements(totalCount: 10000, streakDays: 0);
      expect(await unlockedKeys(), contains('count_10000'));
    });

    test('count_100000 unlocked at 100000 total', () async {
      await vm.checkAndUnlockAchievements(totalCount: 100000, streakDays: 0);
      expect(await unlockedKeys(), contains('count_100000'));
    });

    test('streak_3 unlocked at 3-day streak', () async {
      await vm.checkAndUnlockAchievements(totalCount: 0, streakDays: 3);
      expect(await unlockedKeys(), contains('streak_3'));
    });

    test('streak_7 unlocked at 7-day streak', () async {
      await vm.checkAndUnlockAchievements(totalCount: 0, streakDays: 7);
      expect(await unlockedKeys(), contains('streak_7'));
    });

    test('streak_30 unlocked at 30-day streak', () async {
      await vm.checkAndUnlockAchievements(totalCount: 0, streakDays: 30);
      expect(await unlockedKeys(), contains('streak_30'));
    });

    test('streak_100 unlocked at 100-day streak', () async {
      await vm.checkAndUnlockAchievements(totalCount: 0, streakDays: 100);
      expect(await unlockedKeys(), contains('streak_100'));
    });

    test('already-unlocked achievements are not re-unlocked (timestamp preserved)', () async {
      // Pre-unlock first_dhikr via the fake's unlock() method directly.
      await fakeAchievementRepo.unlock('first_dhikr');
      final firstTimestamp = (await fakeAchievementRepo.getUnlocked())
          .firstWhere((a) => a.key == 'first_dhikr')
          .unlockedAt;

      await vm.checkAndUnlockAchievements(totalCount: 5, streakDays: 0);

      final secondTimestamp = (await fakeAchievementRepo.getUnlocked())
          .firstWhere((a) => a.key == 'first_dhikr')
          .unlockedAt;
      // Phase 2B unlock() is idempotent — original timestamp is preserved.
      expect(secondTimestamp, equals(firstTimestamp));
    });

    test('all applicable achievements checked in single pass', () async {
      await vm.checkAndUnlockAchievements(totalCount: 1000, streakDays: 7);
      expect(await unlockedKeys(),
          containsAll(['first_dhikr', 'count_100', 'count_1000', 'streak_3', 'streak_7']));
    });

    test('notifyListeners called after achievements unlocked', () async {
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);
      await vm.checkAndUnlockAchievements(totalCount: 1, streakDays: 0);
      expect(notifyCount, greaterThan(0));
    });
  });

  group('GamificationViewModel - loadGamification', () {
    test('loads currentStreak and longestStreak from StreakRepository', () async {
      // Seed the fake streak directly using the Phase 2A seed() helper.
      fakeStreakRepo.seed(const Streak(
        id: 1,
        currentStreak: 5,
        longestStreak: 12,
        lastActiveDate: null,
      ));
      await vm.loadGamification();
      expect(vm.currentStreak, 5);
      expect(vm.longestStreak, 12);
    });

    test('loads achievements list from AchievementRepository.getAll()', () async {
      await vm.loadGamification();
      // FakeAchievementRepository pre-seeds from kSeedAchievements constants.
      expect(vm.achievements, isNotEmpty);
    });
  });
}
