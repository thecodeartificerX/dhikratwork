// lib/views/stats/goal_progress_card.dart
import 'package:flutter/material.dart';
import '../../models/goal.dart';

class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({
    super.key,
    required this.goal,
    required this.progress,
  });

  final Goal goal;
  final double progress; // 0.0 - 1.0

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percent = (progress * 100).toInt();
    final periodLabel = switch (goal.period) {
      'daily' => 'Daily',
      'weekly' => 'Weekly',
      'monthly' => 'Monthly',
      _ => goal.period,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$periodLabel goal: ${goal.targetCount} presses',
                  style: theme.textTheme.bodyMedium,
                ),
                SelectableText(
                  '$percent%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: progress >= 1.0
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      height: 8,
                      width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        color: progress >= 1.0
                            ? colorScheme.primary
                            : colorScheme.secondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
