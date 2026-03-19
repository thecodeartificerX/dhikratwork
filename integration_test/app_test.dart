// integration_test/app_test.dart
//
// Integration tests for critical app paths.
//
// These tests use a real DatabaseService backed by an in-memory SQLite database
// via sqflite_common_ffi. All tests exercise the ViewModel and repository layers
// against a real (in-memory) DB — no mock objects.
//
// Run with: flutter test integration_test/app_test.dart -d windows

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/models/goal.dart';
import 'package:dhikratwork/repositories/achievement_repository.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';
import 'package:dhikratwork/repositories/goal_repository.dart';
import 'package:dhikratwork/repositories/session_repository.dart';
import 'package:dhikratwork/repositories/settings_repository.dart';
import 'package:dhikratwork/repositories/stats_repository.dart';
import 'package:dhikratwork/repositories/streak_repository.dart';
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/utils/constants.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/dhikr_library_viewmodel.dart';
import 'package:dhikratwork/viewmodels/gamification_viewmodel.dart';

/// Bootstraps an in-memory SQLite database for integration tests.
/// Uses sqflite_common_ffi so tests run on Windows/macOS/Linux desktop.
Future<DatabaseService> _buildInMemoryDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final service = DatabaseService(dbPath: inMemoryDatabasePath);
  await service.open();
  return service;
}

