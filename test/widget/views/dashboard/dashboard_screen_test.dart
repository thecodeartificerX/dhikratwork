// test/widget/views/dashboard/dashboard_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dhikratwork/viewmodels/dashboard_viewmodel.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/views/dashboard/dashboard_screen.dart';
import 'package:dhikratwork/views/shared/dhikr_counter_tile.dart';
import '../../../fakes/fake_dhikr_repository.dart';
import '../../../fakes/fake_stats_repository.dart';
import '../../../fakes/fake_streak_repository.dart';
import '../../../fakes/fake_settings_repository.dart';
import '../../../fakes/fake_session_repository.dart';
import '../../../fakes/fake_achievement_repository.dart';

Widget _buildTestApp() {
  final dhikrRepo = FakeDhikrRepository();
  final statsRepo = FakeStatsRepository();
  final streakRepo = FakeStreakRepository();
  final settingsRepo = FakeSettingsRepository();

  final dashboardVm = DashboardViewModel(
    dhikrRepository: dhikrRepo,
    statsRepository: statsRepo,
    streakRepository: streakRepo,
    settingsRepository: settingsRepo,
  );
  final counterVm = CounterViewModel(
    dhikrRepository: dhikrRepo,
    sessionRepository: FakeSessionRepository(),
    statsRepository: statsRepo,
    streakRepository: streakRepo,
    achievementRepository: FakeAchievementRepository(),
    settingsRepository: settingsRepo,
  );

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/library', builder: (context, state) => const Scaffold()),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: dashboardVm),
      ChangeNotifierProvider.value(value: counterVm),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('renders loading indicator initially', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    // On first pump before postFrameCallback fires.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders stat cards after load', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text("Today's Total"), findsOneWidget);
    expect(find.text('Day Streak'), findsOneWidget);
  });

  testWidgets('renders progress ring', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Daily Goal Progress'), findsOneWidget);
  });

  testWidgets('renders quick-access grid tiles', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    // FakeDhikrRepository has 2 dhikrs.
    expect(find.byType(DhikrCounterTile), findsNWidgets(2));
  });
}
