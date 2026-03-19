// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dhikratwork/app/router.dart';
import 'package:dhikratwork/app/theme.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';
import 'package:dhikratwork/repositories/session_repository.dart';
import 'package:dhikratwork/repositories/stats_repository.dart';
import 'package:dhikratwork/repositories/streak_repository.dart';
import 'package:dhikratwork/repositories/achievement_repository.dart';
import 'package:dhikratwork/repositories/goal_repository.dart';
import 'package:dhikratwork/repositories/settings_repository.dart';
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/services/subscription_service.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/dhikr_library_viewmodel.dart';
import 'package:dhikratwork/viewmodels/dashboard_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/viewmodels/stats_viewmodel.dart';
import 'package:dhikratwork/viewmodels/gamification_viewmodel.dart';
import 'package:dhikratwork/viewmodels/goal_viewmodel.dart';
import 'package:dhikratwork/views/shared/subscription_prompt.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Required for sqflite on Windows and macOS desktop.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Phase 2 outputs — repositories wired to real DatabaseService.
  final db = DatabaseService();
  await db.open();

  final dhikrRepo = DhikrRepository(db);
  final sessionRepo = SessionRepository(db);
  final statsRepo = StatsRepository(db);
  final streakRepo = StreakRepository(db);
  final achievementRepo = AchievementRepository(db);
  final settingsRepo = SettingsRepository(db);
  final goalRepo = GoalRepository(db);

  runApp(
    MultiProvider(
      providers: [
        // CounterViewModel is app-wide: hotkey handler lives outside any route.
        ChangeNotifierProvider(
          create: (_) => CounterViewModel(
            dhikrRepository: dhikrRepo,
            sessionRepository: sessionRepo,
            statsRepository: statsRepo,
            streakRepository: streakRepo,
            achievementRepository: achievementRepo,
            settingsRepository: settingsRepo,
          ),
        ),
        // DhikrLibraryViewModel is app-wide: detail screen and library screen
        // share the same loaded list.
        ChangeNotifierProvider(
          create: (_) => DhikrLibraryViewModel(
            dhikrRepository: dhikrRepo,
          ),
        ),
        // DashboardViewModel is app-wide: refreshSummary() called after any
        // increment from any source.
        ChangeNotifierProvider(
          create: (_) => DashboardViewModel(
            dhikrRepository: dhikrRepo,
            statsRepository: statsRepo,
            streakRepository: streakRepo,
            settingsRepository: settingsRepo,
          ),
        ),
        // SettingsViewModel manages settings state and subscription verification.
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel(
            settingsRepository: settingsRepo,
            dhikrRepository: dhikrRepo,
            subscriptionService: FirestoreSubscriptionService(),
          ),
        ),
        // Phase 5: Stats & Gamification ViewModels
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
      ],
      child: const DhikrAtWorkApp(),
    ),
  );
}

/// Root widget. Wires up theme + go_router + subscription prompt.
class DhikrAtWorkApp extends StatefulWidget {
  const DhikrAtWorkApp({super.key});

  @override
  State<DhikrAtWorkApp> createState() => _DhikrAtWorkAppState();
}

class _DhikrAtWorkAppState extends State<DhikrAtWorkApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSubscriptionPromptIfNeeded();
    });
  }

  Future<void> _showSubscriptionPromptIfNeeded() async {
    // Full SettingsViewModel lands in Phase 4 — for now, always show prompt.
    await SubscriptionPrompt.show(
      context,
      onSubscribe: () {
        Navigator.of(context).pop();
        // url_launcher → Stripe Checkout: Phase 4.
      },
    );
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
