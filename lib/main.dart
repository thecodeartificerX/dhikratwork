// lib/main.dart

import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'package:dhikratwork/app/app_locator.dart';
import 'package:dhikratwork/app/router.dart';
import 'package:dhikratwork/app/theme.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';
import 'package:dhikratwork/repositories/session_repository.dart';
import 'package:dhikratwork/repositories/settings_repository.dart';
import 'package:dhikratwork/repositories/stats_repository.dart';
import 'package:dhikratwork/repositories/streak_repository.dart';
import 'package:dhikratwork/repositories/achievement_repository.dart';
import 'package:dhikratwork/repositories/goal_repository.dart';
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/services/floating_window_manager.dart';
import 'package:dhikratwork/services/subscription_service.dart';
import 'package:dhikratwork/services/tray_service.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/dhikr_library_viewmodel.dart';
import 'package:dhikratwork/viewmodels/dashboard_viewmodel.dart';
import 'package:dhikratwork/viewmodels/gamification_viewmodel.dart';
import 'package:dhikratwork/viewmodels/goal_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/viewmodels/stats_viewmodel.dart';
import 'package:dhikratwork/viewmodels/widget_toolbar_viewmodel.dart';
import 'package:dhikratwork/views/shared/subscription_prompt.dart';
import 'package:dhikratwork/views/widget/floating_toolbar.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // desktop_multi_window v0.3.0: each sub-window is a separate Flutter engine.
  // The sub-window's main() is called with arguments set via WindowConfiguration.
  // Detect sub-window by inspecting WindowController.fromCurrentEngine().arguments.
  final windowController = await WindowController.fromCurrentEngine();
  final rawArguments = windowController.arguments;
  if (rawArguments.isNotEmpty) {
    try {
      final argMap = jsonDecode(rawArguments) as Map<String, dynamic>;
      if (argMap['type'] == 'floating_toolbar') {
        await _runFloatingWindow(windowController, argMap);
        return;
      }
    } catch (_) {
      // Not JSON or unexpected format — treat as main window.
    }
  }

  // --- Main window startup ---

  // Required for sqflite on Windows and macOS desktop.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Initialize window_manager before any other window operations.
  await _initMainWindow();

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
  final widgetToolbarVm = WidgetToolbarViewModel(
    dhikrRepository: dhikrRepo,
    settingsRepository: settingsRepo,
    sessionRepository: sessionRepo,
  );

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
    subscriptionService: FirestoreSubscriptionService(),
  );

  // Wire hotkey trigger callback to avoid circular construction dependency.
  settingsVm.setHotkeyTriggerCallback(
    () => counterVm.incrementActiveDhikr(source: 'hotkey'),
  );

  // Register shared ViewModels in AppLocator for cross-VM access.
  AppLocator.initialize(
    widgetToolbarViewModel: widgetToolbarVm,
    counterViewModel: counterVm,
    settingsViewModel: settingsVm,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widgetToolbarVm),
        ChangeNotifierProvider.value(value: counterVm),
        ChangeNotifierProvider.value(value: settingsVm),
        ChangeNotifierProvider(
          create: (_) => DhikrLibraryViewModel(
            dhikrRepository: dhikrRepo,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardViewModel(
            dhikrRepository: dhikrRepo,
            statsRepository: statsRepo,
            streakRepository: streakRepo,
            settingsRepository: settingsRepo,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => StatsViewModel(
            statsRepository: statsRepo,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => GamificationViewModel(
            achievementRepository: achievementRepo,
            streakRepository: streakRepo,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => GoalViewModel(
            goalRepository: goalRepo,
            statsRepository: statsRepo,
          ),
        ),
        // Repositories as plain Providers for screens that need direct access.
        Provider<DhikrRepository>.value(value: dhikrRepo),
        Provider<SessionRepository>.value(value: sessionRepo),
        Provider<SettingsRepository>.value(value: settingsRepo),
        Provider<StatsRepository>.value(value: statsRepo),
        Provider<GoalRepository>.value(value: goalRepo),
      ],
      child: const DhikrAtWorkApp(),
    ),
  );
}

