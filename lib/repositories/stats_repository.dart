// lib/repositories/stats_repository.dart
import 'package:dhikratwork/models/daily_summary.dart';
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/utils/constants.dart';

/// Repository for [DailySummary] data. Acts as the Single Source of Truth
/// for all stats/counting history. Consumers never touch [DatabaseService]
/// directly — they call methods on this repository.
class StatsRepository {
  StatsRepository(this._db);

  final DatabaseService _db;

  // -------------------------------------------------------------------------
  // upsertDailySummary
  // -------------------------------------------------------------------------

  /// Atomically increments [total_count] by [countDelta] and [session_count]
  /// by 1 for the row matching ([dhikrId], [date]). Inserts the row if it
  /// does not exist yet (UNIQUE constraint on dhikr_id + date).
  ///
  /// Uses INSERT OR REPLACE with arithmetic to avoid a read-then-write race.
  Future<void> upsertDailySummary(
    int dhikrId,
    String date,
    int countDelta,
  ) async {
    await _db.execute(
      '''
      INSERT INTO $tDailySummary
        ($cSummaryDhikrId, $cSummaryDate, $cSummaryTotalCount, $cSummarySessionCount)
      VALUES (?, ?, ?, 1)
      ON CONFLICT($cSummaryDhikrId, $cSummaryDate) DO UPDATE SET
        $cSummaryTotalCount = $cSummaryTotalCount + excluded.$cSummaryTotalCount,
        $cSummarySessionCount = $cSummarySessionCount + 1
      ''',
      [dhikrId, date, countDelta],
    );
  }

  // -------------------------------------------------------------------------
  // getDailySummaries
  // -------------------------------------------------------------------------

  /// Returns all [DailySummary] rows for [date] (YYYY-MM-DD).
  Future<List<DailySummary>> getDailySummaries(String date) async {
    final rows = await _db.query(
      tDailySummary,
      where: '$cSummaryDate = ?',
      whereArgs: [date],
    );
    return List.unmodifiable(rows.map(DailySummary.fromMap).toList());
  }

  // -------------------------------------------------------------------------
  // getDailySummariesForPeriod
  // -------------------------------------------------------------------------

  /// Returns all [DailySummary] rows where [date] is within the inclusive
  /// range [[startDate], [endDate]]. Lexicographic comparison works because
  /// dates are stored as ISO-8601 'YYYY-MM-DD' strings.
  Future<List<DailySummary>> getDailySummariesForPeriod(
    String startDate,
    String endDate,
  ) async {
    final rows = await _db.query(
      tDailySummary,
      where: '$cSummaryDate >= ? AND $cSummaryDate <= ?',
      whereArgs: [startDate, endDate],
      orderBy: '$cSummaryDate ASC',
    );
    return List.unmodifiable(rows.map(DailySummary.fromMap).toList());
  }

  // -------------------------------------------------------------------------
  // getTotalCountForDate
  // -------------------------------------------------------------------------

  /// Returns the aggregate sum of [total_count] across all dhikrs for [date].
  /// Returns 0 if no rows exist for that date.
  Future<int> getTotalCountForDate(String date) async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM($cSummaryTotalCount), 0) AS total '
      'FROM $tDailySummary '
      'WHERE $cSummaryDate = ?',
      [date],
    );
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  // -------------------------------------------------------------------------
  // getTotalCountForDhikrOnDate
  // -------------------------------------------------------------------------

  /// Returns the sum of [total_count] for a single [dhikrId] on [date].
  /// Returns 0 if no row exists.
  Future<int> getTotalCountForDhikrOnDate(int dhikrId, String date) async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM($cSummaryTotalCount), 0) AS total '
      'FROM $tDailySummary '
      'WHERE $cSummaryDhikrId = ? AND $cSummaryDate = ?',
      [dhikrId, date],
    );
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  // -------------------------------------------------------------------------
  // getTotalCountForDhikr
  // -------------------------------------------------------------------------

  /// Returns the all-time cumulative [total_count] for a single [dhikrId].
  /// Returns 0 if no rows exist.
  Future<int> getTotalCountForDhikr(int dhikrId) async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM($cSummaryTotalCount), 0) AS total '
      'FROM $tDailySummary '
      'WHERE $cSummaryDhikrId = ?',
      [dhikrId],
    );
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  // -------------------------------------------------------------------------
  // resetDailySummary
  // -------------------------------------------------------------------------

  /// Resets [total_count] to 0 for the row matching ([dhikrId], [date]).
  /// No-op if no matching row exists.
  Future<void> resetDailySummary(int dhikrId, String date) async {
    await _db.execute(
      'UPDATE $tDailySummary SET $cSummaryTotalCount = 0 '
      'WHERE $cSummaryDhikrId = ? AND $cSummaryDate = ?',
      [dhikrId, date],
    );
  }

  // -------------------------------------------------------------------------
  // getCountsByDhikrForPeriod
  // -------------------------------------------------------------------------

  /// Returns [DailySummary] rows for a single [dhikrId] within an inclusive
  /// date range. Used to power per-dhikr chart views.
  Future<List<DailySummary>> getCountsByDhikrForPeriod(
    int dhikrId,
    String startDate,
    String endDate,
  ) async {
    final rows = await _db.query(
      tDailySummary,
      where:
          '$cSummaryDhikrId = ? AND $cSummaryDate >= ? AND $cSummaryDate <= ?',
      whereArgs: [dhikrId, startDate, endDate],
      orderBy: '$cSummaryDate ASC',
    );
    return List.unmodifiable(rows.map(DailySummary.fromMap).toList());
  }
}
