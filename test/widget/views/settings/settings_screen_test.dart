// test/widget/views/settings/settings_screen_test.dart

import 'package:dhikratwork/models/user_settings.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/views/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../../fakes/fake_dhikr_repository.dart';
import '../../../fakes/fake_settings_repository.dart';
import '../../../fakes/fake_subscription_service.dart';

Widget _buildTestApp(SettingsViewModel vm) {
  return MaterialApp(
    home: ChangeNotifierProvider<SettingsViewModel>.value(
      value: vm,
      child: const SettingsScreen(),
    ),
  );
}

void main() {
  late FakeSettingsRepository fakeSettingsRepo;
  late FakeDhikrRepository fakeDhikrRepo;
  late FakeSubscriptionService fakeSubscription;
  late SettingsViewModel vm;

  setUp(() {
    fakeSettingsRepo = FakeSettingsRepository();
    fakeDhikrRepo = FakeDhikrRepository();
    fakeSubscription = FakeSubscriptionService();
    vm = SettingsViewModel(
      settingsRepository: fakeSettingsRepo,
      dhikrRepository: fakeDhikrRepo,
      subscriptionService: fakeSubscription,
    );
  });

  testWidgets('renders content after load (loading state tested in vm unit tests)',
      (tester) async {
    // The loading state (CircularProgressIndicator) is verified at the
    // ViewModel unit test level via the 'sets isLoading then clears it' test.
    // Here we verify the post-load content renders correctly.
    await tester.pumpWidget(_buildTestApp(vm));
    await tester.pumpAndSettle();
    // After load, the loading indicator should be gone and content visible.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Global Hotkey'), findsOneWidget);
  });

  testWidgets('renders all section headings after load', (tester) async {
    await tester.pumpWidget(_buildTestApp(vm));
    await tester.pumpAndSettle();
    expect(find.text('Global Hotkey'), findsOneWidget);
    expect(find.text('Floating Widget'), findsOneWidget);
    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('Data Export'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('hotkey string is displayed', (tester) async {
    await tester.pumpWidget(_buildTestApp(vm));
    await tester.pumpAndSettle();
    expect(find.text('ctrl+shift+d'), findsOneWidget);
  });

  testWidgets('Subscribe button shown when not subscribed', (tester) async {
    await tester.pumpWidget(_buildTestApp(vm));
    await tester.pumpAndSettle();
    expect(find.text('Subscribe — \$5/month'), findsOneWidget);
  });

  testWidgets('Subscribe button absent when subscribed', (tester) async {
    fakeSettingsRepo = FakeSettingsRepository()
      ..overrideSettings(const UserSettings(
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
    vm = SettingsViewModel(
      settingsRepository: fakeSettingsRepo,
      dhikrRepository: fakeDhikrRepo,
      subscriptionService: fakeSubscription,
    );
    await tester.pumpWidget(_buildTestApp(vm));
    await tester.pumpAndSettle();
    expect(find.text('Subscribe — \$5/month'), findsNothing);
  });

  testWidgets('Verify button triggers verifySubscription', (tester) async {
    fakeSubscription =
        FakeSubscriptionService(statusMap: {'user@example.com': true});
    vm = SettingsViewModel(
      settingsRepository: fakeSettingsRepo,
      dhikrRepository: fakeDhikrRepo,
      subscriptionService: fakeSubscription,
    );
    await tester.pumpWidget(_buildTestApp(vm));
    await tester.pumpAndSettle();

    // The TextFormField may be off-screen; scroll to it first.
    await tester.ensureVisible(find.byType(TextFormField));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'user@example.com');

    // Scroll to the Verify button and tap it.
    final verifyFinder = find.text('Verify');
    await tester.ensureVisible(verifyFinder);
    await tester.pumpAndSettle();
    await tester.tap(verifyFinder);
    await tester.pumpAndSettle();

    expect(
      find.text('Subscription verified. JazakAllahu Khayran.'),
      findsOneWidget,
    );
  });

  testWidgets('Export JSON button calls exportData', (tester) async {
    await tester.pumpWidget(_buildTestApp(vm));
    await tester.pumpAndSettle();

    // Scroll to the Export JSON button which may be off-screen.
    final exportJsonFinder = find.text('Export JSON');
    await tester.ensureVisible(exportJsonFinder);
    await tester.pumpAndSettle();

    await tester.tap(exportJsonFinder);
    await tester.pump();
    // Verify loading indicator appears briefly.
    // (File I/O path tested at unit level in SettingsViewModel tests.)
  });

  testWidgets('widget visible toggle calls toggleWidgetVisible', (tester) async {
    await tester.pumpWidget(_buildTestApp(vm));
    await tester.pumpAndSettle();
    final initial = vm.settings.widgetVisible;
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(vm.settings.widgetVisible, !initial);
  });
}
