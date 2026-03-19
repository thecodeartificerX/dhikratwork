// lib/views/stats/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/stats_viewmodel.dart';
import '../../viewmodels/gamification_viewmodel.dart';
import '../../viewmodels/goal_viewmodel.dart';
import '../shared/achievement_badge.dart';
import 'stats_bar_chart.dart';
import 'stats_line_chart.dart';
import 'xp_progress_bar.dart';
import 'goal_progress_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsViewModel>().loadStats();
      context.read<GamificationViewModel>().loadGamification();
      context.read<GoalViewModel>().loadGoals();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats & Progress'),
      ),
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PeriodSelectorSection(),
              SizedBox(height: 24),
              _LevelXpSection(),
              SizedBox(height: 24),
              _ChartsSection(),
              SizedBox(height: 24),
              _GoalsSection(),
              SizedBox(height: 24),
              _AchievementsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Period Selector ────────────────────────────────────────────────────────────

class _PeriodSelectorSection extends StatelessWidget {
  const _PeriodSelectorSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsViewModel>(
      builder: (context, vm, _) {
        return SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'day', label: Text('Day')),
            ButtonSegment(value: 'week', label: Text('Week')),
            ButtonSegment(value: 'month', label: Text('Month')),
          ],
          selected: {vm.selectedPeriod},
          onSelectionChanged: (selection) {
            context.read<StatsViewModel>().setPeriod(selection.first);
          },
        );
      },
    );
  }
}

// ── Level + XP Progress Bar ────────────────────────────────────────────────────

class _LevelXpSection extends StatelessWidget {
  const _LevelXpSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) return const SizedBox.shrink();
        return XpProgressBar(
          levelName: vm.levelName,
          currentLevel: vm.currentLevel,
          totalXp: vm.totalXp,
          xpForNextLevel: vm.xpForNextLevel,
          progress: vm.xpProgress,
          currentStreak: vm.currentStreak,
          longestStreak: vm.longestStreak,
        );
      },
    );
  }
}

// ── Charts ────────────────────────────────────────────────────────────────────

class _ChartsSection extends StatelessWidget {
  const _ChartsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.errorMessage != null) {
          return Text(vm.errorMessage!, style: const TextStyle(color: Colors.red));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Counts by Dhikr', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: StatsBarChart(data: vm.barChartData),
            ),
            const SizedBox(height: 24),
            Text('Daily Totals', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: StatsLineChart(data: vm.lineChartData),
            ),
          ],
        );
      },
    );
  }
}

// ── Goals ─────────────────────────────────────────────────────────────────────

class _GoalsSection extends StatelessWidget {
  const _GoalsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading || vm.goals.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Goals', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...vm.goals.map((goal) => GoalProgressCard(
                  goal: goal,
                  progress: vm.goalProgress[goal.id] ?? 0.0,
                )),
          ],
        );
      },
    );
  }
}

// ── Achievements ──────────────────────────────────────────────────────────────

class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Achievements', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 120,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: vm.achievements.length,
              itemBuilder: (context, index) {
                final achievement = vm.achievements[index];
                return AchievementBadge(achievement: achievement);
              },
            ),
          ],
        );
      },
    );
  }
}
