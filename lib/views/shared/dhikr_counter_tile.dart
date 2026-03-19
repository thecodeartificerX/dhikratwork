// lib/views/shared/dhikr_counter_tile.dart

import 'package:flutter/material.dart';
import 'package:dhikratwork/models/dhikr.dart';

/// Reusable tile that displays a dhikr with its today count and supports
/// tap-to-increment. Used in the Dashboard quick-access grid and the
/// floating toolbar.
class DhikrCounterTile extends StatelessWidget {
  const DhikrCounterTile({
    super.key,
    required this.dhikr,
    required this.count,
    required this.onTap,
    this.isActive = false,
  });

  final Dhikr dhikr;
  final int count;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: dhikr.translation,
      child: Card(
        color: isActive
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Arabic text — large, selectable, correct font direction.
                SelectableText(
                  dhikr.arabicText,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Amiri',
                    color: isActive
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                    height: 1.8, // Extra line height for tashkeel clearance.
                  ),
                ),
                const SizedBox(height: 4),
                // Transliteration.
                Text(
                  dhikr.transliteration,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                // Today's count badge.
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    count.toString(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isActive
                          ? colorScheme.onPrimary
                          : colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
