// test/fakes/fake_stats_repository.dart
import 'package:dhikratwork/models/daily_summary.dart';
import 'package:dhikratwork/repositories/stats_repository.dart';

/// In-memory fake of [StatsRepository] for use in ViewModel and View tests.
/// Avoids sqflite entirely — pure Dart state.
// ignore: subtype_of_sealed_class
class FakeStatsRepository implements StatsRepository {
  // Backing store: keyed by (dhikrId, date).
  final Map<String, DailySummary> _store = {};

  int _nextId = 1;

  String _key(int dhikrId, String date) => '$dhikrId::$date';

  @override
  Future<void> upsertDailySummary(
    int dhikrId,
    String date,
    int countDelta,
  ) async {
    final key = _key(dhikrId, date);
    final existing = _store[key];
    if (existing == null) {
      _store[key] = DailySummary(
        id: _nextId++,
        dhikrId: dhikrId,
        date: date,
        totalCount: countDelta,
        sessionCount: 1,
      );
    } else {
      _store[key] = DailySummary(
        id: existing.id,
        dhikrId: dhikrId,
        date: date,
        totalCount: existing.totalCount + countDelta,
        sessionCount: existing.sessionCount + 1,
      );
    }
  }

  @override
  Future<List<DailySummary>> getDailySummaries(String date) async {
    final result = _store.values.where((s) => s.date == date).toList();
    return List.unmodifiable(result);
  }

  @override
  Future<List<DailySummary>> getDailySummariesForPeriod(
    String startDate,
    String endDate,
  ) async {
    final result = _store.values
        .where((s) =>
            s.date.compareTo(startDate) >= 0 &&
            s.date.compareTo(endDate) <= 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return List.unmodifiable(result);
  }

  @override
  Future<int> getTotalCountForDate(String date) async {
    return _store.values
        .where((s) => s.date == date)
        .fold<int>(0, (sum, s) => sum + s.totalCount);
  }

  @override
  Future<int> getTotalCountForDhikrOnDate(int dhikrId, String date) async {
    return _store.values
        .where((s) => s.dhikrId == dhikrId && s.date == date)
        .fold<int>(0, (sum, s) => sum + s.totalCount);
  }

  @override
  Future<int> getTotalCountForDhikr(int dhikrId) async {
    return _store.values
        .where((s) => s.dhikrId == dhikrId)
        .fold<int>(0, (sum, s) => sum + s.totalCount);
  }

  @override
  Future<List<DailySummary>> getCountsByDhikrForPeriod(
    int dhikrId,
    String startDate,
    String endDate,
  ) async {
    final result = _store.values
        .where((s) =>
            s.dhikrId == dhikrId &&
            s.date.compareTo(startDate) >= 0 &&
            s.date.compareTo(endDate) <= 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return List.unmodifiable(result);
  }

  @override
  Future<void> resetDailySummary(int dhikrId, String date) async {
    final key = _key(dhikrId, date);
    final existing = _store[key];
    if (existing != null) {
      _store[key] = DailySummary(
        id: existing.id,
        dhikrId: existing.dhikrId,
        date: existing.date,
        totalCount: 0,
        sessionCount: existing.sessionCount,
      );
    }
  }

  /// Test helper — seed a pre-built summary directly.
  void seed(DailySummary summary) {
    _store[_key(summary.dhikrId, summary.date)] = summary;
  }

  /// Test helper — clear all data.
  void clear() => _store.clear();

  // ---------------------------------------------------------------------------
  // Phase 5 additions — ViewModel test helpers
  // ---------------------------------------------------------------------------

  /// Tracks the last period string passed to any method (for assertions).
  String? lastLoadedPeriod;

  /// Stubbed count returned by getTotalCountForDhikr/getTotalCountForDate
  /// when no seeded summaries exist (override for specific tests).
  int stubbedCurrentPeriodCount = 0;
}
