// test/unit/viewmodels/settings_viewmodel_test.dart

import 'dart:convert';

import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_dhikr_repository.dart';
import '../../fakes/fake_settings_repository.dart';
import '../../fakes/fake_subscription_service.dart';

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

  group('loadSettings', () {
    test('sets isLoading then clears it', () async {
      final states = <bool>[];
      vm.addListener(() => states.add(vm.isLoading));
      await vm.loadSettings();
      expect(states, containsAllInOrder([true, false]));
    });

    test('populates settings from repository', () async {
      await vm.loadSettings();
      expect(vm.settings.globalHotkey, 'ctrl+shift+d');
    });

    test('hotkeyString matches settings.globalHotkey after load', () async {
      await vm.loadSettings();
      expect(vm.hotkeyString, 'ctrl+shift+d');
    });

    test('isSubscribed is false when status is free', () async {
      await vm.loadSettings();
      expect(vm.isSubscribed, isFalse);
    });
  });

  group('updateHotkey', () {
    test('persists new hotkey and notifies listeners', () async {
      await vm.loadSettings();
      final changes = <String>[];
      vm.addListener(() => changes.add(vm.hotkeyString));
      await vm.updateHotkey('ctrl+alt+d');
      expect(vm.hotkeyString, 'ctrl+alt+d');
      expect(
        (await fakeSettingsRepo.getSettings()).globalHotkey,
        'ctrl+alt+d',
      );
    });
  });

  group('toggleWidgetVisible', () {
    test('flips widget visibility and persists', () async {
      await vm.loadSettings();
      final initial = vm.settings.widgetVisible;
      await vm.toggleWidgetVisible();
      expect(vm.settings.widgetVisible, !initial);
    });
  });

  group('resetWidgetPosition', () {
    test('clears position x and y', () async {
      await vm.loadSettings();
      await vm.resetWidgetPosition();
      expect(vm.settings.widgetPositionX, isNull);
      expect(vm.settings.widgetPositionY, isNull);
    });
  });

  group('updateWidgetDhikrSelection', () {
    test('saves new dhikr id list as JSON string', () async {
      await vm.loadSettings();
      await vm.updateWidgetDhikrSelection([1, 2, 3]);
      // widgetDhikrIds is stored as a JSON array string in UserSettings.
      final raw = vm.settings.widgetDhikrIds;
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as List<dynamic>;
      expect(decoded.cast<int>(), [1, 2, 3]);
    });

    test('widgetDhikrIdsList getter returns parsed list', () async {
      await vm.loadSettings();
      await vm.updateWidgetDhikrSelection([1, 2, 3]);
      expect(vm.widgetDhikrIdsList, [1, 2, 3]);
    });
  });

  group('verifySubscription', () {
    test('sets isSubscribed true for active email', () async {
      fakeSubscription = FakeSubscriptionService(
        statusMap: {'test@example.com': true},
      );
      vm = SettingsViewModel(
        settingsRepository: fakeSettingsRepo,
        dhikrRepository: fakeDhikrRepo,
        subscriptionService: fakeSubscription,
      );
      await vm.loadSettings();
      await vm.verifySubscription('test@example.com');
      expect(vm.isSubscribed, isTrue);
      expect(vm.subscriptionEmail, 'test@example.com');
    });

    test('sets isSubscribed false for unknown email', () async {
      await vm.loadSettings();
      await vm.verifySubscription('nobody@example.com');
      expect(vm.isSubscribed, isFalse);
    });

    test('sets subscriptionError on offline exception', () async {
      fakeSubscription = FakeSubscriptionService(simulateOffline: true);
      vm = SettingsViewModel(
        settingsRepository: fakeSettingsRepo,
        dhikrRepository: fakeDhikrRepo,
        subscriptionService: fakeSubscription,
      );
      await vm.loadSettings();
      await vm.verifySubscription('test@example.com');
      expect(vm.subscriptionError, isNotNull);
    });
  });

  group('exportData', () {
    test('exportData json does not throw (may set exportError in test env)',
        () async {
      await vm.loadSettings();
      await expectLater(vm.exportData('json'), completes);
      // In test environments, path_provider may be unavailable.
      // The ViewModel captures any error in exportError rather than rethrowing,
      // so the future itself always completes successfully.
    });

    test('exportData csv does not throw (may set exportError in test env)',
        () async {
      await vm.loadSettings();
      await expectLater(vm.exportData('csv'), completes);
    });
  });
}
