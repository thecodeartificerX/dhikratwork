// lib/views/shared/dhikr_selection_dialog.dart

import 'package:flutter/material.dart';
import 'package:dhikratwork/models/dhikr.dart';

/// Confirmation dialog shown when a user taps a dhikr item to set it active.
/// Returns [true] via [Navigator.pop] on confirm, [false] or null on cancel.
class DhikrSelectionDialog extends StatelessWidget {
  const DhikrSelectionDialog({
    super.key,
    required this.dhikr,
  });

  final Dhikr dhikr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(dhikr.name),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                dhikr.arabicText,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              dhikr.transliteration,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dhikr.translation,
              style: theme.textTheme.bodyMedium,
            ),
            if (dhikr.targetCount != null) ...[
              const SizedBox(height: 12),
              Text(
                'Target: ${dhikr.targetCount} counts',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Set Active'),
        ),
      ],
    );
  }
}
