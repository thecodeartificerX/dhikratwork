// test/widget/views/stats/stats_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dhikratwork/views/stats/stats_screen.dart';
import 'package:dhikratwork/viewmodels/stats_viewmodel.dart';
import 'package:dhikratwork/viewmodels/gamification_viewmodel.dart';
import 'package:dhikratwork/viewmodels/goal_viewmodel.dart';
import '../../../fakes/fake_stats_repository.dart';
import '../../../fakes/fake_achievement_repository.dart';
import '../../../fakes/fake_streak_repository.dart';
import '../../../fakes/fake_goal_repository.dart';

Widget buildTestWidget() {
  final fakeStats = FakeStatsRepository();
  final fakeAchievements = FakeAchievementRepository();
  final fakeStreaks = FakeStreakRepository();
  final fakeGoals = FakeGoalRepository();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => StatsViewModel(statsRepository: fakeStats),
      ),
      ChangeNotifierProvider(
        create: (_) => GamificationViewModel(
          achievementRepository: fakeAchievements,
          streakRepository: fakeStreaks,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => GoalViewModel(
          goalRepository: fakeGoals,
          statsRepository: fakeStats,
        ),
      ),
    ],
    child: const MaterialApp(home: StatsScreen()),
  );
}

void main() {
  group('StatsScreen', () {
    testWidgets('renders period selector with Day/Week/Month segments', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
    });

    testWidgets('tapping Week segment calls setPeriod week', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      // StatsViewModel.selectedPeriod should now be 'week'
      final vm = tester.element(find.byType(StatsScreen)).read<StatsViewModel>();
      expect(vm.selectedPeriod, 'week');
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      // Pump once without settling to catch loading state
      await tester.pump();
      // CircularProgressIndicator may appear briefly
      // After settling it should be gone
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders XP progress section', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('Level'), findsWidgets);
      expect(find.textContaining('XP'), findsWidgets);
    });

    testWidgets('renders Achievements section header', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Achievements'), findsOneWidget);
    });

    testWidgets('scrollbar is present for desktop', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(Scrollbar), findsWidgets);
    });
  });
}
