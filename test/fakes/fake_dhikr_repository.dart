// test/fakes/fake_dhikr_repository.dart

import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';

/// In-memory fake of [DhikrRepository] for use in ViewModel unit tests.
///
/// Simulates autoincrement by tracking [_nextId]. All mutations operate on
/// [_dhikrs] directly. No DatabaseService required.
///
/// Pre-seeded with 2 dhikrs so ViewModel tests that call [getAll()] get a
/// realistic non-empty list without extra setup.
class FakeDhikrRepository implements DhikrRepository {
  final List<Dhikr> _dhikrs = [
    const Dhikr(
      id: 1,
      name: 'SubhanAllah',
      arabicText: 'سُبْحَانَ اللَّهِ',
      transliteration: 'Subhanallah',
      translation: 'Glory be to Allah',
      category: 'general_tasbih',
      isPreloaded: true,
      isHidden: false,
      sortOrder: 1,
      createdAt: '2026-01-01T00:00:00',
    ),
    const Dhikr(
      id: 2,
      name: 'Alhamdulillah',
      arabicText: 'اَلْحَمْدُ لِلَّهِ',
      transliteration: 'Alhamdulillah',
      translation: 'Praise be to Allah',
      category: 'general_tasbih',
      isPreloaded: true,
      isHidden: false,
      sortOrder: 2,
      createdAt: '2026-01-01T00:00:00',
    ),
  ];
  int _nextId = 3;

  // Allow tests to pre-seed the repository (replaces default data)
  void seed(List<Dhikr> dhikrs) {
    _dhikrs.clear();
    _nextId = 1;
    for (final d in dhikrs) {
      _dhikrs.add(d.id != null ? d : d.copyWith(id: _nextId++));
    }
  }

  @override
  Future<Dhikr> add(Dhikr dhikr) async {
    final withId = dhikr.copyWith(id: _nextId++);
    _dhikrs.add(withId);
    return withId;
  }

  @override
  Future<void> delete(int id) async {
    _dhikrs.removeWhere((d) => d.id == id);
  }

  @override
  Future<List<Dhikr>> getAll() async {
    return List.unmodifiable(List<Dhikr>.from(_dhikrs));
  }

  @override
  Future<List<Dhikr>> getByCategory(String category) async {
    return List.unmodifiable(
      _dhikrs.where((d) => d.category == category).toList(),
    );
  }

  @override
  Future<Dhikr?> getById(int id) async {
    try {
      return _dhikrs.firstWhere((d) => d.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<List<Dhikr>> getVisible() async {
    return List.unmodifiable(
      _dhikrs.where((d) => !d.isHidden).toList(),
    );
  }

  @override
  Future<void> hide(int id) async {
    final idx = _dhikrs.indexWhere((d) => d.id == id);
    if (idx != -1) _dhikrs[idx] = _dhikrs[idx].copyWith(isHidden: true);
  }

  @override
  Future<void> unhide(int id) async {
    final idx = _dhikrs.indexWhere((d) => d.id == id);
    if (idx != -1) _dhikrs[idx] = _dhikrs[idx].copyWith(isHidden: false);
  }

  @override
  Future<void> update(Dhikr dhikr) async {
    final idx = _dhikrs.indexWhere((d) => d.id == dhikr.id);
    if (idx != -1) _dhikrs[idx] = dhikr;
  }
}
