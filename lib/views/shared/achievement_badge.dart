// lib/views/shared/achievement_badge.dart

import 'package:flutter/material.dart';
import 'package:dhikratwork/models/achievement.dart';

/// Displays a single achievement badge. Locked badges are greyed and
/// semi-transparent.
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.achievement,
  });

  final Achievement achievement;

  bool get _isUnlocked => achievement.unlockedAt != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: _isUnlocked
          ? achievement.description
          : 'Locked: ${achievement.description}',
      child: Opacity(
        opacity: _isUnlocked ? 1.0 : 0.35,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isUnlocked
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                border: _isUnlocked
                    ? Border.all(
                        color: colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: _isUnlocked
                  ? Image.asset(
                      achievement.iconAsset,
                      width: 32,
                      height: 32,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.star,
                        color: colorScheme.primary,
                      ),
                    )
                  : Icon(
                      Icons.lock,
                      size: 24,
                      color: colorScheme.onSurfaceVariant,
                    ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 64,
              child: SelectableText(
                achievement.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _isUnlocked
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontWeight:
                      _isUnlocked ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
