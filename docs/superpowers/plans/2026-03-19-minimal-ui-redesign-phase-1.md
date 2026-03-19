# Phase 1: Backend — ViewModels, Services & AppLocator

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modify all backend layers to support the new single-window architecture before any UI work begins.

**Architecture:** 7 independent tasks that can all run in parallel. All changes are below the widget layer — only ViewModels, services, and the AppLocator.

**Spec:** `docs/superpowers/specs/2026-03-19-minimal-ui-redesign-design.md`

**Validation:** `flutter analyze && flutter test` must pass after all tasks complete.

---

**IMPORTANT — Phase 1 scope note:** Tasks 1.6 (TrayService) and 1.7 (AppLocator) from the original plan have been moved to Phase 5. Both of these changes break `main.dart`'s compile because main.dart still uses the old 3-VM AppLocator signature and old TrayService setup signature. Since main.dart is rewritten in Phase 5, the rewrites are applied atomically there.

---

## Task 1.1: Create AppShellViewModel

**Files:**
- Create: `lib/viewmodels/app_shell_viewmodel.dart`
- Create: `test/unit/viewmodels/app_shell_viewmodel_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/unit/viewmodels/app_shell_viewmodel_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:dhikratwork/viewmodels/app_shell_viewmodel.dart';
import '../../fakes/fake_settings_repository.dart';

void main() {
  late AppShellViewModel vm;
  late FakeSettingsRepository settingsRepo;

  setUp(() {
    settingsRepo = FakeSettingsRepository();
    vm = AppShellViewModel(settingsRepository: settingsRepo);
  });

  test('initial mode is compact', () {
    expect(vm.mode, equals(AppMode.compact));
  });

  test('setMode changes mode and notifies listeners', () async {
    int notifyCount = 0;
    vm.addListener(() => notifyCount++);

    await vm.setMode(AppMode.expanded);

    expect(vm.mode, equals(AppMode.expanded));
    expect(notifyCount, equals(1));
  });

  test('setMode to same value is a no-op', () async {
    int notifyCount = 0;
    vm.addListener(() => notifyCount++);

    await vm.setMode(AppMode.compact);

    expect(notifyCount, equals(0));
  });

  test('loadSavedPosition reads from settings', () async {
    settingsRepo.overrideSettings(settingsRepo.settings.copyWith(
      widgetPositionX: 100.0,
      widgetPositionY: 200.0,
    ));

    await vm.loadSavedPosition();

    expect(vm.compactPositionX, equals(100.0));
    expect(vm.compactPositionY, equals(200.0));
  });

  test('loadSavedPosition with null returns null', () async {
    await vm.loadSavedPosition();

    expect(vm.compactPositionX, isNull);
    expect(vm.compactPositionY, isNull);
  });

  test('saveCompactPosition updates state and persists', () async {
    await vm.saveCompactPosition(150.0, 250.0);

    expect(vm.compactPositionX, equals(150.0));
    expect(vm.compactPositionY, equals(250.0));

    final settings = await settingsRepo.getSettings();
    expect(settings.widgetPositionX, equals(150.0));
    expect(settings.widgetPositionY, equals(250.0));
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/viewmodels/app_shell_viewmodel_test.dart`
Expected: FAIL — `app_shell_viewmodel.dart` does not exist

- [ ] **Step 3: Implement AppShellViewModel**