/// Builds a minimal custom (non-preloaded) [Dhikr] for use in library tests.
Dhikr _customDhikr(String name) {
  return Dhikr(
    name: name,
    arabicText: 'ت',
    transliteration: name,
    translation: name,
    category: kCategoryGeneralTasbih,
    isPreloaded: false,
    sortOrder: 99,
    createdAt: DateTime.now().toIso8601String(),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService dbService;
  late DhikrRepository dhikrRepo;
  late SessionRepository sessionRepo;
  late StatsRepository statsRepo;
  late GoalRepository goalRepo;
  late AchievementRepository achievementRepo;
  late StreakRepository streakRepo;
  late SettingsRepository settingsRepo;

  setUp(() async {
    dbService = await _buildInMemoryDb();
    dhikrRepo = DhikrRepository(dbService);
    sessionRepo = SessionRepository(dbService);
    statsRepo = StatsRepository(dbService);
    goalRepo = GoalRepository(dbService);
    achievementRepo = AchievementRepository(dbService);
    streakRepo = StreakRepository(dbService);
    settingsRepo = SettingsRepository(dbService);
  });

  tearDown(() async {
    await dbService.close();
  });

  // ---------------------------------------------------------------------------
  // Critical Path 1: Counter increment → persisted to DB → ViewModel updated
  // ---------------------------------------------------------------------------
  group('Critical Path: counter increment via hotkey', () {
    test(
      'setActiveDhikr loads dhikr and increment() persists to daily_summary',
      () async {
        final counterVm = CounterViewModel(
          dhikrRepository: dhikrRepo,
          sessionRepository: sessionRepo,
          statsRepository: statsRepo,
          streakRepository: streakRepo,
          achievementRepository: achievementRepo,
          settingsRepository: settingsRepo,
        );

        // dhikrId 1 is seeded (SubhanAllah) by DatabaseService._seedPreloadedDhikr().
        await counterVm.setActiveDhikr(1);
        expect(counterVm.activeDhikr, isNotNull);
        expect(counterVm.activeDhikr!.id, equals(1));

        // Initial counter value is 0 for a fresh in-memory DB.
        expect(counterVm.todayCount, equals(0));

        // Simulate the same path hotkey_manager calls (increment()).
        await counterVm.increment();

        // In-memory count updated immediately.
        expect(counterVm.todayCount, equals(1));

        // Verify persisted to DB via stats repository.
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final totalCount = await statsRepo.getTotalCountForDate(today);
        expect(totalCount, greaterThanOrEqualTo(1));
      },
    );

    test(
      'incrementActiveDhikr creates a session and increments count',
      () async {
        // Set active dhikr in settings so incrementActiveDhikr picks it up.
        await settingsRepo.setActiveDhikr(1);

        final counterVm = CounterViewModel(
          dhikrRepository: dhikrRepo,
          sessionRepository: sessionRepo,
          statsRepository: statsRepo,
          streakRepository: streakRepo,
          achievementRepository: achievementRepo,
          settingsRepository: settingsRepo,
        );

        await counterVm.incrementActiveDhikr(source: 'hotkey');

        // In-memory counter updated.
        expect(counterVm.todayCount, equals(1));

        // A session was created and incremented for dhikr 1.
        final todayCount = await sessionRepo.getTodaySessionCount(1);
        expect(todayCount, greaterThanOrEqualTo(1));
      },
    );

    test(
      'multiple increments accumulate correctly',
      () async {
        final counterVm = CounterViewModel(
          dhikrRepository: dhikrRepo,
          sessionRepository: sessionRepo,
          statsRepository: statsRepo,
          streakRepository: streakRepo,
          achievementRepository: achievementRepo,
          settingsRepository: settingsRepo,
        );

        await counterVm.setActiveDhikr(1);

        for (int i = 0; i < 33; i++) {
          await counterVm.increment();
        }

        expect(counterVm.todayCount, equals(33));

        final today = DateTime.now().toIso8601String().substring(0, 10);
        final dbCount = await statsRepo.getTotalCountForDate(today);
        expect(dbCount, equals(33));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Critical Path 2: Add custom dhikr → appears in library → set as active
  // ---------------------------------------------------------------------------
  group('Critical Path: custom dhikr lifecycle', () {
    test(
      'adding a custom dhikr makes it appear in the library list',
      () async {
        final libraryVm = DhikrLibraryViewModel(dhikrRepository: dhikrRepo);

        await libraryVm.loadAll();
        final initialCount = libraryVm.dhikrList.length;

        await libraryVm.addDhikr(_customDhikr('Ya-Salam'));

        // ViewModel refreshes after add.
        expect(libraryVm.dhikrList.length, equals(initialCount + 1));
        expect(
          libraryVm.dhikrList.any((d) => d.name == 'Ya-Salam'),
          isTrue,
        );

        // Verify persisted to DB.
        final allDhikr = await dhikrRepo.getAll();
        expect(allDhikr.any((d) => d.name == 'Ya-Salam'), isTrue);
      },
    );

    test(
      'custom dhikr can be set as the active dhikr on CounterViewModel',
      () async {
        final libraryVm = DhikrLibraryViewModel(dhikrRepository: dhikrRepo);
        await libraryVm.addDhikr(_customDhikr('Astaghfirullah'));
        await libraryVm.loadAll();

        final customDhikr =
            libraryVm.dhikrList.firstWhere((d) => d.name == 'Astaghfirullah');
        expect(customDhikr.id, isNotNull);

        final counterVm = CounterViewModel(
          dhikrRepository: dhikrRepo,
          sessionRepository: sessionRepo,
          statsRepository: statsRepo,
          streakRepository: streakRepo,
          achievementRepository: achievementRepo,
          settingsRepository: settingsRepo,
        );

        await counterVm.setActiveDhikr(customDhikr.id!);
        expect(counterVm.activeDhikr?.name, equals('Astaghfirullah'));
      },
    );

    test(
      'custom dhikr can be deleted from the library',
      () async {
        final libraryVm = DhikrLibraryViewModel(dhikrRepository: dhikrRepo);
        await libraryVm.addDhikr(_customDhikr('ToDelete'));
        await libraryVm.loadAll();

        final toDelete =
            libraryVm.dhikrList.firstWhere((d) => d.name == 'ToDelete');

        await libraryVm.deleteDhikr(toDelete.id!);

        expect(
          libraryVm.dhikrList.any((d) => d.name == 'ToDelete'),
          isFalse,
        );
      },
    );

    // category filter test removed: filterByCategory/filteredList were removed
    // from DhikrLibraryViewModel in Phase 1.
  });

  // ---------------------------------------------------------------------------
  // Critical Path 3: Goal completion triggers gamification
  // ---------------------------------------------------------------------------
  group('Critical Path: goal completion triggers gamification', () {
    test(
      'completing a goal to targetCount=1 unlocks first_dhikr achievement',
      () async {
        // Pre-seed a goal with target = 1 so a single increment completes it.
        await goalRepo.add(Goal(
          dhikrId: 1,
          targetCount: 1,
          period: kPeriodDaily,
          isActive: true,
          createdAt: DateTime.now().toIso8601String(),
        ));

        final goals = await goalRepo.getActiveGoals();
        expect(goals.isNotEmpty, isTrue);

        // One increment via CounterViewModel.
        final counterVm = CounterViewModel(
          dhikrRepository: dhikrRepo,
          sessionRepository: sessionRepo,
          statsRepository: statsRepo,
          streakRepository: streakRepo,
          achievementRepository: achievementRepo,
          settingsRepository: settingsRepo,
        );
        await counterVm.setActiveDhikr(1);
        await counterVm.increment();

        // GamificationViewModel checks achievements and awards XP.
        final gamificationVm = GamificationViewModel(
          achievementRepository: achievementRepo,
          streakRepository: streakRepo,
        );

        await gamificationVm.checkAndUnlockAchievements(
          totalCount: 1,
          streakDays: 1,
        );

        // XP = totalCount (1 XP per press).
        expect(gamificationVm.totalXp, equals(1));

        // first_dhikr achievement unlocked at totalCount >= 1.
        final unlockedAchievements = await achievementRepo.getUnlocked();
        expect(
          unlockedAchievements.any((a) => a.key == kAchFirstDhikr),
          isTrue,
        );
      },
    );

    test(
      'XP and level are computed correctly for 100 presses',
      () async {
        final gamificationVm = GamificationViewModel(
          achievementRepository: achievementRepo,
          streakRepository: streakRepo,
        );

        await gamificationVm.checkAndUnlockAchievements(
          totalCount: 100,
          streakDays: 0,
        );

        expect(gamificationVm.totalXp, equals(100));
        // 100 presses hits the level-1 threshold (Consistent).
        expect(gamificationVm.currentLevel, greaterThan(0));
        expect(gamificationVm.levelName, isNotEmpty);

        // count_100 achievement unlocked.
        final unlockedAchievements = await achievementRepo.getUnlocked();
        expect(
          unlockedAchievements.any((a) => a.key == kAchCount100),
          isTrue,
        );
      },
    );

    test(
      'checkAndUnlockAchievements is idempotent — unlocking twice preserves timestamp',
      () async {
        final gamificationVm = GamificationViewModel(
          achievementRepository: achievementRepo,
          streakRepository: streakRepo,
        );

        await gamificationVm.checkAndUnlockAchievements(
          totalCount: 1,
          streakDays: 0,
        );

        final firstUnlockedAt = (await achievementRepo.getUnlocked())
            .firstWhere((a) => a.key == kAchFirstDhikr)
            .unlockedAt;

        // Call again — should not overwrite timestamp.
        await gamificationVm.checkAndUnlockAchievements(
          totalCount: 1,
          streakDays: 0,
        );

        final secondUnlockedAt = (await achievementRepo.getUnlocked())
            .firstWhere((a) => a.key == kAchFirstDhikr)
            .unlockedAt;

        expect(firstUnlockedAt, equals(secondUnlockedAt));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Critical Path 4: Streak tracking — consecutive-day completion
  // ---------------------------------------------------------------------------
  group('Critical Path: streak tracking', () {
    test(
      'completing dhikr on consecutive days increments the streak counter',
      () async {
        await streakRepo.updateStreak('2026-03-18');
        await streakRepo.updateStreak('2026-03-19');

        final streak = await streakRepo.getStreak();
        expect(streak.currentStreak, equals(2));
        expect(streak.longestStreak, equals(2));
        expect(streak.lastActiveDate, equals('2026-03-19'));
      },
    );

    test(
      'missing a day resets streak to 1 on the next completion',
      () async {
        await streakRepo.updateStreak('2026-03-17');

        // Skip day 2 — gap of two days.
        await streakRepo.updateStreak('2026-03-19');

        final streak = await streakRepo.getStreak();
        expect(streak.currentStreak, equals(1));
        // longestStreak retains the historical best.
        expect(streak.longestStreak, equals(1));
      },
    );

    test(
      'calling updateStreak twice on the same day is a no-op',
      () async {
        await streakRepo.updateStreak('2026-03-19');
        await streakRepo.updateStreak('2026-03-19');

        final streak = await streakRepo.getStreak();
        expect(streak.currentStreak, equals(1));
      },
    );

    test(
      'longestStreak is preserved after streak reset',
      () async {
        // Build a 3-day streak.
        await streakRepo.updateStreak('2026-03-17');
        await streakRepo.updateStreak('2026-03-18');
        await streakRepo.updateStreak('2026-03-19');

        // Break streak — skip two days.
        await streakRepo.updateStreak('2026-03-22');

        final streak = await streakRepo.getStreak();
        expect(streak.currentStreak, equals(1));
        // longestStreak remembers the 3-day best.
        expect(streak.longestStreak, equals(3));
      },
    );

    test(
      'streak achievement unlocked after 3 consecutive days',
      () async {
        final gamificationVm = GamificationViewModel(
          achievementRepository: achievementRepo,
          streakRepository: streakRepo,
        );

        await streakRepo.updateStreak('2026-03-17');
        await streakRepo.updateStreak('2026-03-18');
        await streakRepo.updateStreak('2026-03-19');

        final streak = await streakRepo.getStreak();

        await gamificationVm.checkAndUnlockAchievements(
          totalCount: 3,
          streakDays: streak.currentStreak,
        );

        final unlocked = await achievementRepo.getUnlocked();
        expect(
          unlocked.any((a) => a.key == kAchStreak3),
          isTrue,
        );
      },
    );
  });
}
