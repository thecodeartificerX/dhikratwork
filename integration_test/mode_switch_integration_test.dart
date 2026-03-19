import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dhikratwork/app/app_locator.dart';
import 'package:dhikratwork/repositories/settings_repository.dart';
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/viewmodels/app_shell_viewmodel.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';
import 'package:dhikratwork/repositories/session_repository.dart';
import 'package:dhikratwork/repositories/stats_repository.dart';
import 'package:dhikratwork/repositories/streak_repository.dart';
import 'package:dhikratwork/repositories/achievement_repository.dart';
import 'package:dhikratwork/services/subscription_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('compact → expanded → compact mode transitions',
      (tester) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final db = DatabaseService();
    await db.open();

    final settingsRepo = SettingsRepository(db);
    final dhikrRepo = DhikrRepository(db);
    final sessionRepo = SessionRepository(db);
    final statsRepo = StatsRepository(db);
    final streakRepo = StreakRepository(db);
    final achievementRepo = AchievementRepository(db);

    final appShellVm = AppShellViewModel(settingsRepository: settingsRepo);

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

    expect(appShellVm.mode, equals(AppMode.compact));

    await appShellVm.setMode(AppMode.expanded);
    expect(appShellVm.mode, equals(AppMode.expanded));

    await appShellVm.setMode(AppMode.compact);
    expect(appShellVm.mode, equals(AppMode.compact));

    await appShellVm.saveCompactPosition(200.0, 300.0);
    final settings = await settingsRepo.getSettings();
    expect(settings.widgetPositionX, equals(200.0));
    expect(settings.widgetPositionY, equals(300.0));

    AppLocator.reset();
    await db.close();
  });
}
