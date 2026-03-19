import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dhikratwork/app/app_locator.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';
import 'package:dhikratwork/repositories/session_repository.dart';
import 'package:dhikratwork/repositories/settings_repository.dart';
import 'package:dhikratwork/repositories/stats_repository.dart';
import 'package:dhikratwork/repositories/streak_repository.dart';
import 'package:dhikratwork/repositories/achievement_repository.dart';
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/services/subscription_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hotkey increment updates CounterViewModel counts',
      (tester) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final db = DatabaseService();
    await db.open();

    final dhikrRepo = DhikrRepository(db);
    final sessionRepo = SessionRepository(db);
    final settingsRepo = SettingsRepository(db);
    final statsRepo = StatsRepository(db);
    final streakRepo = StreakRepository(db);
    final achievementRepo = AchievementRepository(db);

    final counterVm = CounterViewModel(
      dhikrRepository: dhikrRepo,
      sessionRepository: sessionRepo,
      statsRepository: statsRepo,
      streakRepository: streakRepo,
      achievementRepository: achievementRepo,
      settingsRepository: settingsRepo,
    );

    final settingsVm = SettingsViewModel(
      settingsRepository: settingsRepo,
      dhikrRepository: dhikrRepo,
      subscriptionService: NoOpSubscriptionService(),
    );

    AppLocator.initialize(
      counterViewModel: counterVm,
      settingsViewModel: settingsVm,
    );

    await counterVm.loadActiveSession();
    await tester.pump();

    if (counterVm.activeDhikr == null) {
      final allDhikr = await dhikrRepo.getAll();
      if (allDhikr.isEmpty) {
        AppLocator.reset();
        await db.close();
        return;
      }
      await counterVm.setActiveDhikr(allDhikr.first.id!);
      await counterVm.startSession(allDhikr.first.id!);
      await tester.pump();
    }

    final countBefore = counterVm.todayCount;

    await counterVm.incrementActiveDhikr(source: 'hotkey');
    await tester.pump();

    expect(counterVm.todayCount, equals(countBefore + 1));

    AppLocator.reset();
    await db.close();
  });
}
