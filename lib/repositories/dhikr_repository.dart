// lib/repositories/dhikr_repository.dart

import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/utils/constants.dart';

/// SSOT for [Dhikr] domain data.
///
/// Wraps [DatabaseService] with in-memory caching. All write operations
/// invalidate [_cache] to ensure reads are always fresh after mutations.
class DhikrRepository {
  final DatabaseService _db;

  /// Nullable list cache. Null means "cache is cold and must be fetched".
  List<Dhikr>? _cache;

  DhikrRepository(this._db);

  // ---------------------------------------------------------------------------
  // Read operations
  // ---------------------------------------------------------------------------

  /// Returns all dhikrs (including hidden). Uses [_cache] if warm.
  Future<List<Dhikr>> getAll() async {
    if (_cache != null) return List.unmodifiable(_cache!);

    final rows = await _db.query(tDhikr, orderBy: '$cDhikrSortOrder ASC');
    _cache = rows.map(Dhikr.fromMap).toList();
    return List.unmodifiable(_cache!);
  }

  /// Returns a single dhikr by [id], or null if not found.
  Future<Dhikr?> getById(int id) async {
    final rows = await _db.query(
      tDhikr,
      where: '$cDhikrId = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Dhikr.fromMap(rows.first);
  }

  /// Returns all dhikrs with the given [category].
  Future<List<Dhikr>> getByCategory(String category) async {
    final rows = await _db.query(
      tDhikr,
      where: '$cDhikrCategory = ?',
      whereArgs: [category],
      orderBy: '$cDhikrSortOrder ASC',
    );
    return List.unmodifiable(rows.map(Dhikr.fromMap).toList());
  }

  /// Returns all dhikrs whose [id] is in [ids], preserving input order.
  Future<List<Dhikr>> getByIds(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final all = await getAll();
    return List.unmodifiable(all.where((d) => ids.contains(d.id)).toList());
  }

  /// Returns all dhikrs where [isHidden] is false.
  Future<List<Dhikr>> getVisible() async {
    final rows = await _db.query(
      tDhikr,
      where: '$cDhikrIsHidden = ?',
      whereArgs: [0],
      orderBy: '$cDhikrSortOrder ASC',
    );
    return List.unmodifiable(rows.map(Dhikr.fromMap).toList());
  }

  // ---------------------------------------------------------------------------
  // Write operations (all invalidate _cache)
  // ---------------------------------------------------------------------------

  /// Insert [dhikr] into the database. Returns the inserted [Dhikr] with its
  /// database-assigned [id].
  Future<Dhikr> add(Dhikr dhikr) async {
    final id = await _db.insert(tDhikr, dhikr.toMap());
    _invalidateCache();
    return dhikr.copyWith(id: id);
  }

  /// Persist changes to an existing [dhikr]. The [dhikr.id] must not be null.
  Future<void> update(Dhikr dhikr) async {
    assert(dhikr.id != null, 'update() called with a Dhikr that has no id');
    await _db.update(
      tDhikr,
      dhikr.toMap(),
      where: '$cDhikrId = ?',
      whereArgs: [dhikr.id],
    );
    _invalidateCache();
  }

  /// Hard-delete a dhikr by [id].
  /// Note: preloaded dhikrs should be hidden via [hide] rather than deleted.
  Future<void> delete(int id) async {
    await _db.delete(
      tDhikr,
      where: '$cDhikrId = ?',
      whereArgs: [id],
    );
    _invalidateCache();
  }

  /// Soft-hide a preloaded dhikr by [id] (sets is_hidden = 1).
  Future<void> hide(int id) async {
    await _db.update(
      tDhikr,
      {cDhikrIsHidden: 1},
      where: '$cDhikrId = ?',
      whereArgs: [id],
    );
    _invalidateCache();
  }

  /// Restore a hidden dhikr by [id] (sets is_hidden = 0).
  Future<void> unhide(int id) async {
    await _db.update(
      tDhikr,
      {cDhikrIsHidden: 0},
      where: '$cDhikrId = ?',
      whereArgs: [id],
    );
    _invalidateCache();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _invalidateCache() => _cache = null;
}
