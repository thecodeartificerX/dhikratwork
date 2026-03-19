// test/fakes/fake_database_service.dart

import 'package:dhikratwork/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// In-memory fake that simulates the DatabaseService SQL interface.
///
/// Each table is a `Map<String, List<Map<String, dynamic>>>` keyed by table
/// name. Every insert auto-increments a per-table counter and stamps `id` on
/// the row. Supports the same four core methods as DatabaseService plus
/// [rawQuery] for join-like operations.
class FakeDatabaseService implements DatabaseService {
  // ---------------------------------------------------------------------------
  // Internal store
  // ---------------------------------------------------------------------------

  /// table name → list of row maps (each row has an 'id' key).
  final Map<String, List<Map<String, dynamic>>> _store = {};

  /// table name → next auto-increment id.
  final Map<String, int> _nextId = {};

  // ---------------------------------------------------------------------------
  // DatabaseService interface — lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> open() async {
    // No-op: in-memory store is always ready.
  }

  @override
  Future<void> close() async {
    // No-op.
  }

  @override
  bool get isOpen => true;

  @override
  Future<Database> get database async =>
      throw UnimplementedError('FakeDatabaseService does not expose database.');

  // ---------------------------------------------------------------------------
  // DatabaseService interface — generic CRUD
  // ---------------------------------------------------------------------------

  /// Insert [values] into [table]. Returns the auto-incremented row id.
  @override
  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    _store.putIfAbsent(table, () => []);
    _nextId.putIfAbsent(table, () => 1);

    final int id = _nextId[table]!;
    _nextId[table] = id + 1;

    final Map<String, dynamic> row = Map<String, dynamic>.from(values)
      ..['id'] = id;
    _store[table]!.add(row);
    return id;
  }

  /// Query [table] with optional equality [where] clause using [whereArgs].
  ///
  /// The [where] string must be in the form `'col = ? AND col2 = ?'` — only
  /// `=` comparisons separated by `AND` are supported by this fake. This
  /// covers every query pattern used by the four repositories in Phase 2A.
  @override
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final rows = List<Map<String, dynamic>>.from(_store[table] ?? []);

    final filtered = where == null
        ? rows
        : rows.where((row) => _matchesWhere(row, where, whereArgs)).toList();

    if (orderBy != null) {
      // Simple single-column orderBy: 'column ASC' or 'column DESC'
      final parts = orderBy.trim().split(RegExp(r'\s+'));
      final col = parts[0];
      final desc = parts.length > 1 && parts[1].toUpperCase() == 'DESC';
      filtered.sort((a, b) {
        final av = a[col];
        final bv = b[col];
        if (av == null && bv == null) return 0;
        if (av == null) return desc ? 1 : -1;
        if (bv == null) return desc ? -1 : 1;
        final cmp = Comparable.compare(av as Comparable, bv as Comparable);
        return desc ? -cmp : cmp;
      });
    }

    final result = limit != null ? filtered.take(limit).toList() : filtered;
    // Return deep copies so callers cannot mutate the store.
    return result.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  /// Update rows in [table] matching [where]/[whereArgs]. Returns row count.
  @override
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final rows = _store[table];
    if (rows == null) return 0;

    int count = 0;
    for (int i = 0; i < rows.length; i++) {
      if (where == null || _matchesWhere(rows[i], where, whereArgs)) {
        rows[i] = Map<String, dynamic>.from(rows[i])..addAll(values);
        count++;
      }
    }
    return count;
  }

  /// Delete rows from [table] matching [where]/[whereArgs]. Returns row count.
  @override
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final rows = _store[table];
    if (rows == null) return 0;

    final before = rows.length;
    rows.removeWhere(
      (row) => where == null || _matchesWhere(row, where, whereArgs),
    );
    return before - rows.length;
  }

  /// Execute a raw DML statement (UPDATE/INSERT/DELETE). This fake supports:
  ///
  ///   UPDATE <table> SET <col> = <col> + 1 WHERE <col> = ?
  ///
  /// Used by repositories that need atomic read-modify-write without a
  /// separate query round-trip. For Phase 2A, [SessionRepository.incrementCount]
  /// uses this pattern.
  @override
  Future<void> execute(String sql, [List<dynamic>? arguments]) async {
    // Pattern: UPDATE table SET col = col + 1 WHERE idCol = ?
    final updateIncrPattern = RegExp(
      r'UPDATE\s+(\w+)\s+SET\s+(\w+)\s*=\s*\2\s*\+\s*1\s+WHERE\s+(\w+)\s*=\s*\?',
      caseSensitive: false,
    );
    final updateIncrMatch = updateIncrPattern.firstMatch(sql.trim());
    if (updateIncrMatch != null) {
      final table = updateIncrMatch.group(1)!;
      final valueCol = updateIncrMatch.group(2)!;
      final whereCol = updateIncrMatch.group(3)!;
      final arg = arguments?.first;
      final rows = _store[table];
      if (rows == null) return;
      for (int i = 0; i < rows.length; i++) {
        if (rows[i][whereCol] == arg) {
          rows[i] = Map<String, dynamic>.from(rows[i])
            ..[valueCol] = ((rows[i][valueCol] as int?) ?? 0) + 1;
        }
      }
      return;
    }

    throw UnimplementedError('FakeDatabaseService.execute does not support: $sql');
  }

  /// Execute a raw SQL-like query. This fake supports a restricted subset:
  ///
  ///   SELECT cols FROM table [WHERE col = ?] [ORDER BY col [DESC]]
  ///
  /// Used by repositories that need aggregate or join-style queries. For Phase
  /// 2A, [SessionRepository.getTodaySessionCount] uses this with a SUM.
  @override
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    // ---------------------------------------------------------------------------
    // Pattern: SELECT SUM(col) AS alias FROM table WHERE col = ?
    // Used by: SessionRepository.getTodaySessionCount
    // ---------------------------------------------------------------------------
    final sumPattern = RegExp(
      r"SELECT SUM\((\w+)\) AS (\w+) FROM (\w+)(?: WHERE (.+))?",
      caseSensitive: false,
    );
    final sumMatch = sumPattern.firstMatch(sql.trim());
    if (sumMatch != null) {
      final sumCol = sumMatch.group(1)!;
      final alias = sumMatch.group(2)!;
      final table = sumMatch.group(3)!;
      final whereClause = sumMatch.group(4);

      final rows = await query(table, where: whereClause, whereArgs: arguments);
      final total = rows.fold<int>(
        0,
        (acc, r) => acc + ((r[sumCol] as int?) ?? 0),
      );
      return [
        {alias: total}
      ];
    }

    // ---------------------------------------------------------------------------
    // Pattern: SELECT COUNT(*) AS alias FROM table WHERE col = ?
    // ---------------------------------------------------------------------------
    final countPattern = RegExp(
      r"SELECT COUNT\(\*\) AS (\w+) FROM (\w+)(?: WHERE (.+))?",
      caseSensitive: false,
    );
    final countMatch = countPattern.firstMatch(sql.trim());
    if (countMatch != null) {
      final alias = countMatch.group(1)!;
      final table = countMatch.group(2)!;
      final whereClause = countMatch.group(3);

      final rows = await query(table, where: whereClause, whereArgs: arguments);
      return [
        {alias: rows.length}
      ];
    }

    throw UnimplementedError('FakeDatabaseService.rawQuery does not support: $sql');
  }

  // ---------------------------------------------------------------------------
  // DatabaseService interface — domain-specific CRUD wrappers (no-op stubs)
  // These are implemented for interface compliance. Repositories use the generic
  // insert/query/update/delete/execute/rawQuery methods above.
  // ---------------------------------------------------------------------------

  @override
  Future<int> insertDhikr(Map<String, dynamic> row) =>
      insert('dhikr', row);

  @override
  Future<List<Map<String, dynamic>>> queryAllDhikr({
    bool includeHidden = false,
  }) =>
      query('dhikr');

  @override
  Future<List<Map<String, dynamic>>> queryDhikrByCategory(
    String category,
  ) =>
      query('dhikr', where: 'category = ?', whereArgs: [category]);

  @override
  Future<Map<String, dynamic>?> queryDhikrById(int id) async {
    final rows =
        await query('dhikr', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<int> updateDhikr(int id, Map<String, dynamic> row) =>
      update('dhikr', row, where: 'id = ?', whereArgs: [id]);

  @override
  Future<int> hideDhikr(int id) => update(
        'dhikr',
        {'is_hidden': 1},
        where: 'id = ? AND is_preloaded = ?',
        whereArgs: [id, 1],
      );

  @override
  Future<int> deleteDhikr(int id) => delete(
        'dhikr',
        where: 'id = ? AND is_preloaded = ?',
        whereArgs: [id, 0],
      );

  @override
  Future<int> insertSession(Map<String, dynamic> row) =>
      insert('dhikr_session', row);

  @override
  Future<List<Map<String, dynamic>>> querySessionsByDhikr(int dhikrId) =>
      query('dhikr_session', where: 'dhikr_id = ?', whereArgs: [dhikrId]);

  @override
  Future<List<Map<String, dynamic>>> querySessionsForDate(String date) =>
      query('dhikr_session');

  @override
  Future<int> updateSession(int id, Map<String, dynamic> row) =>
      update('dhikr_session', row, where: 'id = ?', whereArgs: [id]);

  @override
  Future<int> deleteSession(int id) =>
      delete('dhikr_session', where: 'id = ?', whereArgs: [id]);

  @override
  Future<Map<String, dynamic>?> querySummary(int dhikrId, String date) async =>
      null;

  @override
  Future<List<Map<String, dynamic>>> querySummariesForDate(String date) async =>
      [];

  @override
  Future<List<Map<String, dynamic>>> querySummariesForDateRange(
    String startDate,
    String endDate,
  ) async =>
      [];

  @override
  Future<void> upsertDailySummary({
    required int dhikrId,
    required String date,
    required int countDelta,
    int sessionDelta = 0,
  }) async {}

  @override
  Future<int> insertGoal(Map<String, dynamic> row) => insert('goal', row);

  @override
  Future<List<Map<String, dynamic>>> queryActiveGoals() async => [];

  @override
  Future<List<Map<String, dynamic>>> queryAllGoals() async => [];

  @override
  Future<int> updateGoal(int id, Map<String, dynamic> row) =>
      update('goal', row, where: 'id = ?', whereArgs: [id]);

  @override
  Future<int> deleteGoal(int id) =>
      delete('goal', where: 'id = ?', whereArgs: [id]);

  @override
  Future<List<Map<String, dynamic>>> queryAllAchievements() async => [];

  @override
  Future<Map<String, dynamic>?> queryAchievementByKey(String key) async => null;

  @override
  Future<int> unlockAchievement(String key, String unlockedAt) async => 0;

  @override
  Future<Map<String, dynamic>?> querySettings() async {
    final rows = await query(
      'user_settings',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<int> updateSettings(Map<String, dynamic> row) =>
      update('user_settings', row, where: 'id = ?', whereArgs: [1]);

  @override
  Future<Map<String, dynamic>?> queryStreak() async {
    final rows = await query(
      'streak',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<int> updateStreak(Map<String, dynamic> row) =>
      update('streak', row, where: 'id = ?', whereArgs: [1]);

  // ---------------------------------------------------------------------------
  // Test helpers (not part of DatabaseService interface)
  // ---------------------------------------------------------------------------

  /// Seed [rows] directly into [table] bypassing auto-increment.
  /// Useful for pre-populating the store in test setUp.
  void seedTable(String table, List<Map<String, dynamic>> rows) {
    _store[table] = rows.map((r) => Map<String, dynamic>.from(r)).toList();
    final maxId = rows
        .map((r) => (r['id'] as int?) ?? 0)
        .fold(0, (a, b) => a > b ? a : b);
    _nextId[table] = maxId + 1;
  }

  /// Clear all tables (reset between tests).
  void reset() {
    _store.clear();
    _nextId.clear();
  }

  /// Return a raw (mutable) copy of all rows in [table] for assertions.
  List<Map<String, dynamic>> tableRows(String table) {
    return (_store[table] ?? [])
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Evaluates a WHERE clause of the form `col = ? AND col2 = ?`.
  /// Supports `=`, `!=`, `>=`, `IS NULL`, and `IS NOT NULL` comparisons.
  bool _matchesWhere(
    Map<String, dynamic> row,
    String where,
    List<dynamic>? args,
  ) {
    // Split by AND (case-insensitive)
    final clauses = where.split(RegExp(r'\bAND\b', caseSensitive: false));
    int argIndex = 0;

    for (final clause in clauses) {
      final trimmed = clause.trim();

      // IS NULL check
      final isNullMatch = RegExp(
        r'^(\w+)\s+IS\s+NULL$',
        caseSensitive: false,
      ).firstMatch(trimmed);
      if (isNullMatch != null) {
        final col = isNullMatch.group(1)!;
        if (row[col] != null) return false;
        continue;
      }

      // IS NOT NULL check
      final isNotNullMatch = RegExp(
        r'^(\w+)\s+IS\s+NOT\s+NULL$',
        caseSensitive: false,
      ).firstMatch(trimmed);
      if (isNotNullMatch != null) {
        final col = isNotNullMatch.group(1)!;
        if (row[col] == null) return false;
        continue;
      }

      // != check
      final neqMatch = RegExp(r'^(\w+)\s*!=\s*\?$').firstMatch(trimmed);
      if (neqMatch != null) {
        final col = neqMatch.group(1)!;
        final arg = args![argIndex++];
        if (row[col] == arg) return false;
        continue;
      }

      // >= with literal string value (used by getTodaySessionCount date filter)
      final gteMatch =
          RegExp(r"^(\w+)\s*>=\s*'([^']+)'$").firstMatch(trimmed);
      if (gteMatch != null) {
        final col = gteMatch.group(1)!;
        final val = gteMatch.group(2)!;
        final rowVal = row[col];
        if (rowVal == null) return false;
        if ((rowVal as String).compareTo(val) < 0) return false;
        continue;
      }

      // = check (default)
      final eqMatch = RegExp(r'^(\w+)\s*=\s*\?$').firstMatch(trimmed);
      if (eqMatch != null) {
        final col = eqMatch.group(1)!;
        final arg = args![argIndex++];
        if (row[col] != arg) return false;
        continue;
      }

      throw UnimplementedError(
        'FakeDatabaseService._matchesWhere: unsupported clause "$trimmed"',
      );
    }
    return true;
  }
}
