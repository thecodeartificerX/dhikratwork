// lib/repositories/session_repository.dart

import 'package:dhikratwork/models/dhikr_session.dart';
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/utils/constants.dart';

/// SSOT for [DhikrSession] domain data.
///
/// Sessions are created when a user starts actively counting a dhikr and
/// ended when they switch to another dhikr or close the app. The repository
/// is stateless — no in-memory caching — because sessions change very
/// frequently (every hotkey press) and always need the latest value.
class SessionRepository {
  final DatabaseService _db;

  SessionRepository(this._db);

  // ---------------------------------------------------------------------------
  // Create / end
  // ---------------------------------------------------------------------------

  /// Create a new open session for [dhikrId]. Returns the persisted session
  /// with its auto-assigned [id] and [startedAt] timestamp.
  Future<DhikrSession> createSession(int dhikrId, String source) async {
    final now = DateTime.now().toIso8601String();
    final data = <String, dynamic>{
      cSessionDhikrId: dhikrId,
      cSessionCount: 0,
      cSessionStartedAt: now,
      cSessionEndedAt: null,
      cSessionSource: source,
    };
    final id = await _db.insert(tDhikrSession, data);
    return DhikrSession(
      id: id,
      dhikrId: dhikrId,
      count: 0,
      startedAt: now,
      source: source,
    );
  }

  /// Mark session [sessionId] as ended by setting [ended_at] to now.
  Future<void> endSession(int sessionId) async {
    await _db.update(
      tDhikrSession,
      {cSessionEndedAt: DateTime.now().toIso8601String()},
      where: '$cSessionId = ?',
      whereArgs: [sessionId],
    );
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Returns the open (not-yet-ended) session for [dhikrId], or null if none.
  Future<DhikrSession?> getActiveSession(int dhikrId) async {
    final rows = await _db.query(
      tDhikrSession,
      where: '$cSessionDhikrId = ? AND $cSessionEndedAt IS NULL',
      whereArgs: [dhikrId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DhikrSession.fromMap(rows.first);
  }

  /// Returns all sessions (open and closed) for [dhikrId], newest first.
  Future<List<DhikrSession>> getSessionsByDhikr(int dhikrId) async {
    final rows = await _db.query(
      tDhikrSession,
      where: '$cSessionDhikrId = ?',
      whereArgs: [dhikrId],
      orderBy: '$cSessionStartedAt DESC',
    );
    return List.unmodifiable(rows.map(DhikrSession.fromMap).toList());
  }

  // ---------------------------------------------------------------------------
  // Counting
  // ---------------------------------------------------------------------------

  /// Increment the [count] of session [sessionId] by 1.
  ///
  /// Uses a raw UPDATE with `count + 1` to avoid a read-modify-write race.
  Future<void> incrementCount(int sessionId) async {
    await _db.execute(
      'UPDATE $tDhikrSession SET $cSessionCount = $cSessionCount + 1 '
      'WHERE $cSessionId = ?',
      [sessionId],
    );
  }

  /// Returns the total count for [dhikrId] across all sessions that started
  /// today (local date).
  Future<int> getTodaySessionCount(int dhikrId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await _db.rawQuery(
      'SELECT SUM($cSessionCount) AS total '
      'FROM $tDhikrSession '
      'WHERE $cSessionDhikrId = ? '
      "AND $cSessionStartedAt >= '${today}T00:00:00'",
      [dhikrId],
    );
    if (rows.isEmpty) return 0;
    return (rows.first['total'] as int?) ?? 0;
  }
}