```dart
// lib/viewmodels/app_shell_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:dhikratwork/repositories/settings_repository.dart';

enum AppMode { compact, expanded }

class AppShellViewModel extends ChangeNotifier {
  final SettingsRepository _settingsRepository;

  AppShellViewModel({required SettingsRepository settingsRepository})
      : _settingsRepository = settingsRepository;

  AppMode _mode = AppMode.compact;
  AppMode get mode => _mode;

  double? _compactPositionX;
  double? _compactPositionY;
  double? get compactPositionX => _compactPositionX;
  double? get compactPositionY => _compactPositionY;

  Future<void> setMode(AppMode newMode) async {
    if (_mode == newMode) return;
    _mode = newMode;
    notifyListeners();
  }

  Future<void> loadSavedPosition() async {
    final settings = await _settingsRepository.getSettings();
    _compactPositionX = settings.widgetPositionX;
    _compactPositionY = settings.widgetPositionY;
  }

  Future<void> saveCompactPosition(double x, double y) async {
    _compactPositionX = x;
    _compactPositionY = y;
    await _settingsRepository.setWidgetPosition(x, y);
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/unit/viewmodels/app_shell_viewmodel_test.dart`
Expected: All 6 tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/viewmodels/app_shell_viewmodel.dart test/unit/viewmodels/app_shell_viewmodel_test.dart
git commit -m "feat: add AppShellViewModel with mode toggling and position persistence"
```

---

## Task 1.2: Modify CounterViewModel

Remove the WidgetToolbarViewModel sync block, add session count tracking, and add reset methods for compact bar context menu.

**Files:**
- Modify: `lib/viewmodels/counter_viewmodel.dart`
- Modify: `lib/repositories/stats_repository.dart` (add `resetDailySummary`)
- Modify: `test/fakes/fake_stats_repository.dart` (add `resetDailySummary`)
- Modify: `test/unit/viewmodels/counter_viewmodel_test.dart`

- [ ] **Step 1: Add `resetDailySummary` to StatsRepository**

In `lib/repositories/stats_repository.dart`, add after the `getCountsByDhikrForPeriod` method:

```dart
  /// Resets the [total_count] for a given ([dhikrId], [date]) row to 0.
  /// No-op if the row does not exist.
  Future<void> resetDailySummary(int dhikrId, String date) async {
    await _db.execute(
      'UPDATE $tDailySummary SET $cSummaryTotalCount = 0 '
      'WHERE $cSummaryDhikrId = ? AND $cSummaryDate = ?',
      [dhikrId, date],
    );
  }
```

- [ ] **Step 2: Add `resetDailySummary` to FakeStatsRepository**

In `test/fakes/fake_stats_repository.dart`, add before the `seed` method:

```dart
  @override
  Future<void> resetDailySummary(int dhikrId, String date) async {
    final key = _key(dhikrId, date);
    final existing = _store[key];
    if (existing != null) {
      _store[key] = DailySummary(
        id: existing.id,
        dhikrId: dhikrId,
        date: date,
        totalCount: 0,
        sessionCount: existing.sessionCount,
      );
    }
  }
```

- [ ] **Step 3: Write failing tests for new CounterViewModel behavior**

Add to `test/unit/viewmodels/counter_viewmodel_test.dart` (also add `import 'package:dhikratwork/models/user_settings.dart';` at the top):

```dart
  test('incrementActiveDhikr increments sessionCount', () async {
    await vm.setActiveDhikr(1);
    await vm.startSession(1);

    expect(vm.sessionCount, equals(0));

    await vm.incrementActiveDhikr(source: 'hotkey');

    expect(vm.sessionCount, equals(1));
  });

  test('loadActiveSession resumes open session and restores sessionCount',
      () async {
    // Create a session with some counts.
    final session = await sessionRepo.createSession(1, 'main_app');
    await sessionRepo.incrementCount(session.id!);
    await sessionRepo.incrementCount(session.id!);

    // Set active dhikr in settings.
    final testSettingsRepo = FakeSettingsRepository();
    testSettingsRepo.overrideSettings(const UserSettings(
      id: 1,
      activeDhikrId: 1,
      globalHotkey: 'ctrl+shift+d',
      widgetVisible: true,
      themeVariant: 'default',
      subscriptionStatus: 'free',
      createdAt: '2026-01-01T00:00:00',
    ));

    final freshVm = CounterViewModel(
      dhikrRepository: FakeDhikrRepository(),
      sessionRepository: sessionRepo,
      statsRepository: statsRepo,
      streakRepository: streakRepo,
      achievementRepository: FakeAchievementRepository(),
      settingsRepository: testSettingsRepo,
    );

    await freshVm.loadActiveSession();

    expect(freshVm.activeDhikr, isNotNull);
    expect(freshVm.activeDhikr!.id, equals(1));
    expect(freshVm.sessionCount, equals(2));
  });

  test('resetSessionCount ends current and starts new session', () async {
    await vm.setActiveDhikr(1);
    await vm.startSession(1);
    await vm.incrementActiveDhikr(source: 'hotkey');
    await vm.incrementActiveDhikr(source: 'hotkey');

    expect(vm.sessionCount, equals(2));

    await vm.resetSessionCount();

    expect(vm.sessionCount, equals(0));
    expect(vm.activeSession, isNotNull);
    expect(vm.activeDhikr!.id, equals(1)); // same dhikr
  });

  test('resetTodayCount resets todayCount to 0', () async {
    await vm.setActiveDhikr(1);
    await vm.incrementActiveDhikr(source: 'hotkey');
    await vm.incrementActiveDhikr(source: 'hotkey');

    expect(vm.todayCount, equals(2));

    await vm.resetTodayCount();

    expect(vm.todayCount, equals(0));
  });
