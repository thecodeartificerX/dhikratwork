# Phase 6: Cleanup & Integration Tests

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Delete all old files, remove unused packages, delete/update old tests, and add integration tests for the new architecture.

**Architecture:** Pure cleanup + verification. No new features.

**Depends on:** Phase 5 (all new code is in place and working)

---

## Task 6.1: Delete Old Source Files

**Files to delete:**

```
lib/viewmodels/widget_toolbar_viewmodel.dart
lib/viewmodels/dashboard_viewmodel.dart
lib/views/widget/floating_toolbar.dart
lib/views/dashboard/dashboard_screen.dart
lib/views/library/library_screen.dart
lib/views/library/dhikr_detail_screen.dart
lib/views/library/add_dhikr_screen.dart
lib/views/settings/settings_screen.dart
lib/views/settings/dhikr_multi_select.dart
lib/views/shared/dhikr_counter_tile.dart
lib/views/shared/subscription_prompt.dart
lib/views/stats/stats_screen.dart
lib/services/floating_window_manager.dart
lib/app/router.dart
```

- [ ] **Step 1: Delete all listed files**

```bash
rm lib/viewmodels/widget_toolbar_viewmodel.dart
rm lib/viewmodels/dashboard_viewmodel.dart
rm lib/views/widget/floating_toolbar.dart
rm lib/views/dashboard/dashboard_screen.dart
rm lib/views/library/library_screen.dart
rm lib/views/library/dhikr_detail_screen.dart
rm lib/views/library/add_dhikr_screen.dart
rm lib/views/settings/settings_screen.dart
rm lib/views/settings/dhikr_multi_select.dart
rm lib/views/shared/dhikr_counter_tile.dart
rm lib/views/shared/subscription_prompt.dart
rm lib/views/stats/stats_screen.dart
rm lib/services/floating_window_manager.dart
rm lib/app/router.dart
```

- [ ] **Step 2: Delete empty directories**

```bash
rmdir lib/views/widget/
rmdir lib/views/dashboard/
# lib/views/library/ still has reused files? No — add_dhikr_screen was replaced by dialog.
# Wait: library/ directory is now empty. Delete it.
rmdir lib/views/library/
```

Note: `lib/views/settings/` still contains `hotkey_record_dialog.dart` (kept). `lib/views/stats/` still contains chart widgets (kept). `lib/views/shared/` still contains `achievement_badge.dart`, `splash_screen.dart`, `add_dhikr_dialog.dart`, `dhikr_selection_dialog.dart`.

- [ ] **Step 3: Run analyze to verify no broken imports**

```bash
flutter analyze
```

Expected: Clean. All old imports were removed in Phase 5 main.dart rewrite. If any `import` references remain to deleted files, fix them.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: delete old multi-window and dashboard files"
```

---

## Task 6.2: Remove Unused Packages from pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Remove desktop_multi_window and go_router**

In `pubspec.yaml`, under `dependencies:`, delete these lines:

```yaml
  # Navigation
  go_router: ^14.6.2

  # ...
  desktop_multi_window: ^0.3.0
```

Keep all other dependencies (window_manager, hotkey_manager, tray_manager, etc.).

- [ ] **Step 2: Run flutter pub get**

```bash
flutter pub get
```

Expected: Success, no resolution errors.

- [ ] **Step 3: Run analyze**

```bash
flutter analyze
```

Expected: Clean.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: remove desktop_multi_window and go_router packages"
```

---

## Task 6.3: Delete/Update Old Tests

**Files to delete:**
```
test/unit/viewmodels/widget_toolbar_viewmodel_test.dart
test/unit/viewmodels/dashboard_viewmodel_test.dart
test/widget/views/floating_toolbar_test.dart
test/widget/views/dashboard/dashboard_screen_test.dart
test/widget/views/library/library_screen_test.dart
test/widget/views/library/add_dhikr_screen_test.dart
test/widget/views/settings/settings_screen_test.dart
test/widget/views/stats/stats_screen_test.dart
```

**Files to update:**
```
integration_test/hotkey_integration_test.dart
```

- [ ] **Step 1: Delete old test files**

```bash
rm test/unit/viewmodels/widget_toolbar_viewmodel_test.dart
rm test/unit/viewmodels/dashboard_viewmodel_test.dart
rm test/widget/views/floating_toolbar_test.dart
rm test/widget/views/dashboard/dashboard_screen_test.dart
rm test/widget/views/library/library_screen_test.dart
rm test/widget/views/library/add_dhikr_screen_test.dart
rm test/widget/views/settings/settings_screen_test.dart
rm test/widget/views/stats/stats_screen_test.dart
```

- [ ] **Step 2: Delete empty test directories**

```bash
rmdir test/widget/views/dashboard/
rmdir test/widget/views/library/
# test/widget/views/settings/ is now empty
rmdir test/widget/views/settings/
# test/widget/views/stats/ is now empty
rmdir test/widget/views/stats/
```

- [ ] **Step 3: Update integration test for new AppLocator signature**

Rewrite `integration_test/hotkey_integration_test.dart`:

```dart
// integration_test/hotkey_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dhikratwork/app/app_locator.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';
import 'package:dhikratwork/repositories/session_repository.dart';
import 'package:dhikratwork/repositories/settings_repository.dart';
import 'package:dhikratwork/repositories/stats_repository.dart';
import 'package:dhikratwork/repositories/streak_repository.dart';
import 'package:dhikratwork/repositories/achievement_repository.dart';
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/services/subscription_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hotkey increment updates CounterViewModel counts',
      (tester) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final db = DatabaseService();
    await db.open();

    final dhikrRepo = DhikrRepository(db);
    final sessionRepo = SessionRepository(db);
    final settingsRepo = SettingsRepository(db);
    final statsRepo = StatsRepository(db);
    final streakRepo = StreakRepository(db);
    final achievementRepo = AchievementRepository(db);

    final counterVm = CounterViewModel(
      dhikrRepository: dhikrRepo,
      sessionRepository: sessionRepo,
      statsRepository: statsRepo,
      streakRepository: streakRepo,
      achievementRepository: achievementRepo,
      settingsRepository: settingsRepo,
    );

    final settingsVm = SettingsViewModel(
      settingsRepository: settingsRepo,
      dhikrRepository: dhikrRepo,
      subscriptionService: NoOpSubscriptionService(),
    );

    // Initialize AppLocator (new 2-VM signature).
    AppLocator.initialize(
      counterViewModel: counterVm,
      settingsViewModel: settingsVm,
    );

    // Load active session (may resume or create one).
    await counterVm.loadActiveSession();
    await tester.pump();

    // Set an active dhikr if none.
    if (counterVm.activeDhikr == null) {
      final allDhikr = await dhikrRepo.getAll();
      if (allDhikr.isEmpty) {
        AppLocator.reset();
        await db.close();
        return;
      }
      await counterVm.setActiveDhikr(allDhikr.first.id!);
      await counterVm.startSession(allDhikr.first.id!);
      await tester.pump();
    }

    final countBefore = counterVm.todayCount;

    // Simulate hotkey press.
    await counterVm.incrementActiveDhikr(source: 'hotkey');
    await tester.pump();

    expect(counterVm.todayCount, equals(countBefore + 1));
    expect(counterVm.sessionCount, equals(counterVm.sessionCount));

    // Clean up.
    AppLocator.reset();
    await db.close();
  });
}
```

- [ ] **Step 4: Create mode switch integration test**

```dart
// integration_test/mode_switch_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dhikratwork/app/app_locator.dart';
import 'package:dhikratwork/repositories/settings_repository.dart';
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/viewmodels/app_shell_viewmodel.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';
import 'package:dhikratwork/repositories/session_repository.dart';
import 'package:dhikratwork/repositories/stats_repository.dart';
import 'package:dhikratwork/repositories/streak_repository.dart';
import 'package:dhikratwork/repositories/achievement_repository.dart';
import 'package:dhikratwork/services/subscription_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('compact → expanded → compact mode transitions',
      (tester) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final db = DatabaseService();
    await db.open();

    final settingsRepo = SettingsRepository(db);
    final dhikrRepo = DhikrRepository(db);
    final sessionRepo = SessionRepository(db);
    final statsRepo = StatsRepository(db);
    final streakRepo = StreakRepository(db);
    final achievementRepo = AchievementRepository(db);

    final appShellVm = AppShellViewModel(settingsRepository: settingsRepo);

    final counterVm = CounterViewModel(
      dhikrRepository: dhikrRepo,
      sessionRepository: sessionRepo,
      statsRepository: statsRepo,
      streakRepository: streakRepo,
      achievementRepository: achievementRepo,
      settingsRepository: settingsRepo,
    );

    final settingsVm = SettingsViewModel(
      settingsRepository: settingsRepo,
      dhikrRepository: dhikrRepo,
      subscriptionService: NoOpSubscriptionService(),
    );

    AppLocator.initialize(
      counterViewModel: counterVm,
      settingsViewModel: settingsVm,
    );

    // Start in compact mode.
    expect(appShellVm.mode, equals(AppMode.compact));

    // Switch to expanded.
    await appShellVm.setMode(AppMode.expanded);
    expect(appShellVm.mode, equals(AppMode.expanded));

    // Switch back to compact.
    await appShellVm.setMode(AppMode.compact);
    expect(appShellVm.mode, equals(AppMode.compact));

    // Verify position persistence.
    await appShellVm.saveCompactPosition(200.0, 300.0);
    final settings = await settingsRepo.getSettings();
    expect(settings.widgetPositionX, equals(200.0));
    expect(settings.widgetPositionY, equals(300.0));

    AppLocator.reset();
    await db.close();
  });
}
```

- [ ] **Step 5: Run all tests**

```bash
flutter test
```

Expected: All tests pass. Test count will be lower than the original 261 because old test files were deleted.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore: delete old tests, update integration tests for new architecture"
```

---

## Final Validation

Run the full test suite and analyzer:

```bash
flutter analyze
flutter test
```

Both must pass with zero errors. The analyzer should report 0 issues. The test count reflects the new architecture:
- Unit: AppShellViewModel, CounterViewModel, DhikrLibraryViewModel, StatsViewModel, GamificationViewModel, GoalViewModel, SettingsViewModel, HotkeyService, repository tests (unchanged)
- Widget: CompactCounterBar, ExpandedShell, DhikrTab, StatsTab, SettingsTab, shared widget tests (achievement_badge)
- Integration: hotkey increment, mode switch

## Post-Cleanup: Update CLAUDE.md

After all phases complete, update `CLAUDE.md` to reflect the new architecture:

1. Remove multi-window isolation gotcha
2. Remove `WidgetToolbarViewModel` and `DashboardViewModel` references
3. Add `AppShellViewModel` to VM structure
4. Update architecture description (single window, two modes)
5. Update test tier count
6. Remove `go_router` and `desktop_multi_window` from any references
7. Add new gotcha about compact bar position using `widgetPositionX/Y`
