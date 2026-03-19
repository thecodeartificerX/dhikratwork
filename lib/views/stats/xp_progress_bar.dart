// lib/views/stats/xp_progress_bar.dart
import 'package:flutter/material.dart';

class XpProgressBar extends StatelessWidget {
  const XpProgressBar({
    super.key,
    required this.levelName,
    required this.currentLevel,
    required this.totalXp,
    required this.xpForNextLevel,
    required this.progress,
    required this.currentStreak,
    required this.longestStreak,
  });

  final String levelName;
  final int currentLevel;
  final int totalXp;
  final int xpForNextLevel;
  final double progress; // 0.0 - 1.0
  final int currentStreak;
  final int longestStreak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(levelName, style: theme.textTheme.titleLarge),
                    Text(
                      'Level $currentLevel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SelectableText(
                      '$totalXp XP',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Next level: $xpForNextLevel XP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // XP progress bar using AnimatedContainer for implicit animation
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      height: 12,
                      width: constraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Streak info
            Row(
              children: [
                _StreakChip(
                  label: 'Current Streak',
                  value: '$currentStreak days',
                  icon: Icons.local_fire_department,
                ),
                const SizedBox(width: 12),
                _StreakChip(
                  label: 'Best Streak',
                  value: '$longestStreak days',
                  icon: Icons.emoji_events,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({
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
    return Tooltip(
      message: label,
      child: Chip(
        avatar: Icon(icon, size: 16),
        label: SelectableText(value, style: theme.textTheme.labelMedium),
      ),
    );
  }
}
