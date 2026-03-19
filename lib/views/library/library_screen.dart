// lib/views/library/library_screen.dart

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dhikratwork/viewmodels/dhikr_library_viewmodel.dart';
import 'package:dhikratwork/models/dhikr.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DhikrLibraryViewModel>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dhikr Library'),
        leading: Tooltip(
          message: 'Back to Dashboard',
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
        ),
        actions: [
          Tooltip(
            message: 'Add Custom Dhikr',
            child: FilledButton.icon(
              onPressed: () => context.go('/library/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Custom'),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<DhikrLibraryViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return _LibraryBody(vm: vm);
        },
      ),
    );
  }
}

class _LibraryBody extends StatelessWidget {
  const _LibraryBody({required this.vm});

  final DhikrLibraryViewModel vm;

  /// The canonical category order for display.
  static const List<String> _categoryOrder = [
    'general_tasbih',
    'post_salah',
    'istighfar',
    'salawat',
    'dua_remembrance',
  ];

  static const Map<String, String> _categoryLabels = {
    'general_tasbih': 'General Tasbih',
    'post_salah': 'Post-Salah',
    'istighfar': 'Istighfar',
    'salawat': 'Salawat',
    'dua_remembrance': 'Dua & Remembrance',
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sidebar: category filter.
            SizedBox(
              width: 200,
              child: _CategorySidebar(vm: vm),
            ),
            const VerticalDivider(width: 1),
            // Main list.
            Expanded(
              child: _DhikrList(
                vm: vm,
                categoryOrder: _categoryOrder,
                categoryLabels: _categoryLabels,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategorySidebar extends StatefulWidget {
  const _CategorySidebar({required this.vm});

  final DhikrLibraryViewModel vm;

  @override
  State<_CategorySidebar> createState() => _CategorySidebarState();
}

class _CategorySidebarState extends State<_CategorySidebar> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static const _categories = {
    null: 'All',
    'general_tasbih': 'General Tasbih',
    'post_salah': 'Post-Salah',
    'istighfar': 'Istighfar',
    'salawat': 'Salawat',
    'dua_remembrance': 'Dua & Remembrance',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: _categories.entries.map((entry) {
          final isSelected = widget.vm.selectedCategory == entry.key;
          return ListTile(
            selected: isSelected,
            selectedColor: colorScheme.primary,
            selectedTileColor: colorScheme.primaryContainer,
            title: Text(entry.value),
            onTap: () => context
                .read<DhikrLibraryViewModel>()
                .filterByCategory(entry.key),
          );
        }).toList(),
      ),
    );
  }
}

class _DhikrList extends StatefulWidget {
  const _DhikrList({
    required this.vm,
    required this.categoryOrder,
    required this.categoryLabels,
  });

  final DhikrLibraryViewModel vm;
  final List<String> categoryOrder;
  final Map<String, String> categoryLabels;

  @override
  State<_DhikrList> createState() => _DhikrListState();
}

class _DhikrListState extends State<_DhikrList> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Group filtered list by category, preserving canonical order.
    final groups = <String, List<Dhikr>>{};
    for (final cat in widget.categoryOrder) {
      final items =
          widget.vm.filteredList.where((d) => d.category == cat).toList();
      if (items.isNotEmpty) groups[cat] = items;
    }
    // User-created dhikr may not have a category in canonical order.
    final ungrouped = widget.vm.filteredList
        .where((d) => !widget.categoryOrder.contains(d.category))
        .toList();
    if (ungrouped.isNotEmpty) groups['custom'] = ungrouped;

    if (groups.isEmpty) {
      return const Center(child: Text('No dhikr found.'));
    }

    // Build a flat list of headers + items.
    final items = <Widget>[];
    groups.forEach((cat, dhikrs) {
      items.add(_CategoryHeader(
        label: widget.categoryLabels[cat] ?? 'Custom',
      ));
      items.addAll(
          dhikrs.map((d) => _DhikrListTile(dhikr: d, vm: widget.vm)));
    });

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 40),
        children: items,
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DhikrListTile extends StatelessWidget {
  const _DhikrListTile({required this.dhikr, required this.vm});

  final Dhikr dhikr;
  final DhikrLibraryViewModel vm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: SelectableText(
        dhikr.arabicText,
        textDirection: TextDirection.rtl,
        style: theme.textTheme.titleLarge?.copyWith(
          fontFamily: 'Amiri',
          height: 1.8,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dhikr.transliteration, style: theme.textTheme.bodyMedium),
          Text(
            dhikr.translation,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!dhikr.isPreloaded)
            Tooltip(
              message: 'Delete',
              child: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context),
              ),
            )
          else
            Tooltip(
              message: 'Hide from list',
              child: IconButton(
                icon: const Icon(Icons.visibility_off_outlined),
                onPressed: () =>
                    context.read<DhikrLibraryViewModel>().hideDhikr(dhikr.id!),
              ),
            ),
          Tooltip(
            message: 'View details',
            child: IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => context.go('/library/${dhikr.id}'),
            ),
          ),
        ],
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
            // Windows: confirm on left (RTL reversal).
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
      context.read<DhikrLibraryViewModel>().deleteDhikr(dhikr.id!);
    }
  }
}
