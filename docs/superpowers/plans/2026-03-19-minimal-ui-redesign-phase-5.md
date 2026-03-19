# Phase 5: AppShell + main.dart Rewrite

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the top-level AppShell widget, rewrite main.dart, simplify TrayService, and modify AppLocator. These are done together atomically because TrayService and AppLocator signature changes break the old main.dart.

**Architecture:** `AppShell` listens to `AppShellViewModel.mode` and calls `window_manager` for OS-level window changes (size, always-on-top, title bar, taskbar). The `SplashThenApp` pattern is preserved but with the new dependency set.

**Depends on:** Phases 1-4 (all ViewModels, theme, all UI widgets)

**Spec:** `docs/superpowers/specs/2026-03-19-minimal-ui-redesign-design.md` — "Transitions" and "Startup Flow" sections

---

## Task 5.1: Build AppShell Widget

The root UI widget that switches between `CompactCounterBar` and `ExpandedShell` based on `AppShellViewModel.mode`.

**Files:**
- Create: `lib/views/app_shell.dart`

- [ ] **Step 1: Read the spec transition sequences**

Compact → Expanded:
1. `setAlwaysOnTop(false)` → `setTitleBarStyle(TitleBarStyle.normal)` → `setSkipTaskbar(false)` → `setSize(700, 500)` → `setAlignment(Alignment.center)`

Expanded → Compact:
1. `setSize(360, 60)` → `setPosition(savedX, savedY)` → `setTitleBarStyle(TitleBarStyle.hidden)` → `setSkipTaskbar(true)` → `setAlwaysOnTop(true)`

Esc behavior:
- Compact: no-op
- Expanded + dialog open: close dialog (standard Flutter)
- Expanded + text field focused: unfocus
- Expanded + nothing: collapse to compact

- [ ] **Step 2: Implement AppShell**

```dart
// lib/views/app_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:dhikratwork/viewmodels/app_shell_viewmodel.dart';
import 'package:dhikratwork/views/compact/compact_counter_bar.dart';
import 'package:dhikratwork/views/expanded/expanded_shell.dart';

/// Root UI widget. Crossfades between [CompactCounterBar] and [ExpandedShell]
/// based on [AppShellViewModel.mode]. Handles window_manager transitions.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppMode? _previousMode;

  @override
  void initState() {
    super.initState();
    final appShellVm = context.read<AppShellViewModel>();
    appShellVm.addListener(_onModeChanged);
    _previousMode = appShellVm.mode;
  }

  @override
  void dispose() {
    context.read<AppShellViewModel>().removeListener(_onModeChanged);
    super.dispose();
  }

  void _onModeChanged() {
    final appShellVm = context.read<AppShellViewModel>();
    final newMode = appShellVm.mode;
    if (newMode == _previousMode) return;
    _previousMode = newMode;

    if (newMode == AppMode.expanded) {
      _transitionToExpanded();
    } else {
      _transitionToCompact(appShellVm);
    }
  }

  Future<void> _transitionToExpanded() async {
    try {
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);
      await windowManager.setSkipTaskbar(false);
      await windowManager.setSize(const Size(700, 500));
      await windowManager.setAlignment(Alignment.center);
    } catch (_) {
      // window_manager may throw in test environments.
    }
  }

  Future<void> _transitionToCompact(AppShellViewModel appShellVm) async {
    try {
      final x = appShellVm.compactPositionX;
      final y = appShellVm.compactPositionY;
      await windowManager.setSize(const Size(360, 60));
      if (x != null && y != null) {
        await windowManager.setPosition(Offset(x, y));
      }
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setSkipTaskbar(true);
      await windowManager.setAlwaysOnTop(true);
    } catch (_) {
      // window_manager may throw in test environments.
    }
  }

  /// Handles Esc key: in expanded mode with nothing focused/open, collapse.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }

    final appShellVm = context.read<AppShellViewModel>();
    if (appShellVm.mode != AppMode.expanded) return KeyEventResult.ignored;

    // If a dialog or overlay is open, let Flutter's default behavior close it.
    if (ModalRoute.of(context)?.isCurrent == false) {
      return KeyEventResult.ignored;
    }

    // If a text field has focus, just unfocus it.
    final focusNode = FocusManager.instance.primaryFocus;
    if (focusNode != null &&
        focusNode.context != null &&
        focusNode.context!.widget is EditableText) {
      focusNode.unfocus();
      return KeyEventResult.handled;
    }

    // Nothing focused or open — collapse.
    appShellVm.setMode(AppMode.compact);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<AppShellViewModel>().mode;

    return Focus(
      onKeyEvent: _onKeyEvent,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: mode == AppMode.compact
            ? _DraggableCompactBar(key: const ValueKey('compact'))
            : const ExpandedShell(key: ValueKey('expanded')),
      ),
    );
  }
}

/// Wraps [CompactCounterBar] with drag-to-reposition via [GestureDetector].
class _DraggableCompactBar extends StatefulWidget {
  const _DraggableCompactBar({super.key});

  @override
  State<_DraggableCompactBar> createState() => _DraggableCompactBarState();
}

class _DraggableCompactBarState extends State<_DraggableCompactBar> {
  Offset _dragStartGlobal = Offset.zero;
  Offset _windowStartPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onDragStart,
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
      child: const CompactCounterBar(),
    );
  }

  void _onDragStart(DragStartDetails details) async {
    _dragStartGlobal = details.globalPosition;
    try {
      _windowStartPosition = await windowManager.getPosition();
    } catch (_) {
      // Ignore in test.
    }
  }

  void _onDragUpdate(DragUpdateDetails details) async {
    final delta = details.globalPosition - _dragStartGlobal;
    final newPos = _windowStartPosition + delta;
    try {
      await windowManager.setPosition(newPos);
    } catch (_) {
      // Ignore in test.
    }
  }

  void _onDragEnd(DragEndDetails details) async {
    try {
      final pos = await windowManager.getPosition();
      context.read<AppShellViewModel>().saveCompactPosition(pos.dx, pos.dy);
    } catch (_) {
      // Ignore in test.
    }
  }
}
```

