// test/unit/repositories/dhikr_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';
import 'package:dhikratwork/utils/constants.dart';
import '../../fakes/fake_database_service.dart';

void main() {
  late FakeDatabaseService fakeDb;
  late DhikrRepository repo;

  /// Helper: a minimal valid Dhikr (no id, for inserting).
  Dhikr makeDhikr({
    String name = 'SubhanAllah',
    String category = kCategoryGeneralTasbih,
    bool isHidden = false,
    int sortOrder = 0,
  }) =>
      Dhikr(
        name: name,
        arabicText: 'سُبْحَانَ اللَّهِ',
        transliteration: 'Subhanallah',
        translation: 'Glory be to Allah',
        category: category,
        isPreloaded: false,
        isHidden: isHidden,
        sortOrder: sortOrder,
        createdAt: '2026-01-01T00:00:00',
      );

  setUp(() {
    fakeDb = FakeDatabaseService();
    repo = DhikrRepository(fakeDb);
  });

  tearDown(() => fakeDb.reset());

  // -------------------------------------------------------------------------
  // add
  // -------------------------------------------------------------------------

  group('add', () {
    test('inserts dhikr and returns it with auto-assigned id', () async {
      final inserted = await repo.add(makeDhikr());
      expect(inserted.id, isNotNull);
      expect(inserted.id, greaterThan(0));
      expect(inserted.name, 'SubhanAllah');
    });

    test('second insert gets a different id', () async {
      final a = await repo.add(makeDhikr(name: 'A'));
      final b = await repo.add(makeDhikr(name: 'B'));
      expect(a.id, isNot(b.id));
    });
  });

  // -------------------------------------------------------------------------
  // getAll
  // -------------------------------------------------------------------------

  group('getAll', () {
    test('returns empty list when no rows exist', () async {
      final result = await repo.getAll();
      expect(result, isEmpty);
    });

    test('returns all inserted dhikrs', () async {
      await repo.add(makeDhikr(name: 'A'));
      await repo.add(makeDhikr(name: 'B'));
      final result = await repo.getAll();
      expect(result.length, 2);
    });

    test('result is unmodifiable', () async {
      await repo.add(makeDhikr());
      final result = await repo.getAll();
      expect(() => (result as dynamic).clear(), throwsUnsupportedError);
    });

    test('includes hidden dhikrs', () async {
      await repo.add(makeDhikr(name: 'Visible'));
      await repo.add(makeDhikr(name: 'Hidden', isHidden: true));
      final result = await repo.getAll();
      expect(result.length, 2);
    });
  });

  // -------------------------------------------------------------------------
  // getById
  // -------------------------------------------------------------------------

  group('getById', () {
    test('returns dhikr for valid id', () async {
      final inserted = await repo.add(makeDhikr(name: 'Test'));
      final found = await repo.getById(inserted.id!);
      expect(found, isNotNull);
      expect(found!.name, 'Test');
    });

    test('returns null for unknown id', () async {
      final found = await repo.getById(9999);
      expect(found, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // getByCategory
  // -------------------------------------------------------------------------

  group('getByCategory', () {
    test('returns only dhikrs matching the category', () async {
      await repo.add(makeDhikr(name: 'A', category: kCategoryGeneralTasbih));
      await repo.add(makeDhikr(name: 'B', category: kCategoryPostSalah));
      await repo.add(makeDhikr(name: 'C', category: kCategoryGeneralTasbih));

      final result = await repo.getByCategory(kCategoryGeneralTasbih);
      expect(result.length, 2);
      expect(result.every((d) => d.category == kCategoryGeneralTasbih), isTrue);
    });

    test('returns empty list for unknown category', () async {
      await repo.add(makeDhikr());
      final result = await repo.getByCategory('nonexistent');
      expect(result, isEmpty);
    });

    test('result is unmodifiable', () async {
      await repo.add(makeDhikr());
      final result = await repo.getByCategory(kCategoryGeneralTasbih);
      expect(() => (result as dynamic).clear(), throwsUnsupportedError);
    });
  });

  // -------------------------------------------------------------------------
  // getVisible
  // -------------------------------------------------------------------------

  group('getVisible', () {
    test('excludes hidden dhikrs', () async {
      await repo.add(makeDhikr(name: 'Visible'));
      await repo.add(makeDhikr(name: 'Hidden', isHidden: true));
      final result = await repo.getVisible();
      expect(result.length, 1);
      expect(result.first.name, 'Visible');
    });

    test('returns empty when all are hidden', () async {
      await repo.add(makeDhikr(isHidden: true));
      final result = await repo.getVisible();
      expect(result, isEmpty);
    });

    test('result is unmodifiable', () async {
      await repo.add(makeDhikr());
      final result = await repo.getVisible();
      expect(() => (result as dynamic).clear(), throwsUnsupportedError);
    });
  });

  // -------------------------------------------------------------------------
  // update
  // -------------------------------------------------------------------------

  group('update', () {
    test('persists changed fields', () async {
      final inserted = await repo.add(makeDhikr(name: 'Original'));
      final updated = inserted.copyWith(name: 'Updated');
      await repo.update(updated);
      final found = await repo.getById(inserted.id!);
      expect(found!.name, 'Updated');
    });

    test('does not affect other rows', () async {
      final a = await repo.add(makeDhikr(name: 'A'));
      final b = await repo.add(makeDhikr(name: 'B'));
      await repo.update(a.copyWith(name: 'A-Updated'));
      final foundB = await repo.getById(b.id!);
      expect(foundB!.name, 'B');
    });
  });

  // -------------------------------------------------------------------------
  // delete
  // -------------------------------------------------------------------------

  group('delete', () {
    test('removes the row', () async {
      final inserted = await repo.add(makeDhikr());
      await repo.delete(inserted.id!);
      final found = await repo.getById(inserted.id!);
      expect(found, isNull);
    });

    test('other rows survive deletion', () async {
      final a = await repo.add(makeDhikr(name: 'A'));
      final b = await repo.add(makeDhikr(name: 'B'));
      await repo.delete(a.id!);
      final allRows = await repo.getAll();
      expect(allRows.length, 1);
      expect(allRows.first.id, b.id);
    });
  });

  // -------------------------------------------------------------------------
  // hide / unhide
  // -------------------------------------------------------------------------

  group('hide', () {
    test('sets is_hidden = true', () async {
      final inserted = await repo.add(makeDhikr());
      await repo.hide(inserted.id!);
      final found = await repo.getById(inserted.id!);
      expect(found!.isHidden, isTrue);
    });

    test('hidden dhikr disappears from getVisible', () async {
      final inserted = await repo.add(makeDhikr());
      expect((await repo.getVisible()).length, 1);
      await repo.hide(inserted.id!);
      expect((await repo.getVisible()).length, 0);
    });
  });

  group('unhide', () {
    test('sets is_hidden = false', () async {
      final inserted = await repo.add(makeDhikr(isHidden: true));
      await repo.unhide(inserted.id!);
      final found = await repo.getById(inserted.id!);
      expect(found!.isHidden, isFalse);
    });

    test('unhidden dhikr reappears in getVisible', () async {
      final inserted = await repo.add(makeDhikr(isHidden: true));
      expect((await repo.getVisible()).length, 0);
      await repo.unhide(inserted.id!);
      expect((await repo.getVisible()).length, 1);
    });
  });

  // -------------------------------------------------------------------------
  // Cache invalidation
  // -------------------------------------------------------------------------

  group('cache', () {
    test('cache is invalidated after add — second getAll sees new row', () async {
      await repo.getAll(); // Warm the cache
      await repo.add(makeDhikr(name: 'Late'));
      final result = await repo.getAll();
      expect(result.any((d) => d.name == 'Late'), isTrue);
    });

    test('cache is invalidated after update', () async {
      final inserted = await repo.add(makeDhikr(name: 'Before'));
      await repo.getAll(); // Warm the cache
      await repo.update(inserted.copyWith(name: 'After'));
      final result = await repo.getAll();
      expect(result.any((d) => d.name == 'After'), isTrue);
    });

    test('cache is invalidated after delete', () async {
      final inserted = await repo.add(makeDhikr());
      await repo.getAll(); // Warm the cache
      await repo.delete(inserted.id!);
      final result = await repo.getAll();
      expect(result, isEmpty);
    });
  });
}
