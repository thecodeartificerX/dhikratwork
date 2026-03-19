// test/unit/viewmodels/dhikr_library_viewmodel_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/viewmodels/dhikr_library_viewmodel.dart';
import '../../fakes/fake_dhikr_repository.dart';

void main() {
  late DhikrLibraryViewModel vm;
  late FakeDhikrRepository dhikrRepo;

  setUp(() {
    dhikrRepo = FakeDhikrRepository();
    vm = DhikrLibraryViewModel(dhikrRepository: dhikrRepo);
  });

  test('initial state: empty list, not loading', () {
    expect(vm.dhikrList, isEmpty);
    expect(vm.isLoading, isFalse);
  });

  test('loadAll populates dhikrList', () async {
    int notifyCount = 0;
    vm.addListener(() => notifyCount++);

    await vm.loadAll();

    expect(vm.dhikrList, hasLength(2));
    expect(notifyCount, greaterThan(0));
  });

  test('addDhikr inserts and refreshes list', () async {
    await vm.loadAll();
    const newDhikr = Dhikr(
      name: 'Custom',
      arabicText: 'test',
      transliteration: 'test',
      translation: 'test',
      category: 'general_tasbih',
      isPreloaded: false,
      isHidden: false,
      sortOrder: 99,
      createdAt: '2026-01-01T00:00:00',
    );

    await vm.addDhikr(newDhikr);

    expect(vm.dhikrList, hasLength(3));
  });

  test('deleteDhikr removes from list', () async {
    await vm.loadAll();
    await vm.deleteDhikr(1);
    expect(vm.dhikrList.any((d) => d.id == 1), isFalse);
  });

  test('hideDhikr sets isHidden=true and reloads', () async {
    await vm.loadAll();
    await vm.hideDhikr(1);
    // After reload, the hidden dhikr should not appear in dhikrList
    expect(vm.dhikrList.any((d) => d.id == 1 && !d.isHidden), isFalse);
  });

  test('dhikrList is unmodifiable', () async {
    await vm.loadAll();
    const fakeDhikr = Dhikr(
      name: 'Test',
      arabicText: 'test',
      transliteration: 'test',
      translation: 'test',
      category: 'general_tasbih',
      isPreloaded: false,
      isHidden: false,
      sortOrder: 0,
      createdAt: '2026-01-01T00:00:00',
    );
    // List.unmodifiable throws UnsupportedError on mutation.
    final list = vm.dhikrList;
    expect(() => (list as dynamic).add(fakeDhikr), throwsUnsupportedError);
  });
}
