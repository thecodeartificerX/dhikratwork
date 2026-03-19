// test/widget/views/compact/compact_counter_bar_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/viewmodels/app_shell_viewmodel.dart';
import 'package:dhikratwork/views/compact/compact_counter_bar.dart';
import '../../../fakes/fake_dhikr_repository.dart';
import '../../../fakes/fake_session_repository.dart';
import '../../../fakes/fake_stats_repository.dart';
import '../../../fakes/fake_streak_repository.dart';
import '../../../fakes/fake_achievement_repository.dart';
import '../../../fakes/fake_settings_repository.dart';
import '../../../fakes/fake_subscription_service.dart';

Widget _buildTestApp({
  required CounterViewModel counterVm,
  required SettingsViewModel settingsVm,
  required AppShellViewModel appShellVm,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<CounterViewModel>.value(value: counterVm),
      ChangeNotifierProvider<SettingsViewModel>.value(value: settingsVm),
      ChangeNotifierProvider<AppShellViewModel>.value(value: appShellVm),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 600,
          child: CompactCounterBar(),
        ),
      ),
    ),
  );
}

void main() {
  late FakeDhikrRepository dhikrRepo;
  late FakeSessionRepository sessionRepo;
  late FakeStatsRepository statsRepo;
  late FakeStreakRepository streakRepo;
  late FakeAchievementRepository achievementRepo;
  late FakeSettingsRepository settingsRepo;
  late CounterViewModel counterVm;
  late SettingsViewModel settingsVm;
  late AppShellViewModel appShellVm;

  setUp(() {
    dhikrRepo = FakeDhikrRepository();
    sessionRepo = FakeSessionRepository();
    statsRepo = FakeStatsRepository();
    streakRepo = FakeStreakRepository();
    achievementRepo = FakeAchievementRepository();
    settingsRepo = FakeSettingsRepository();

    counterVm = CounterViewModel(
      dhikrRepository: dhikrRepo,
      sessionRepository: sessionRepo,
      statsRepository: statsRepo,
      streakRepository: streakRepo,
      achievementRepository: achievementRepo,
      settingsRepository: settingsRepo,
    );

    settingsVm = SettingsViewModel(
      settingsRepository: settingsRepo,
      dhikrRepository: dhikrRepo,
      subscriptionService: FakeSubscriptionService(),
    );

    appShellVm = AppShellViewModel(settingsRepository: settingsRepo);
  });

  testWidgets('shows "No dhikr selected" when no active dhikr', (tester) async {
    // No active dhikr is the default state.
    await tester.pumpWidget(
      _buildTestApp(
        counterVm: counterVm,
        settingsVm: settingsVm,
        appShellVm: appShellVm,
      ),
    );
    await tester.pump();

    expect(find.text('No dhikr selected'), findsOneWidget);
  });

  testWidgets('shows expand button in no-active-dhikr state', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        counterVm: counterVm,
        settingsVm: settingsVm,
        appShellVm: appShellVm,
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.open_in_full), findsOneWidget);
  });

  testWidgets('shows Arabic text when active dhikr is set', (tester) async {
    // Set an active dhikr (id: 1 = SubhanAllah in FakeDhikrRepository).
    await counterVm.setActiveDhikr(1);

    await tester.pumpWidget(
      _buildTestApp(
        counterVm: counterVm,
        settingsVm: settingsVm,
        appShellVm: appShellVm,
      ),
    );
    await tester.pump();

    // Arabic text for SubhanAllah.
    expect(find.text('سُبْحَانَ اللَّهِ'), findsOneWidget);
  });

  testWidgets('shows transliteration when active dhikr is set', (tester) async {
    await counterVm.setActiveDhikr(1);

    await tester.pumpWidget(
      _buildTestApp(
        counterVm: counterVm,
        settingsVm: settingsVm,
        appShellVm: appShellVm,
      ),
    );
    await tester.pump();

    expect(find.text('Subhanallah'), findsOneWidget);
  });

  testWidgets('shows Session and Today count labels when active dhikr is set',
      (tester) async {
    await counterVm.setActiveDhikr(1);

    await tester.pumpWidget(
      _buildTestApp(
        counterVm: counterVm,
        settingsVm: settingsVm,
        appShellVm: appShellVm,
      ),
    );
    await tester.pump();

    expect(find.text('Session'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('shows hotkey badge text when active dhikr is set',
      (tester) async {
    await counterVm.setActiveDhikr(1);

    await tester.pumpWidget(
      _buildTestApp(
        counterVm: counterVm,
        settingsVm: settingsVm,
        appShellVm: appShellVm,
      ),
    );
    await tester.pump();

    // Default hotkey from FakeSettingsRepository is 'ctrl+shift+d'.
    expect(find.text('ctrl+shift+d'), findsOneWidget);
  });

  testWidgets('shows expand button (Icons.open_in_full) when active dhikr is set',
      (tester) async {
    await counterVm.setActiveDhikr(1);

    await tester.pumpWidget(
      _buildTestApp(
        counterVm: counterVm,
        settingsVm: settingsVm,
        appShellVm: appShellVm,
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.open_in_full), findsOneWidget);
  });

  testWidgets('tapping expand button calls setMode(AppMode.expanded)',
      (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        counterVm: counterVm,
        settingsVm: settingsVm,
        appShellVm: appShellVm,
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pump();

    expect(appShellVm.mode, equals(AppMode.expanded));
  });
}
