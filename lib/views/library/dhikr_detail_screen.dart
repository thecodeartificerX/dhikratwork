// lib/views/library/dhikr_detail_screen.dart

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/viewmodels/dhikr_library_viewmodel.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';

class DhikrDetailScreen extends StatelessWidget {
  const DhikrDetailScreen({super.key, required this.dhikrId});

  final int dhikrId;

  @override
  Widget build(BuildContext context) {
    return Consumer<DhikrLibraryViewModel>(
      builder: (context, vm, _) {
        final dhikr = vm.dhikrList
            .where((d) => d.id == dhikrId)
            .firstOrNull;

        if (dhikr == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dhikr')),
            body: const Center(child: Text('Dhikr not found.')),
          );
        }

        return _DhikrDetailView(dhikr: dhikr, vm: vm);
      },
    );
  }
}

class _DhikrDetailView extends StatelessWidget {
  const _DhikrDetailView({required this.dhikr, required this.vm});

  final Dhikr dhikr;
  final DhikrLibraryViewModel vm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(dhikr.name),
        leading: Tooltip(
          message: 'Back to Library',
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/library'),
          ),
        ),
        actions: [
          if (!dhikr.isPreloaded)
            Tooltip(
              message: 'Delete',
              child: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context),
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Arabic text — large, selectable.
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          SelectableText(
                            dhikr.arabicText,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontFamily: 'Amiri',
                              height: 2.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            dhikr.transliteration,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            dhikr.translation,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                          if (dhikr.hadithReference != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Source: ${dhikr.hadithReference}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Actions.
                  _ActionButtons(dhikr: dhikr),
                  if (dhikr.targetCount != null) ...[
                    const SizedBox(height: 20),
                    _TargetCountCard(dhikr: dhikr),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Dhikr'),
        content: Text('Delete "${dhikr.name}"? This cannot be undone.'),
        actions: [
          Row(
            textDirection: Platform.isWindows
                ? TextDirection.rtl
                : TextDirection.ltr,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<DhikrLibraryViewModel>().deleteDhikr(dhikr.id!);
      if (context.mounted) context.go('/library');
    }
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.dhikr});

  final Dhikr dhikr;

  @override
  Widget build(BuildContext context) {
    final counterVm = context.read<CounterViewModel>();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        Tooltip(
          message: 'Make this the target for the global hotkey',
          child: FilledButton.icon(
            onPressed: () async {
              await counterVm.setActiveDhikr(dhikr.id!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${dhikr.name}" is now the active dhikr.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.keyboard),
            label: const Text('Set as Active'),
          ),
        ),
        Tooltip(
          message: 'Add to floating widget toolbar',
          child: OutlinedButton.icon(
            onPressed: () {
              // WidgetToolbarViewModel integration — Phase 4.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Widget toolbar — coming in Phase 4.')),
              );
            },
            icon: const Icon(Icons.widgets_outlined),
            label: const Text('Add to Widget'),
          ),
        ),
        Tooltip(
          message: 'Set a daily or weekly goal',
          child: OutlinedButton.icon(
            onPressed: () {
              // GoalViewModel integration — Phase 4.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Goals — coming in Phase 4.')),
              );
            },
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Set Goal'),
          ),
        ),
      ],
    );
  }
}

class _TargetCountCard extends StatelessWidget {
  const _TargetCountCard({required this.dhikr});

  final Dhikr dhikr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.track_changes, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Text(
              'Recommended count: ${dhikr.targetCount}×',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
