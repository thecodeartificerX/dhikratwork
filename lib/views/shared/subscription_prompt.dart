// lib/views/shared/subscription_prompt.dart

import 'dart:io' show Platform;
import 'package:flutter/material.dart';

/// Dismissable modal shown on every app launch to non-subscribers.
/// Donation-transparent, no "don't show again" option per spec.
class SubscriptionPrompt extends StatelessWidget {
  const SubscriptionPrompt({
    super.key,
    required this.onSubscribe,
    required this.onDismiss,
  });

  final VoidCallback onSubscribe;
  final VoidCallback onDismiss;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onSubscribe,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SubscriptionPrompt(
        onSubscribe: onSubscribe,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.volunteer_activism, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Support DhikrAtWork'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All proceeds are donated for the sake of Allah.',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'None of the subscription fee is kept — 100% goes to those in need. '
              'Your subscription keeps this app maintained and ad-free.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: colorScheme.onSecondaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can use the full app for free. '
                      'The subscription is entirely optional.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Windows: confirm (Subscribe) on left, cancel (Continue) on right.
        // macOS: confirm on right, cancel on left.
        Row(
          textDirection: Platform.isWindows
              ? TextDirection.rtl
              : TextDirection.ltr,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: onDismiss,
              child: const Text('Continue for free'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onSubscribe,
              icon: const Icon(Icons.favorite),
              label: const Text('Subscribe — \$5/month'),
            ),
          ],
        ),
      ],
    );
  }
}
