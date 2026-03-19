// test/widget/views/expanded/stats_tab_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dhikratwork/viewmodels/stats_viewmodel.dart';
import 'package:dhikratwork/viewmodels/gamification_viewmodel.dart';
import 'package:dhikratwork/viewmodels/goal_viewmodel.dart';
import 'package:dhikratwork/views/expanded/stats_tab.dart';
import '../../../fakes/fake_stats_repository.dart';
import '../../../fakes/fake_streak_repository.dart';
import '../../../fakes/fake_dhikr_repository.dart';
import '../../../fakes/fake_achievement_repository.dart';
import '../../../fakes/fake_goal_repository.dart';

Widget _buildTestApp() {
  final statsRepo = FakeStatsRepository();
  final streakRepo = FakeStreakRepository();
  final dhikrRepo = FakeDhikrRepository();
  final achievementRepo = FakeAchievementRepository();
  final goalRepo = FakeGoalRepository();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<StatsViewModel>(
        create: (_) => StatsViewModel(
          statsRepository: statsRepo,
          streakRepository: streakRepo,
          dhikrRepository: dhikrRepo,
        ),
      ),
      ChangeNotifierProvider<GamificationViewModel>(
        create: (_) => GamificationViewModel(
          achievementRepository: achievementRepo,
          streakRepository: streakRepo,
        ),
      ),
      ChangeNotifierProvider<GoalViewModel>(
        create: (_) => GoalViewModel(
          goalRepository: goalRepo,
          statsRepository: statsRepo,
        ),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: StatsTab()),
    ),
  );
}

void main() {
  group('StatsTab', () {
    testWidgets('period selector renders Day/Week/Month', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
    });

    testWidgets('stat cards row renders Total and Streak labels',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
    });

    testWidgets('XP section renders', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // XpProgressBar shows level name and XP
      expect(find.textContaining('XP'), findsWidgets);
    });

    testWidgets('Achievements header renders', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Achievements'), findsOneWidget);
    });

    testWidgets('Goals section header renders', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Goals'), findsOneWidget);
    });

    testWidgets('Level stat card renders', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Level'), findsOneWidget);
    });
  });
}
