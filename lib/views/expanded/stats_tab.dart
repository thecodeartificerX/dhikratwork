// lib/views/expanded/stats_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dhikratwork/viewmodels/stats_viewmodel.dart';
import 'package:dhikratwork/viewmodels/gamification_viewmodel.dart';
import 'package:dhikratwork/viewmodels/goal_viewmodel.dart';
import 'package:dhikratwork/views/stats/stats_bar_chart.dart';
import 'package:dhikratwork/views/stats/stats_line_chart.dart';
import 'package:dhikratwork/views/stats/xp_progress_bar.dart';
import 'package:dhikratwork/views/stats/goal_progress_card.dart';
import 'package:dhikratwork/views/shared/achievement_badge.dart';

/// The Stats tab in the expanded shell.
/// Shows period selector, stat cards, XP progress, charts, achievements, goals.
class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final statsVm = context.watch<StatsViewModel>();
    final gamVm = context.watch<GamificationViewModel>();
    final goalVm = context.watch<GoalViewModel>();

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period selector
            _PeriodSelector(
              selectedPeriod: statsVm.selectedPeriod,
              onPeriodChanged: (period) => statsVm.setPeriod(period),
            ),

            const SizedBox(height: 16),

            // Stat cards row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Total',
                    value: statsVm.isLoading
                        ? '...'
                        : statsVm.totalCountForPeriod.toString(),
                    icon: Icons.numbers,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'Streak',
                    value: statsVm.isLoading
                        ? '...'
                        : '${statsVm.currentStreak} days',
                    icon: Icons.local_fire_department,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'Level',
                    value: gamVm.isLoading
                        ? '...'
                        : gamVm.levelName,
                    icon: Icons.emoji_events,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // XP progress bar
            if (!gamVm.isLoading)
              XpProgressBar(
                levelName: gamVm.levelName,
                currentLevel: gamVm.currentLevel,
                totalXp: gamVm.totalXp,
                xpForNextLevel: gamVm.xpForNextLevel,
                progress: gamVm.xpProgress,
                currentStreak: gamVm.currentStreak,
                longestStreak: gamVm.longestStreak,
              ),

            const SizedBox(height: 16),

            // Charts
            if (statsVm.isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text('By Dhikr', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: StatsBarChart(data: statsVm.barChartData),
              ),
              const SizedBox(height: 16),
              Text('Over Time', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: StatsLineChart(data: statsVm.lineChartData),
              ),
            ],

            const SizedBox(height: 16),

            // Achievements section
            Text('Achievements', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (gamVm.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (gamVm.achievements.isEmpty)
              Text(
                'No achievements yet.',
                style: theme.textTheme.bodyMedium,
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: gamVm.achievements
                    .map((a) => AchievementBadge(achievement: a))
                    .toList(),
              ),

            const SizedBox(height: 16),

            // Goals section
            Text('Goals', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (goalVm.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (goalVm.goals.isEmpty)
              Text(
                'No active goals.',
                style: theme.textTheme.bodyMedium,
              )
            else
              ...goalVm.goals.map((goal) {
                final progress = goalVm.goalProgress[goal.id] ?? 0.0;
                return GoalProgressCard(goal: goal, progress: progress);
              }),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment<String>(value: 'day', label: Text('Day')),
        ButtonSegment<String>(value: 'week', label: Text('Week')),
        ButtonSegment<String>(value: 'month', label: Text('Month')),
      ],
      selected: {selectedPeriod},
      onSelectionChanged: (set) {
        if (set.isNotEmpty) onPeriodChanged(set.first);
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            SelectableText(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