- [ ] **Step 3: Run analyze**

Run: `flutter analyze lib/views/app_shell.dart`
Expected: No issues

- [ ] **Step 4: Commit**

```bash
git add lib/views/app_shell.dart
git commit -m "feat: add AppShell with mode crossfade, drag support, and Esc key handling"
```

---

## Task 5.2: Simplify TrayService

(Moved from Phase 1 — must be applied atomically with main.dart rewrite.)

**Files:**
- Modify: `lib/services/tray_service.dart`

- [ ] **Step 1: Rewrite TrayService**

Replace `lib/services/tray_service.dart` with:

```dart
// lib/services/tray_service.dart

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';

/// Manages the system tray icon and context menu.
///
/// Simplified: single "Quit DhikrAtWork" menu item.
/// Left-click: no action.
class TrayService with TrayListener {
  TrayService._();

  static final TrayService instance = TrayService._();

  VoidCallback? _onQuit;

  /// Must be called once after the tray icon asset is set in main.dart.
  Future<void> setup({required VoidCallback onQuit}) async {
    _onQuit = onQuit;

    trayManager.addListener(this);
    await trayManager.setToolTip('DhikrAtWork');

    final menu = Menu(
      items: [
        MenuItem(
          key: 'quit',
          label: 'Quit DhikrAtWork',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconMouseDown() {
    // No action on left-click per spec.
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'quit') {
      _onQuit?.call();
    }
  }

  void dispose() {
    trayManager.removeListener(this);
  }
}
```

- [ ] **Step 2: Commit** (commit together with Task 5.3 and 5.4)

---

## Task 5.3: Modify AppLocator

(Moved from Phase 1 — must be applied atomically with main.dart rewrite.)

**Files:**
- Modify: `lib/app/app_locator.dart`

- [ ] **Step 1: Rewrite AppLocator**

```dart
// lib/app/app_locator.dart

import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';

/// Top-level singleton registry for ViewModels that must be shared
/// across features without passing through the widget tree.
///
/// Holds only [CounterViewModel] and [SettingsViewModel].
/// [AppShellViewModel] is provided solely via the widget tree's Provider.
class AppLocator {
  AppLocator._();

  static AppLocator? _instance;
  static AppLocator get instance {
    assert(_instance != null,
        'AppLocator.initialize() must be called before accessing instance.');
    return _instance!;
  }

  late final CounterViewModel counterViewModel;
  late final SettingsViewModel settingsViewModel;

  static void initialize({
    required CounterViewModel counterViewModel,
    required SettingsViewModel settingsViewModel,
  }) {
    _instance = AppLocator._();
    _instance!.counterViewModel = counterViewModel;
    _instance!.settingsViewModel = settingsViewModel;
  }

  /// Reset for testing purposes only.
  static void reset() {
    _instance = null;
  }
}
```

