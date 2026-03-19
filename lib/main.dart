// lib/main.dart

import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'package:dhikratwork/app/app_locator.dart';
import 'package:dhikratwork/app/theme.dart';
import 'package:dhikratwork/repositories/achievement_repository.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';
import 'package:dhikratwork/repositories/goal_repository.dart';
import 'package:dhikratwork/repositories/session_repository.dart';
import 'package:dhikratwork/repositories/settings_repository.dart';
import 'package:dhikratwork/repositories/stats_repository.dart';
import 'package:dhikratwork/repositories/streak_repository.dart';
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
  // Initialize hotkey_manager (clears any stale registrations from prev runs).
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

  // Register shared ViewModels in AppLocator for cross-feature access.
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
            // Repositories as plain Providers for screens that need direct access.
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

/// Configures the main window as a small, always-on-top compact bar
/// positioned in the top-right corner of the screen.
///
/// NOTE: For production builds, also patch:
///   - windows/runner/main.cpp: remove window.Show(), add SetQuitOnClose(false)
///   - macos/Runner/AppDelegate.swift: return false from
///     applicationShouldTerminateAfterLastWindowClosed
///   - macos/Runner/DebugProfile.entitlements: disable sandbox
/// These native file changes are required for hotkey_manager and tray_manager.
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
    await windowManager.setAlignment(Alignment.topRight);
    await windowManager.show();
    await windowManager.focus();
  });
}

/// Root widget. Wires up theme + tray + hotkey bootstrap.
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

    // Capture context-dependent objects before any awaits.
    final appShellVm = context.read<AppShellViewModel>();
    final settingsRepo = context.read<SettingsRepository>();
    final settingsVm = context.read<SettingsViewModel>();
    final counterVm = context.read<CounterViewModel>();

    // Load saved compact window position.
    await appShellVm.loadSavedPosition();

    if (!mounted) return;

    // Register global hotkey using the stored settings value.
    final settings = await settingsRepo.getSettings();

    if (!mounted) return;

    await settingsVm.applyHotkeyFromString(settings.globalHotkey);

    if (!mounted) return;

    // Resume any active dhikr session from the previous run.
    await counterVm.loadActiveSession();

    if (!mounted) return;

    // Set up system tray icon.
    // NOTE: Tray icon asset (assets/tray/tray_icon.png) must exist.
    // For Windows production, provide a .ico file. PNG fallback works for dev.
    try {
      await trayManager.setIcon('assets/tray/tray_icon.png');
      await TrayService.instance.setup(
        onQuit: () async {
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

  // Intercept close button: hide to tray instead of closing.
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