```

- [ ] **Step 4: Run tests to verify they fail**

Run: `flutter test test/unit/viewmodels/counter_viewmodel_test.dart`
Expected: FAIL — `sessionCount`, `loadActiveSession`, `resetSessionCount`, `resetTodayCount` do not exist

- [ ] **Step 5: Modify CounterViewModel**

In `lib/viewmodels/counter_viewmodel.dart`:

1. **Add `_sessionCount` field** after `_isLoading`:
```dart
  int _sessionCount = 0;
  int get sessionCount => _sessionCount;
```

2. **Remove the toolbar sync block** in `incrementActiveDhikr()`. Delete this entire block (lines ~160-174):
```dart
    // Refresh WidgetToolbarViewModel counts so the floating toolbar updates.
    // Both share the same main-window isolate, so direct call works.
    // AppLocator may not be initialized if called from tests — guard with try.
    try {
      final widgetVm = AppLocator.instance.widgetToolbarViewModel;
      final ids = widgetVm.toolbarDhikrs
          .where((d) => d.id != null)
          .map((d) => d.id!)
          .toList();
      if (ids.contains(activeDhikrId)) {
        await widgetVm.incrementDhikr(activeDhikrId);
      }
    } catch (_) {
      // AppLocator not initialized (e.g. test environment). Ignore.
    }
```

3. **Add `_sessionCount++`** in `incrementActiveDhikr()` after `_todayCount++`:
```dart
    _sessionCount++;
```

4. **Update `startSession`** to reset session count:
```dart
  Future<void> startSession(int dhikrId) async {
    await _sessionRepository.createSession(dhikrId, 'main_app');
    _activeSession = await _sessionRepository.getActiveSession(dhikrId);
    _sessionCount = 0;
    notifyListeners();
  }
```

5. **Add `loadActiveSession()` method** after `endSession()`:
```dart
  /// Restores active dhikr + session from DB on app startup.
  /// If an open session exists, resumes it with the persisted count.
  /// If no open session but an active dhikr is set, starts a fresh session.
  Future<void> loadActiveSession() async {
    final settings = await _settingsRepository.getSettings();
    final activeDhikrId = settings.activeDhikrId;
    if (activeDhikrId == null) return;

    _activeDhikr = await _dhikrRepository.getById(activeDhikrId);
    if (_activeDhikr == null) return;

    // Load today's count for this specific dhikr (not aggregate across all).
    final today = _todayDateString();
    final todaySummaries = await _statsRepository.getDailySummaries(today);
    _todayCount = todaySummaries
        .where((s) => s.dhikrId == activeDhikrId)
        .fold(0, (sum, s) => sum + s.totalCount);

    final session = await _sessionRepository.getActiveSession(activeDhikrId);
    if (session != null) {
      _activeSession = session;
      _sessionCount = session.count;
    } else {
      await _sessionRepository.createSession(activeDhikrId, 'main_app');
      _activeSession =
          await _sessionRepository.getActiveSession(activeDhikrId);
      _sessionCount = 0;
    }

    notifyListeners();
  }
```

6. **Add `resetSessionCount()` method**:
```dart
  /// Ends the current session and starts a new one for the same dhikr.
  /// Resets the displayed session count to 0.
  Future<void> resetSessionCount() async {
    if (_activeDhikr == null) return;
    final dhikrId = _activeDhikr!.id!;

    if (_activeSession?.id != null) {
      await _sessionRepository.endSession(_activeSession!.id!);
    }
    await _sessionRepository.createSession(dhikrId, 'main_app');
    _activeSession =
        await _sessionRepository.getActiveSession(dhikrId);
    _sessionCount = 0;
    notifyListeners();
  }
```

7. **Add `resetTodayCount()` method**:
```dart
  /// Resets the daily_summary total for the active dhikr for today to 0.
  Future<void> resetTodayCount() async {
    if (_activeDhikr == null) return;
    final today = _todayDateString();
    await _statsRepository.resetDailySummary(_activeDhikr!.id!, today);
    _todayCount = 0;
    notifyListeners();
  }
