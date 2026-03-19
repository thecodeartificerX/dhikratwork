// test/widget/views/expanded/expanded_shell_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dhikratwork/viewmodels/app_shell_viewmodel.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/viewmodels/dhikr_library_viewmodel.dart';
import 'package:dhikratwork/viewmodels/stats_viewmodel.dart';
import 'package:dhikratwork/viewmodels/gamification_viewmodel.dart';
import 'package:dhikratwork/viewmodels/goal_viewmodel.dart';
import 'package:dhikratwork/views/expanded/expanded_shell.dart';
import '../../../fakes/fake_dhikr_repository.dart';
import '../../../fakes/fake_settings_repository.dart';
import '../../../fakes/fake_stats_repository.dart';
import '../../../fakes/fake_streak_repository.dart';
import '../../../fakes/fake_session_repository.dart';
import '../../../fakes/fake_achievement_repository.dart';
import '../../../fakes/fake_goal_repository.dart';
import '../../../fakes/fake_subscription_service.dart';

Widget _buildTestApp() {
  final dhikrRepo = FakeDhikrRepository();
  final settingsRepo = FakeSettingsRepository();
  final statsRepo = FakeStatsRepository();
  final streakRepo = FakeStreakRepository();
  final achievementRepo = FakeAchievementRepository();
  final goalRepo = FakeGoalRepository();

  final appShellVm = AppShellViewModel(settingsRepository: settingsRepo);
  final counterVm = CounterViewModel(
    dhikrRepository: dhikrRepo,
    sessionRepository: FakeSessionRepository(),
    statsRepository: statsRepo,
    streakRepository: streakRepo,
    achievementRepository: achievementRepo,
    settingsRepository: settingsRepo,
  );
  final settingsVm = SettingsViewModel(
    settingsRepository: settingsRepo,
    dhikrRepository: dhikrRepo,
    subscriptionService: FakeSubscriptionService(),
  );
  final libraryVm = DhikrLibraryViewModel(dhikrRepository: dhikrRepo);
  final statsVm = StatsViewModel(
    statsRepository: statsRepo,
    streakRepository: streakRepo,
    dhikrRepository: dhikrRepo,
  );
  final gamVm = GamificationViewModel(
    achievementRepository: achievementRepo,
    streakRepository: streakRepo,
  );
  final goalVm = GoalViewModel(
    goalRepository: goalRepo,
    statsRepository: statsRepo,
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AppShellViewModel>.value(value: appShellVm),
      ChangeNotifierProvider<CounterViewModel>.value(value: counterVm),
      ChangeNotifierProvider<SettingsViewModel>.value(value: settingsVm),
      ChangeNotifierProvider<DhikrLibraryViewModel>.value(value: libraryVm),
      ChangeNotifierProvider<StatsViewModel>.value(value: statsVm),
      ChangeNotifierProvider<GamificationViewModel>.value(value: gamVm),
      ChangeNotifierProvider<GoalViewModel>.value(value: goalVm),
    ],
    child: MaterialApp(
      home: const ExpandedShell(),
    ),
  );
}

void main() {
  group('ExpandedShell', () {
    testWidgets('renders 3 tab labels: Dhikr, Stats, Settings', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Dhikr'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('title bar minimize and close buttons exist', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.minimize), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('tapping Stats tab shows period selector', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();

      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
    });

    testWidgets('title bar has collapse-to-compact button', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.compress), findsOneWidget);
    });
  });
}
