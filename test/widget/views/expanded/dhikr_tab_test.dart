// test/widget/views/expanded/dhikr_tab_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/viewmodels/dhikr_library_viewmodel.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/views/expanded/dhikr_tab.dart';
import '../../../fakes/fake_dhikr_repository.dart';
import '../../../fakes/fake_settings_repository.dart';
import '../../../fakes/fake_stats_repository.dart';
import '../../../fakes/fake_streak_repository.dart';
import '../../../fakes/fake_session_repository.dart';
import '../../../fakes/fake_achievement_repository.dart';
import '../../../fakes/fake_subscription_service.dart';

Widget _buildTestApp({
  FakeDhikrRepository? dhikrRepo,
  FakeSettingsRepository? settingsRepo,
  Dhikr? activeDhikr,
  VoidCallback? onSwitchToSettings,
}) {
  dhikrRepo ??= FakeDhikrRepository();
  settingsRepo ??= FakeSettingsRepository();
  final statsRepo = FakeStatsRepository();
  final streakRepo = FakeStreakRepository();

  final counterVm = CounterViewModel(
    dhikrRepository: dhikrRepo,
    sessionRepository: FakeSessionRepository(),
    statsRepository: statsRepo,
    streakRepository: streakRepo,
    achievementRepository: FakeAchievementRepository(),
    settingsRepository: settingsRepo,
  );

  // If we want to simulate an active dhikr, set it directly via field access
  // is not possible — but FakeDhikrRepository starts with 2 dhikrs, so
  // the banner only appears if counterVm.activeDhikr is set. For tests
  // that need the banner, we rely on counterVm.setActiveDhikr being called.

  final settingsVm = SettingsViewModel(
    settingsRepository: settingsRepo,
    dhikrRepository: dhikrRepo,
    subscriptionService: FakeSubscriptionService(),
  );
  final libraryVm = DhikrLibraryViewModel(dhikrRepository: dhikrRepo);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<CounterViewModel>.value(value: counterVm),
      ChangeNotifierProvider<SettingsViewModel>.value(value: settingsVm),
      ChangeNotifierProvider<DhikrLibraryViewModel>.value(value: libraryVm),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: DhikrTab(onSwitchToSettings: onSwitchToSettings),
      ),
    ),
  );
}

void main() {
  group('DhikrTab', () {
    testWidgets('dhikr list renders after load', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // FakeDhikrRepository seeds 2 dhikrs by default.
      expect(find.text('SubhanAllah'), findsOneWidget);
      // 'Alhamdulillah' appears as both the title and the transliteration subtitle.
      expect(find.text('Alhamdulillah'), findsWidgets);
    });

    testWidgets('Add Custom button exists', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Add Custom'), findsOneWidget);
    });

    testWidgets('hotkey display shows', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // FakeSettingsRepository defaults to kDefaultHotkey = 'ctrl+shift+d'
      expect(find.textContaining('ctrl+shift+d'), findsOneWidget);
    });

    testWidgets('active dhikr banner shows when active dhikr is set',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Tap on the first dhikr to trigger selection dialog.
      await tester.tap(find.text('SubhanAllah'));
      await tester.pumpAndSettle();

      // Confirm the dialog.
      await tester.tap(find.text('Set Active'));
      await tester.pumpAndSettle();

      // The active banner should now be visible.
      expect(find.textContaining('Active:'), findsOneWidget);
    });

    testWidgets('All Dhikr header is present', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('All Dhikr'), findsOneWidget);
    });

    testWidgets('Change in Settings link shown when callback provided',
        (tester) async {
      bool switched = false;
      await tester.pumpWidget(
        _buildTestApp(onSwitchToSettings: () => switched = true),
      );
      await tester.pumpAndSettle();

      expect(find.text('Change in Settings'), findsOneWidget);
      await tester.tap(find.text('Change in Settings'));
      expect(switched, isTrue);
    });
  });
}