/// Configures main window appearance via window_manager.
///
/// NOTE (Step 2/3): For production builds, also patch:
///   - windows/runner/main.cpp: remove window.Show(), add SetQuitOnClose(false)
///   - macos/Runner/AppDelegate.swift: return false from
///     applicationShouldTerminateAfterLastWindowClosed
///   - macos/Runner/DebugProfile.entitlements: disable sandbox
/// These native file changes are required for hotkey_manager and tray_manager.
Future<void> _initMainWindow() async {
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    title: 'DhikrAtWork',
    size: Size(1100, 750),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

/// Entry point for the floating toolbar sub-window.
///
/// Called when desktop_multi_window v0.3.0 creates a sub-window with
/// 'floating_toolbar' type in its arguments.
///
/// IMPORTANT (desktop_multi_window v0.3.0 isolate boundary):
/// Each sub-window is a completely separate Flutter engine / Dart isolate.
/// The main window's AppLocator is NOT accessible here. The floating toolbar
/// maintains its own repository/ViewModel instances and synchronizes state
/// with the main window via WindowMethodChannel IPC.
Future<void> _runFloatingWindow(
    WindowController controller, Map<String, dynamic> args) async {
  // Required for sqflite on Windows and macOS desktop.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = DatabaseService();
  await db.open();

  final dhikrRepo = DhikrRepository(db);
  final sessionRepo = SessionRepository(db);
  final settingsRepo = SettingsRepository(db);

  final widgetToolbarVm = WidgetToolbarViewModel(
    dhikrRepository: dhikrRepo,
    settingsRepository: settingsRepo,
    sessionRepository: sessionRepo,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widgetToolbarVm),
      ],
      child: FloatingToolbarApp(windowId: controller.windowId),
    ),
  );
}

/// Root widget. Wires up theme + go_router + tray + hotkey bootstrap.
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
    final widgetToolbarVm = context.read<WidgetToolbarViewModel>();
    final settingsRepo = context.read<SettingsRepository>();
    final settingsVm = context.read<SettingsViewModel>();

    // Load toolbar dhikrs.
    await widgetToolbarVm.loadToolbar();

    if (!mounted) return;

    // Register global hotkey using the stored settings value.
    final settings = await settingsRepo.getSettings();

    if (!mounted) return;

    await settingsVm.applyHotkeyFromString(settings.globalHotkey);

    // Set up system tray icon.
    // NOTE: Tray icon asset (assets/tray/tray_icon.png) must exist.
    // For Windows production, provide a .ico file. PNG fallback works for dev.
    try {
      await trayManager.setIcon('assets/tray/tray_icon.png');
      await TrayService.instance.setup(
        onShowMainWindow: () => windowManager.show(),
        onHideMainWindow: () => windowManager.hide(),
        onQuit: () async {
          await hotKeyManager.unregisterAll();
          await windowManager.destroy();
        },
        widgetToolbarViewModel: widgetToolbarVm,
      );
    } catch (_) {
      // Tray icon may not be available in CI or if the asset is missing.
    }

    // Show floating widget if it was visible on last run.
    FloatingWindowManager.instance.showFloatingWidget(
      initialX: settings.widgetPositionX,
      initialY: settings.widgetPositionY,
    );

    // Show subscription prompt if needed.
    if (mounted) {
      _showSubscriptionPromptIfNeeded();
    }
  }

  Future<void> _showSubscriptionPromptIfNeeded() async {
    if (!mounted) return;
    await SubscriptionPrompt.show(
      context,
      onSubscribe: () {
        Navigator.of(context).pop();
      },
    );
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
    return MaterialApp.router(
      title: 'DhikrAtWork',
      theme: buildAppTheme(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