- [ ] **Step 2: Commit** (commit together with Task 5.2 and 5.4)

---

## Task 5.4: Rewrite main.dart

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Read current main.dart**

Read `lib/main.dart` to understand the full structure.

- [ ] **Step 2: Rewrite main.dart**

Replace the entire file with:

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'package:dhikratwork/app/app_locator.dart';
import 'package:dhikratwork/app/theme.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';
import 'package:dhikratwork/repositories/session_repository.dart';
import 'package:dhikratwork/repositories/settings_repository.dart';
import 'package:dhikratwork/repositories/stats_repository.dart';
import 'package:dhikratwork/repositories/streak_repository.dart';
import 'package:dhikratwork/repositories/achievement_repository.dart';
import 'package:dhikratwork/repositories/goal_repository.dart';
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/services/subscription_service.dart';
import 'package:dhikratwork/services/tray_service.dart';
import 'package:dhikratwork/viewmodels/app_shell_viewmodel.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/dhikr_library_viewmodel.dart';
import 'package:dhikratwork/viewmodels/gamification_viewmodel.dart';
import 'package:dhikratwork/viewmodels/goal_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/viewmodels/stats_viewmodel.dart';
import 'package:dhikratwork/views/app_shell.dart';
import 'package:dhikratwork/views/shared/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Required for sqflite on Windows and macOS desktop.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Initialize window_manager before any other window operations.
  await _initMainWindow();

  // Show splash immediately while heavy init runs in the background.
  runApp(const SplashThenApp());
}

/// Holds all objects created during async initialisation.
class _AppDependencies {
  final DhikrRepository dhikrRepo;
  final SessionRepository sessionRepo;
  final SettingsRepository settingsRepo;
  final StatsRepository statsRepo;
  final GoalRepository goalRepo;
  final StreakRepository streakRepo;
  final AchievementRepository achievementRepo;
  final AppShellViewModel appShellVm;
  final CounterViewModel counterVm;
  final SettingsViewModel settingsVm;
  final DhikrLibraryViewModel dhikrLibraryVm;
  final StatsViewModel statsVm;
  final GamificationViewModel gamificationVm;
  final GoalViewModel goalVm;

  const _AppDependencies({
    required this.dhikrRepo,
    required this.sessionRepo,
    required this.settingsRepo,
    required this.statsRepo,
    required this.goalRepo,
    required this.streakRepo,
    required this.achievementRepo,
    required this.appShellVm,
    required this.counterVm,
    required this.settingsVm,
    required this.dhikrLibraryVm,
    required this.statsVm,
    required this.gamificationVm,
    required this.goalVm,
  });
}

/// Opens the database, creates repositories and ViewModels.
Future<_AppDependencies> _initDependencies() async {
  // Clear any stale hotkey registrations from prior runs.
  await hotKeyManager.unregisterAll();

  final db = DatabaseService();
  await db.open();

  final dhikrRepo = DhikrRepository(db);
  final sessionRepo = SessionRepository(db);
  final settingsRepo = SettingsRepository(db);
  final statsRepo = StatsRepository(db);
  final streakRepo = StreakRepository(db);
  final achievementRepo = AchievementRepository(db);
  final goalRepo = GoalRepository(db);

  // Build ViewModels — order matters for dependency injection.
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

  // Wire hotkey trigger callback to avoid circular construction dependency.
  settingsVm.setHotkeyTriggerCallback(
    () => counterVm.incrementActiveDhikr(source: 'hotkey'),
  );

  // Register shared ViewModels in AppLocator for cross-VM access.
  AppLocator.initialize(
    counterViewModel: counterVm,
    settingsViewModel: settingsVm,
  );

  return _AppDependencies(
    dhikrRepo: dhikrRepo,
    sessionRepo: sessionRepo,
    settingsRepo: settingsRepo,
    statsRepo: statsRepo,
    goalRepo: goalRepo,
    streakRepo: streakRepo,
    achievementRepo: achievementRepo,
    appShellVm: appShellVm,
    counterVm: counterVm,
    settingsVm: settingsVm,
    dhikrLibraryVm: DhikrLibraryViewModel(dhikrRepository: dhikrRepo),
    statsVm: StatsViewModel(
      statsRepository: statsRepo,
      streakRepository: streakRepo,
      dhikrRepository: dhikrRepo,
    ),
    gamificationVm: GamificationViewModel(
      achievementRepository: achievementRepo,
      streakRepository: streakRepo,
    ),
    goalVm: GoalViewModel(
      goalRepository: goalRepo,
      statsRepository: statsRepo,
    ),
  );
}

