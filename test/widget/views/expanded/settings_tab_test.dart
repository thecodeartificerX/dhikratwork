// test/widget/views/expanded/settings_tab_test.dart

import 'package:dhikratwork/models/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/views/expanded/settings_tab.dart';
import '../../../fakes/fake_dhikr_repository.dart';
import '../../../fakes/fake_settings_repository.dart';
import '../../../fakes/fake_subscription_service.dart';

Widget _buildTestApp({
  FakeSettingsRepository? settingsRepo,
  bool subscribed = false,
}) {
  settingsRepo ??= FakeSettingsRepository();
  if (subscribed) {
    settingsRepo.overrideSettings(const UserSettings(
      id: 1,
      activeDhikrId: null,
      globalHotkey: 'ctrl+shift+d',
      widgetVisible: true,
      widgetPositionX: null,
      widgetPositionY: null,
      widgetDhikrIds: null,
      themeVariant: 'system',
      subscriptionStatus: 'subscribed',
      subscriptionEmail: 'test@example.com',
      lastSubscriptionPrompt: null,
      createdAt: '2024-01-01T00:00:00.000Z',
    ));
  }

  final vm = SettingsViewModel(
    settingsRepository: settingsRepo,
    dhikrRepository: FakeDhikrRepository(),
    subscriptionService: FakeSubscriptionService(),
  );

  return MaterialApp(
    home: ChangeNotifierProvider<SettingsViewModel>.value(
      value: vm,
      child: const Scaffold(body: SettingsTab()),
    ),
  );
}

void main() {
  group('SettingsTab', () {
    testWidgets('renders Global Hotkey section heading', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Global Hotkey'), findsOneWidget);
    });

    testWidgets('renders Subscription section heading', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Subscription'), findsOneWidget);
    });

    testWidgets('renders Data Export section heading', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Data Export'), findsOneWidget);
    });

    testWidgets('renders About section heading', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('hotkey string is displayed', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('ctrl+shift+d'), findsWidgets);
    });

    testWidgets('no Floating Widget section', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Floating Widget'), findsNothing);
    });

    testWidgets('Subscribe button shown when not subscribed', (tester) async {
      await tester.pumpWidget(_buildTestApp(subscribed: false));
      await tester.pumpAndSettle();

      expect(find.text('Subscribe — \$5/month'), findsOneWidget);
    });

    testWidgets('Subscribe button absent when subscribed', (tester) async {
      await tester.pumpWidget(_buildTestApp(subscribed: true));
      await tester.pumpAndSettle();

      expect(find.text('Subscribe — \$5/month'), findsNothing);
    });

    testWidgets('Export JSON and Export CSV buttons are present',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final exportJsonFinder = find.text('Export JSON');
      await tester.ensureVisible(exportJsonFinder);
      expect(exportJsonFinder, findsOneWidget);

      final exportCsvFinder = find.text('Export CSV');
      await tester.ensureVisible(exportCsvFinder);
      expect(exportCsvFinder, findsOneWidget);
    });
  });
}
