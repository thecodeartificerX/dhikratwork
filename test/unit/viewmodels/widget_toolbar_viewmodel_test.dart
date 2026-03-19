// test/unit/viewmodels/widget_toolbar_viewmodel_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:dhikratwork/viewmodels/widget_toolbar_viewmodel.dart';
import '../../fakes/fake_dhikr_repository.dart';
import '../../fakes/fake_settings_repository.dart';
import '../../fakes/fake_session_repository.dart';

void main() {
  late WidgetToolbarViewModel vm;
  late FakeDhikrRepository fakeDhikrRepo;
  late FakeSettingsRepository fakeSettingsRepo;
  late FakeSessionRepository fakeSessionRepo;

  setUp(() {
    fakeDhikrRepo = FakeDhikrRepository();
    fakeSettingsRepo = FakeSettingsRepository();
    fakeSessionRepo = FakeSessionRepository();
    vm = WidgetToolbarViewModel(
      dhikrRepository: fakeDhikrRepo,
      settingsRepository: fakeSettingsRepo,
      sessionRepository: fakeSessionRepo,
    );
  });

  group('loadToolbar', () {
    test('loads dhikrs from widget_dhikr_ids in settings', () async {
      // Default FakeSettingsRepository has empty widgetDhikrIds, so should
      // fall back to first 3 dhikrs from repository.
      // FakeDhikrRepository seeds 2 dhikrs by default, so we get 2.
      await vm.loadToolbar();

      // Should have loaded up to 3 (limited by available 2 in fake repo)
      expect(vm.toolbarDhikrs.length, greaterThanOrEqualTo(1));
      expect(vm.toolbarDhikrs.first.name, equals('SubhanAllah'));
    });

    test('notifies listeners after loading', () async {
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      await vm.loadToolbar();

      expect(notifyCount, greaterThanOrEqualTo(1));
    });

    test('loads today counts for toolbar dhikrs', () async {
      fakeSessionRepo.seedTodayCount(1, 42);
      await vm.loadToolbar();

      expect(vm.todayCounts[1], equals(42));
    });

    test('sets isLoading to false after loading', () async {
      await vm.loadToolbar();
      expect(vm.isLoading, isFalse);
    });
  });

  group('incrementDhikr', () {
    test('increments today count for given dhikr id', () async {
      await vm.loadToolbar();
      final countBefore = vm.todayCounts[1] ?? 0;

      await vm.incrementDhikr(1);

      expect(vm.todayCounts[1], equals(countBefore + 1));
    });

    test('notifies listeners after increment', () async {
      await vm.loadToolbar();
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      await vm.incrementDhikr(1);

      expect(notifyCount, greaterThanOrEqualTo(1));
    });
  });

  group('setActiveDhikr', () {
    test('updates activeDhikrId and persists to settings', () async {
      await vm.loadToolbar();
      await vm.setActiveDhikr(2);

      expect(vm.activeDhikrId, equals(2));
      final settings = await fakeSettingsRepo.getSettings();
      expect(settings.activeDhikrId, equals(2));
    });

    test('notifies listeners', () async {
      await vm.loadToolbar();
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      await vm.setActiveDhikr(3);

      expect(notifyCount, greaterThanOrEqualTo(1));
    });
  });

  group('toggleExpand', () {
    test('toggles isExpanded from true to false', () async {
      await vm.loadToolbar();
      expect(vm.isExpanded, isTrue); // default is expanded

      vm.toggleExpand();

      expect(vm.isExpanded, isFalse);
    });

    test('toggles isExpanded from false to true', () async {
      await vm.loadToolbar();
      vm.toggleExpand(); // collapse
      vm.toggleExpand(); // re-expand

      expect(vm.isExpanded, isTrue);
    });
  });

  group('updatePosition', () {
    test('persists position to settings repository', () async {
      await vm.loadToolbar();
      await vm.updatePosition(100.0, 200.0);

      final settings = await fakeSettingsRepo.getSettings();
      expect(settings.widgetPositionX, equals(100.0));
      expect(settings.widgetPositionY, equals(200.0));
    });
  });
}