/// Wrapper that shows [SplashScreen] while [_initDependencies] runs,
/// then transitions to [DhikrAtWorkApp] with all providers.
class SplashThenApp extends StatefulWidget {
  const SplashThenApp({super.key});

  @override
  State<SplashThenApp> createState() => _SplashThenAppState();
}

class _SplashThenAppState extends State<SplashThenApp> {
  late final Future<_AppDependencies> _future;

  @override
  void initState() {
    super.initState();
    _future = _initDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppDependencies>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError) {
          return const SplashScreen();
        }
        final deps = snapshot.data!;
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: deps.appShellVm),
            ChangeNotifierProvider.value(value: deps.counterVm),
            ChangeNotifierProvider.value(value: deps.settingsVm),
            ChangeNotifierProvider.value(value: deps.dhikrLibraryVm),
            ChangeNotifierProvider.value(value: deps.statsVm),
            ChangeNotifierProvider.value(value: deps.gamificationVm),
            ChangeNotifierProvider.value(value: deps.goalVm),
            // Repositories as plain Providers for direct access.
            Provider<DhikrRepository>.value(value: deps.dhikrRepo),
            Provider<SessionRepository>.value(value: deps.sessionRepo),
            Provider<SettingsRepository>.value(value: deps.settingsRepo),
            Provider<StatsRepository>.value(value: deps.statsRepo),
            Provider<GoalRepository>.value(value: deps.goalRepo),
          ],
          child: const DhikrAtWorkApp(),
        );
      },
    );
  }
}

/// Configures main window: starts in compact mode (360x60, hidden title bar,
/// always-on-top, skip taskbar, top-right position).
Future<void> _initMainWindow() async {
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    title: 'DhikrAtWork',
    size: Size(360, 60),
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    // Position at top-right of screen.
    await windowManager.setAlignment(Alignment.topRight);
    await windowManager.show();
    await windowManager.focus();
  });
}

/// Root widget. Wires up theme + bootstrap (hotkey, tray, session resume).
class DhikrAtWorkApp extends StatefulWidget {
  const DhikrAtWorkApp({super.key});

  @override
  State<DhikrAtWorkApp> createState() => _DhikrAtWorkAppState();
}

class _DhikrAtWorkAppState extends State<DhikrAtWorkApp>
    with WindowListener, TrayListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    trayManager.addListener(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    final settingsRepo = context.read<SettingsRepository>();
    final settingsVm = context.read<SettingsViewModel>();
    final counterVm = context.read<CounterViewModel>();
    final appShellVm = context.read<AppShellViewModel>();

    // Load saved compact bar position.
    await appShellVm.loadSavedPosition();

    if (!mounted) return;

    // Register global hotkey using the stored settings value.
    final settings = await settingsRepo.getSettings();

    if (!mounted) return;

    await settingsVm.applyHotkeyFromString(settings.globalHotkey);

    // Resume active session if one exists.
    await counterVm.loadActiveSession();

    // Set up system tray icon (quit only).
    try {
      await trayManager.setIcon('assets/tray/tray_icon.png');
      await TrayService.instance.setup(
        onQuit: () async {
          // End active session before quitting.
          await counterVm.endSession();
          await hotKeyManager.unregisterAll();
          await windowManager.destroy();
        },
      );
    } catch (_) {
      // Tray icon may not be available in CI or if the asset is missing.
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  // WindowListener: close to tray instead of destroying.
  @override
  void onWindowClose() async {
    await windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DhikrAtWork',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );
  }
}
```

- [ ] **Step 3: Run analyze**

Run: `flutter analyze lib/main.dart lib/app/app_locator.dart lib/services/tray_service.dart`
Expected: No issues — all three files are now consistent

- [ ] **Step 4: Commit (Tasks 5.2 + 5.3 + 5.4 together)**

```bash
git add lib/main.dart lib/app/app_locator.dart lib/services/tray_service.dart
git commit -m "feat: rewrite main.dart, simplify AppLocator and TrayService for single-window architecture"
```

---

## Phase 5 Validation

```bash
flutter analyze
```

Expected: Warnings about old files that are no longer imported but still exist (Phase 6 cleanup). No errors in the new/modified files.