```

8. **Remove the `AppLocator` import** at the top of the file:
```dart
// DELETE: import 'package:dhikratwork/app/app_locator.dart';
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/unit/viewmodels/counter_viewmodel_test.dart`
Expected: All tests PASS

- [ ] **Step 7: Commit**

```bash
git add lib/viewmodels/counter_viewmodel.dart lib/repositories/stats_repository.dart test/fakes/fake_stats_repository.dart test/unit/viewmodels/counter_viewmodel_test.dart
git commit -m "feat: add session tracking and reset methods to CounterViewModel, remove toolbar sync"
```

---

## Task 1.3: Remove Category Filtering from DhikrLibraryViewModel

**Files:**
- Modify: `lib/viewmodels/dhikr_library_viewmodel.dart`
- Modify: `test/unit/viewmodels/dhikr_library_viewmodel_test.dart`

- [ ] **Step 1: Read the existing test file**

Read `test/unit/viewmodels/dhikr_library_viewmodel_test.dart` to see which tests reference `filterByCategory`, `filteredList`, or `selectedCategory`.

- [ ] **Step 2: Modify DhikrLibraryViewModel**

Remove the following from `lib/viewmodels/dhikr_library_viewmodel.dart`:

1. Delete the `_filteredList` field, getter, `_selectedCategory` field, getter
2. Delete the `filterByCategory()` method
3. Delete the `_applyFilter()` helper
4. In `loadAll()`, remove the `_applyFilter()` call

The result should be:

```dart
// lib/viewmodels/dhikr_library_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';

class DhikrLibraryViewModel extends ChangeNotifier {
  final DhikrRepository _dhikrRepository;

  DhikrLibraryViewModel({required DhikrRepository dhikrRepository})
      : _dhikrRepository = dhikrRepository;

  List<Dhikr> _dhikrList = const [];
  List<Dhikr> get dhikrList => _dhikrList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      final all = await _dhikrRepository.getAll();
      _dhikrList = List.unmodifiable(all.where((d) => !d.isHidden).toList());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDhikr(Dhikr dhikr) async {
    await _dhikrRepository.add(dhikr);
    await loadAll();
  }

  Future<void> updateDhikr(Dhikr dhikr) async {
    await _dhikrRepository.update(dhikr);
    await loadAll();
  }

  Future<void> deleteDhikr(int id) async {
    await _dhikrRepository.delete(id);
    await loadAll();
  }

  Future<void> hideDhikr(int id) async {
    await _dhikrRepository.hide(id);
    await loadAll();
  }
}
```

- [ ] **Step 3: Update tests**

Remove any tests that reference `filterByCategory`, `filteredList`, or `selectedCategory`. Update remaining tests that used `filteredList` to use `dhikrList` instead.

- [ ] **Step 4: Run tests**

Run: `flutter test test/unit/viewmodels/dhikr_library_viewmodel_test.dart`
Expected: All remaining tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/viewmodels/dhikr_library_viewmodel.dart test/unit/viewmodels/dhikr_library_viewmodel_test.dart
git commit -m "refactor: remove category filtering from DhikrLibraryViewModel"
```

---

## Task 1.4: Expand StatsViewModel

Add StreakRepository and DhikrRepository dependencies for stat cards and dhikr name resolution.

**Files:**
- Modify: `lib/viewmodels/stats_viewmodel.dart`
- Modify: `test/unit/viewmodels/stats_viewmodel_test.dart`

- [ ] **Step 1: Write failing tests**

Add to `test/unit/viewmodels/stats_viewmodel_test.dart`:

```dart
  test('loadStats also loads streak and totalCountForPeriod', () async {
    final streakRepo = FakeStreakRepository();
    final dhikrRepo = FakeDhikrRepository();
    final statsRepo = FakeStatsRepository();

    final vm = StatsViewModel(
      statsRepository: statsRepo,
      streakRepository: streakRepo,
      dhikrRepository: dhikrRepo,
    );

    await vm.loadStats();

    expect(vm.currentStreak, isNotNull);
    expect(vm.totalCountForPeriod, isA<int>());
  });

  test('dhikrNameForId resolves id to name', () async {
    final statsRepo = FakeStatsRepository();
    final streakRepo = FakeStreakRepository();
    final dhikrRepo = FakeDhikrRepository();

    final vm = StatsViewModel(
      statsRepository: statsRepo,
      streakRepository: streakRepo,
      dhikrRepository: dhikrRepo,
    );

    await vm.loadStats();

    expect(vm.dhikrNameForId(1), equals('SubhanAllah'));
    expect(vm.dhikrNameForId(999), equals('Unknown'));
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/viewmodels/stats_viewmodel_test.dart`
Expected: FAIL — constructor signature mismatch

