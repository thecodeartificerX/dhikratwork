// test/unit/repositories/session_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:dhikratwork/repositories/session_repository.dart';
import 'package:dhikratwork/utils/constants.dart';
import '../../fakes/fake_database_service.dart';

void main() {
  late FakeDatabaseService fakeDb;
  late SessionRepository repo;

  /// Stable "today" string used throughout this test suite.
  final String today = DateTime.now().toIso8601String().substring(0, 10);
  final String yesterday = DateTime.now()
      .subtract(const Duration(days: 1))
      .toIso8601String()
      .substring(0, 10);

  setUp(() {
    fakeDb = FakeDatabaseService();
    repo = SessionRepository(fakeDb);
  });

  tearDown(() => fakeDb.reset());

  // -------------------------------------------------------------------------
  // createSession
  // -------------------------------------------------------------------------

  group('createSession', () {
    test('creates a session and returns it with an id', () async {
      final session = await repo.createSession(1, kSourceMainApp);
      expect(session.id, isNotNull);
      expect(session.dhikrId, 1);
      expect(session.source, kSourceMainApp);
      expect(session.count, 0);
      expect(session.endedAt, isNull);
    });

    test('startedAt is set to current time (today)', () async {
      final session = await repo.createSession(1, kSourceMainApp);
      expect(session.startedAt.startsWith(today), isTrue);
    });

    test('two sessions get different ids', () async {
      final a = await repo.createSession(1, kSourceMainApp);
      final b = await repo.createSession(1, kSourceMainApp);
      expect(a.id, isNot(b.id));
    });
  });

  // -------------------------------------------------------------------------
  // endSession
  // -------------------------------------------------------------------------

  group('endSession', () {
    test('sets ended_at on the session', () async {
      final session = await repo.createSession(1, kSourceMainApp);
      await repo.endSession(session.id!);
      final rows = fakeDb.tableRows(tDhikrSession);
      final row = rows.firstWhere((r) => r['id'] == session.id);
      expect(row[cSessionEndedAt], isNotNull);
    });

    test('ended_at timestamp starts with today', () async {
      final session = await repo.createSession(1, kSourceMainApp);
      await repo.endSession(session.id!);
      final rows = fakeDb.tableRows(tDhikrSession);
      final row = rows.firstWhere((r) => r['id'] == session.id);
      expect((row[cSessionEndedAt] as String).startsWith(today), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // getActiveSession
  // -------------------------------------------------------------------------

  group('getActiveSession', () {
    test('returns null when no session exists for dhikr', () async {
      final session = await repo.getActiveSession(99);
      expect(session, isNull);
    });

    test('returns open session for the given dhikr', () async {
      final created = await repo.createSession(1, kSourceMainApp);
      final found = await repo.getActiveSession(1);
      expect(found, isNotNull);
      expect(found!.id, created.id);
    });

    test('returns null after session is ended', () async {
      final created = await repo.createSession(1, kSourceMainApp);
      await repo.endSession(created.id!);
      final found = await repo.getActiveSession(1);
      expect(found, isNull);
    });

    test('returns only session for the specific dhikr', () async {
      await repo.createSession(1, kSourceMainApp);
      final found = await repo.getActiveSession(2);
      expect(found, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // getSessionsByDhikr
  // -------------------------------------------------------------------------

  group('getSessionsByDhikr', () {
    test('returns empty list when no sessions exist', () async {
      final result = await repo.getSessionsByDhikr(1);
      expect(result, isEmpty);
    });

    test('returns all sessions for the dhikr', () async {
      await repo.createSession(1, kSourceMainApp);
      await repo.createSession(1, kSourceHotkey);
      await repo.createSession(2, kSourceMainApp); // different dhikr
      final result = await repo.getSessionsByDhikr(1);
      expect(result.length, 2);
    });

    test('result is unmodifiable', () async {
      await repo.createSession(1, kSourceMainApp);
      final result = await repo.getSessionsByDhikr(1);
      expect(() => (result as dynamic).clear(), throwsUnsupportedError);
    });
  });

  // -------------------------------------------------------------------------
  // incrementCount
  // -------------------------------------------------------------------------

  group('incrementCount', () {
    test('increments count by 1', () async {
      final session = await repo.createSession(1, kSourceMainApp);
      await repo.incrementCount(session.id!);
      final rows = fakeDb.tableRows(tDhikrSession);
      final row = rows.firstWhere((r) => r['id'] == session.id);
      expect(row[cSessionCount], 1);
    });

    test('multiple increments accumulate', () async {
      final session = await repo.createSession(1, kSourceMainApp);
      await repo.incrementCount(session.id!);
      await repo.incrementCount(session.id!);
      await repo.incrementCount(session.id!);
      final rows = fakeDb.tableRows(tDhikrSession);
      final row = rows.firstWhere((r) => r['id'] == session.id);
      expect(row[cSessionCount], 3);
    });
  });

  // -------------------------------------------------------------------------
  // getTodaySessionCount
  // -------------------------------------------------------------------------

  group('getTodaySessionCount', () {
    test('returns 0 when no sessions exist', () async {
      final count = await repo.getTodaySessionCount(1);
      expect(count, 0);
    });

    test('sums counts from sessions that started today', () async {
      final s1 = await repo.createSession(1, kSourceMainApp);
      await repo.incrementCount(s1.id!);
      await repo.incrementCount(s1.id!);
      final s2 = await repo.createSession(1, kSourceHotkey);
      await repo.incrementCount(s2.id!);
      final count = await repo.getTodaySessionCount(1);
      expect(count, 3);
    });

    test('excludes sessions for other dhikrs', () async {
      final s = await repo.createSession(1, kSourceMainApp);
      await repo.incrementCount(s.id!);
      final count = await repo.getTodaySessionCount(2);
      expect(count, 0);
    });

    test('excludes sessions from yesterday', () async {
      // Seed a session that started yesterday
      fakeDb.seedTable(tDhikrSession, [
        {
          'id': 1,
          cSessionDhikrId: 1,
          cSessionCount: 50,
          cSessionStartedAt: '${yesterday}T10:00:00',
          cSessionEndedAt: '${yesterday}T10:30:00',
          cSessionSource: kSourceMainApp,
        }
      ]);
      final count = await repo.getTodaySessionCount(1);
      expect(count, 0);
    });
  });
}
