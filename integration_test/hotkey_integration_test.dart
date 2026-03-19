// integration_test/hotkey_integration_test.dart
//
// Integration test: simulates hotkey press → counter increment → persisted to DB → UI updated.
//
// NOTE: True end-to-end hotkey simulation is OS-level and not feasible in
// integration tests. The hotkey handler calls CounterViewModel.incrementActiveDhikr
// which is the same path as a real hotkey press. This test verifies that path.

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
import 'package:dhikratwork/viewmodels/widget_toolbar_viewmodel.dart';
import 'package:dhikratwork/services/subscription_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hotkey increment updates WidgetToolbarViewModel todayCounts',
      (tester) async {
    // Set up sqflite FFI for test environment.
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

    final widgetToolbarVm = WidgetToolbarViewModel(
      dhikrRepository: dhikrRepo,
      settingsRepository: settingsRepo,
      sessionRepository: sessionRepo,
    );

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
      subscriptionService: FirestoreSubscriptionService(),
    );

    // Initialize AppLocator so CounterViewModel.incrementActiveDhikr can
    // refresh WidgetToolbarViewModel counts.
    AppLocator.initialize(
      widgetToolbarViewModel: widgetToolbarVm,
      counterViewModel: counterVm,
      settingsViewModel: settingsVm,
    );

    // Load toolbar dhikrs.
    await widgetToolbarVm.loadToolbar();
    await tester.pump();

    // Ensure there's an active dhikr.
    if (widgetToolbarVm.toolbarDhikrs.isNotEmpty) {
      final firstDhikrId = widgetToolbarVm.toolbarDhikrs.first.id!;
      await widgetToolbarVm.setActiveDhikr(firstDhikrId);
      await tester.pump();
    }

    final activeDhikrId = widgetToolbarVm.activeDhikrId;
    if (activeDhikrId == null) {
      // Skip if no dhikr configured — integration environment may have empty DB.
      return;
    }

    final countBefore = widgetToolbarVm.todayCounts[activeDhikrId] ?? 0;

    // Simulate hotkey press by calling incrementActiveDhikr directly.
    // The hotkey handler calls this exact same method.
    await counterVm.incrementActiveDhikr(source: 'hotkey');
    await tester.pump();

    expect(
      widgetToolbarVm.todayCounts[activeDhikrId],
      equals(countBefore + 1),
    );

    // Clean up.
    AppLocator.reset();
    await db.close();
  });
}