- [ ] **Step 3: Modify StatsViewModel**

Replace `lib/viewmodels/stats_viewmodel.dart` with:

```dart
// lib/viewmodels/stats_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';
import 'package:dhikratwork/repositories/stats_repository.dart';
import 'package:dhikratwork/repositories/streak_repository.dart';

class StatsViewModel extends ChangeNotifier {
  final StatsRepository _statsRepository;
  final StreakRepository _streakRepository;
  final DhikrRepository _dhikrRepository;

  StatsViewModel({
    required StatsRepository statsRepository,
    required StreakRepository streakRepository,
    required DhikrRepository dhikrRepository,
  })  : _statsRepository = statsRepository,
        _streakRepository = streakRepository,
        _dhikrRepository = dhikrRepository;

  String selectedPeriod = 'day'; // 'day' | 'week' | 'month'
  Map<String, int> barChartData = {};
  List<MapEntry<String, int>> lineChartData = [];
  bool isLoading = false;
  String? errorMessage;

  int _currentStreak = 0;
  int get currentStreak => _currentStreak;

  int _totalCountForPeriod = 0;
  int get totalCountForPeriod => _totalCountForPeriod;

  Map<int, String> _dhikrNames = const {};

  Future<void> loadStats() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final (start, end) = getDateRange();
      final startDate = '${start.year.toString().padLeft(4, '0')}-'
          '${start.month.toString().padLeft(2, '0')}-'
          '${start.day.toString().padLeft(2, '0')}';
      final endDate = '${end.year.toString().padLeft(4, '0')}-'
          '${end.month.toString().padLeft(2, '0')}-'
          '${end.day.toString().padLeft(2, '0')}';

      // Load all data in parallel with proper typing.
      final summariesFuture =
          _statsRepository.getDailySummariesForPeriod(startDate, endDate);
      final streakFuture = _streakRepository.getStreak();
      final dhikrFuture = _dhikrRepository.getAll();

      final summaries = await summariesFuture;
      final streak = await streakFuture;
      final allDhikr = await dhikrFuture;

      _currentStreak = streak.currentStreak;

      // Build dhikr name lookup.
      _dhikrNames = Map.unmodifiable({
        for (final d in allDhikr)
          if (d.id != null) d.id!: d.name,
      });

      // Build barChartData: dhikrId (as string key) -> total count for period.
      final barMap = <String, int>{};
      for (final s in summaries) {
        final key = s.dhikrId.toString();
        barMap[key] = (barMap[key] ?? 0) + s.totalCount;
      }
      barChartData = Map.unmodifiable(barMap);

      // Total count for period.
      _totalCountForPeriod = barMap.values.fold(0, (a, b) => a + b);

      // Build lineChartData: date -> daily total across all dhikrs.
      final lineMap = <String, int>{};
      for (final s in summaries) {
        lineMap[s.date] = (lineMap[s.date] ?? 0) + s.totalCount;
      }
      final sortedDates = lineMap.keys.toList()..sort();
      lineChartData = List.unmodifiable(
        sortedDates.map((d) => MapEntry(d, lineMap[d]!)).toList(),
      );
    } catch (e) {
      errorMessage = 'Failed to load stats: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPeriod(String period) async {
    assert(
      ['day', 'week', 'month'].contains(period),
      'period must be day, week, or month',
    );
    selectedPeriod = period;
    notifyListeners();
    await loadStats();
  }

  /// Resolves a dhikr ID to its display name. Returns 'Unknown' if not found.
  String dhikrNameForId(int id) => _dhikrNames[id] ?? 'Unknown';

  (DateTime, DateTime) getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (selectedPeriod) {
      'day' => (today, today),
      'week' => (today.subtract(const Duration(days: 6)), today),
      'month' => (DateTime(today.year, today.month, 1), today),
      _ => (today, today),
    };
  }
}
```

- [ ] **Step 4: Update existing tests**

Update all existing tests in `test/unit/viewmodels/stats_viewmodel_test.dart` to use the new 3-parameter constructor:

