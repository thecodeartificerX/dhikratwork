// test/unit/viewmodels/app_shell_viewmodel_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:dhikratwork/models/user_settings.dart';
import 'package:dhikratwork/utils/constants.dart';
import 'package:dhikratwork/viewmodels/app_shell_viewmodel.dart';
import '../../fakes/fake_settings_repository.dart';

void main() {
  late AppShellViewModel vm;
  late FakeSettingsRepository settingsRepo;

  setUp(() {
    settingsRepo = FakeSettingsRepository();
    vm = AppShellViewModel(settingsRepository: settingsRepo);
  });

  test('initial mode is compact', () {
    expect(vm.mode, equals(AppMode.compact));
  });

  test('setMode changes mode and notifies listeners', () async {
    int notifyCount = 0;
    vm.addListener(() => notifyCount++);

    await vm.setMode(AppMode.expanded);

    expect(vm.mode, equals(AppMode.expanded));
    expect(notifyCount, equals(1));
  });

  test('setMode to same value is a no-op', () async {
    int notifyCount = 0;
    vm.addListener(() => notifyCount++);

    await vm.setMode(AppMode.compact);

    expect(notifyCount, equals(0));
  });

  test('loadSavedPosition reads from settings', () async {
    settingsRepo.overrideSettings(const UserSettings(
      id: kSingleRowId,
      widgetPositionX: 100.0,
      widgetPositionY: 200.0,
      createdAt: '2026-01-01T00:00:00',
    ));

    await vm.loadSavedPosition();

    expect(vm.compactPositionX, equals(100.0));
    expect(vm.compactPositionY, equals(200.0));
  });

  test('loadSavedPosition with null returns null', () async {
    await vm.loadSavedPosition();

    expect(vm.compactPositionX, isNull);
    expect(vm.compactPositionY, isNull);
  });

  test('saveCompactPosition updates state and persists', () async {
    await vm.saveCompactPosition(150.0, 250.0);

    expect(vm.compactPositionX, equals(150.0));
    expect(vm.compactPositionY, equals(250.0));

    final settings = await settingsRepo.getSettings();
    expect(settings.widgetPositionX, equals(150.0));
    expect(settings.widgetPositionY, equals(250.0));
  });
}
