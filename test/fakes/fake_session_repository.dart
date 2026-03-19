// test/fakes/fake_session_repository.dart

import 'package:dhikratwork/models/dhikr_session.dart';
import 'package:dhikratwork/repositories/session_repository.dart';

/// In-memory fake of [SessionRepository] for use in ViewModel unit tests.
class FakeSessionRepository implements SessionRepository {
  final List<DhikrSession> _sessions = [];
  int _nextId = 1;

  /// Pre-populate with sessions for tests that need existing data.
  void seed(List<DhikrSession> sessions) {
    _sessions.clear();
    for (final s in sessions) {
      _sessions.add(s.id != null ? s : s.copyWith(id: _nextId++));
    }
  }

  @override
  Future<DhikrSession> createSession(int dhikrId, String source) async {
    final now = DateTime.now().toIso8601String();
    final session = DhikrSession(
      id: _nextId++,
      dhikrId: dhikrId,
      count: 0,
      startedAt: now,
      source: source,
    );
    _sessions.add(session);
    return session;
  }

  @override
  Future<void> endSession(int sessionId) async {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      _sessions[idx] = _sessions[idx].copyWith(
        endedAt: DateTime.now().toIso8601String(),
      );
    }
  }

  @override
  Future<DhikrSession?> getActiveSession(int dhikrId) async {
    try {
      return _sessions.firstWhere(
        (s) => s.dhikrId == dhikrId && s.endedAt == null,
      );
    } on StateError {
      return null;
    }
  }

  @override
  Future<List<DhikrSession>> getSessionsByDhikr(int dhikrId) async {
    return List.unmodifiable(
      _sessions.where((s) => s.dhikrId == dhikrId).toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt)),
    );
  }

  @override
  Future<void> incrementCount(int sessionId) async {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      _sessions[idx] = _sessions[idx].copyWith(
        count: _sessions[idx].count + 1,
      );
    }
  }

  @override
  Future<int> getTodaySessionCount(int dhikrId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final int total = _sessions
        .where((s) => s.dhikrId == dhikrId && s.startedAt.startsWith(today))
        .fold<int>(0, (acc, s) => acc + s.count);
    return total;
  }
}