```dart
final vm = StatsViewModel(
  statsRepository: FakeStatsRepository(),
  streakRepository: FakeStreakRepository(),
  dhikrRepository: FakeDhikrRepository(),
);
```

Add the required imports:
```dart
import '../../fakes/fake_streak_repository.dart';
import '../../fakes/fake_dhikr_repository.dart';
```

- [ ] **Step 5: Run tests**

Run: `flutter test test/unit/viewmodels/stats_viewmodel_test.dart`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```bash
git add lib/viewmodels/stats_viewmodel.dart test/unit/viewmodels/stats_viewmodel_test.dart
git commit -m "feat: add streak, dhikr name resolution, and totalCountForPeriod to StatsViewModel"
```

---

## Task 1.5: Extend HotkeyService with F-Key Support

**Files:**
- Modify: `lib/services/hotkey_service.dart`
- Create: `test/unit/services/hotkey_service_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/unit/services/hotkey_service_test.dart

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dhikratwork/services/hotkey_service.dart';

void main() {
  group('parseHotKey', () {
    test('parses ctrl+shift+d', () {
      final hk = parseHotKey('ctrl+shift+d');
      expect(hk, isNotNull);
      expect(hk!.key, equals(LogicalKeyboardKey.keyD));
    });

    test('parses f9 (single key, no modifiers)', () {
      final hk = parseHotKey('f9');
      expect(hk, isNotNull);
      expect(hk!.key, equals(LogicalKeyboardKey.f9));
      expect(hk.modifiers, isEmpty);
    });

    test('parses f1 through f12', () {
      for (int i = 1; i <= 12; i++) {
        final hk = parseHotKey('f$i');
        expect(hk, isNotNull, reason: 'f$i should parse');
      }
    });

    test('parses ctrl+f10', () {
      final hk = parseHotKey('ctrl+f10');
      expect(hk, isNotNull);
      expect(hk!.key, equals(LogicalKeyboardKey.f10));
      expect(hk.modifiers, contains(HotKeyModifier.control));
    });

    test('returns null for empty string', () {
      expect(parseHotKey(''), isNull);
    });

    test('returns null for unknown key', () {
      expect(parseHotKey('ctrl+mousebutton3'), isNull);
    });
  });
}
```

Note: Import `HotKeyModifier` from `hotkey_manager` — the exact import path is `package:hotkey_manager/hotkey_manager.dart`.

- [ ] **Step 2: Run tests to verify F-key tests fail**

Run: `flutter test test/unit/services/hotkey_service_test.dart`
Expected: FAIL — `parseHotKey('f9')` returns null

- [ ] **Step 3: Add F-key support to `_parseLogicalKey`**

In `lib/services/hotkey_service.dart`, add to the switch expression in `_parseLogicalKey` before the `_ => null` case:

```dart
    'f1' => LogicalKeyboardKey.f1,
    'f2' => LogicalKeyboardKey.f2,
    'f3' => LogicalKeyboardKey.f3,
    'f4' => LogicalKeyboardKey.f4,
    'f5' => LogicalKeyboardKey.f5,
    'f6' => LogicalKeyboardKey.f6,
    'f7' => LogicalKeyboardKey.f7,
    'f8' => LogicalKeyboardKey.f8,
    'f9' => LogicalKeyboardKey.f9,
    'f10' => LogicalKeyboardKey.f10,
    'f11' => LogicalKeyboardKey.f11,
    'f12' => LogicalKeyboardKey.f12,
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/unit/services/hotkey_service_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/services/hotkey_service.dart test/unit/services/hotkey_service_test.dart
git commit -m "feat: extend HotkeyService to support F1-F12 single keys"
```

---

**Note:** Tasks 1.6 (Simplify TrayService) and 1.7 (Modify AppLocator) have been moved to Phase 5 to avoid breaking `main.dart` compilation. Both are applied atomically alongside the main.dart rewrite.

---

## Phase 1 Validation

After all 5 tasks are complete:

```bash
flutter analyze
flutter test test/unit/viewmodels/app_shell_viewmodel_test.dart test/unit/viewmodels/counter_viewmodel_test.dart test/unit/viewmodels/dhikr_library_viewmodel_test.dart test/unit/viewmodels/stats_viewmodel_test.dart test/unit/services/hotkey_service_test.dart
```

Expected: `flutter analyze` should pass cleanly — AppLocator and TrayService are unchanged at this point, so `main.dart` still compiles. All unit tests should PASS.
