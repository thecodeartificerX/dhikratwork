// lib/views/expanded/dhikr_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/viewmodels/dhikr_library_viewmodel.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/views/shared/add_dhikr_dialog.dart';
import 'package:dhikratwork/views/shared/dhikr_selection_dialog.dart';

/// The Dhikr tab in the expanded shell.
/// Shows active dhikr banner, hotkey display, and the full dhikr library list.
class DhikrTab extends StatefulWidget {
  const DhikrTab({
    super.key,
    this.onSwitchToSettings,
  });

  /// Optional callback to navigate to the Settings tab.
  final VoidCallback? onSwitchToSettings;

  @override
  State<DhikrTab> createState() => _DhikrTabState();
}

class _DhikrTabState extends State<DhikrTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DhikrLibraryViewModel>().loadAll();
    });
  }

  Future<void> _onDhikrTapped(Dhikr dhikr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DhikrSelectionDialog(dhikr: dhikr),
    );
    if (confirmed == true && mounted) {
      if (dhikr.id != null) {
        await context.read<CounterViewModel>().setActiveDhikr(dhikr.id!);
      }
    }
  }

  Future<void> _onAddCustom() async {
    final newDhikr = await showDialog<Dhikr>(
      context: context,
      builder: (_) => const AddDhikrDialog(),
    );
    if (newDhikr != null && mounted) {
      await context.read<DhikrLibraryViewModel>().addDhikr(newDhikr);
    }
  }

  Future<void> _onHide(Dhikr dhikr) async {
    if (dhikr.id != null) {
      await context.read<DhikrLibraryViewModel>().hideDhikr(dhikr.id!);
    }
  }

  Future<void> _onDelete(Dhikr dhikr) async {
    if (dhikr.id != null) {
      await context.read<DhikrLibraryViewModel>().deleteDhikr(dhikr.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final counterVm = context.watch<CounterViewModel>();
    final libraryVm = context.watch<DhikrLibraryViewModel>();
    final settingsVm = context.watch<SettingsViewModel>();

    final activeDhikr = counterVm.activeDhikr;
    final hotkeyString = settingsVm.hotkeyString;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Active dhikr banner
        if (activeDhikr != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.radio_button_checked,
                  color: colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active: ${activeDhikr.name}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        activeDhikr.arabicText,
                        textDirection: TextDirection.rtl,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Hotkey display
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Icon(
                Icons.keyboard,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Hotkey: ',
                style: theme.textTheme.bodySmall,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Text(
                  hotkeyString,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.onSwitchToSettings != null)
                GestureDetector(
                  onTap: widget.onSwitchToSettings,
                  child: Text(
                    'Change in Settings',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // All Dhikr header with Add Custom button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Dhikr',
                style: theme.textTheme.titleSmall,
              ),
              TextButton.icon(
                onPressed: _onAddCustom,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Custom'),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Dhikr list
        Expanded(
          child: libraryVm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : libraryVm.dhikrList.isEmpty
                  ? Center(
                      child: Text(
                        'No dhikr found.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : Scrollbar(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: libraryVm.dhikrList.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final dhikr = libraryVm.dhikrList[index];
                          final isActive =
                              activeDhikr?.id != null &&
                              activeDhikr!.id == dhikr.id;
                          return _DhikrListItem(
                            dhikr: dhikr,
                            isActive: isActive,
                            onTap: () => _onDhikrTapped(dhikr),
                            onHide: () => _onHide(dhikr),
                            onDelete: dhikr.isPreloaded
                                ? null
                                : () => _onDelete(dhikr),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _DhikrListItem extends StatelessWidget {
  const _DhikrListItem({
    required this.dhikr,
    required this.isActive,
    required this.onTap,
    required this.onHide,
    this.onDelete,
  });

  final Dhikr dhikr;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onHide;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: isActive
          ? Icon(Icons.radio_button_checked, color: colorScheme.primary)
          : const Icon(Icons.radio_button_unchecked),
      title: Text(
        dhikr.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isActive ? FontWeight.bold : null,
          color: isActive ? colorScheme.primary : null,
        ),
      ),
      subtitle: Text(
        dhikr.transliteration,
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 18),
        itemBuilder: (_) => [
          const PopupMenuItem<String>(
            value: 'hide',
            child: Row(
              children: [
                Icon(Icons.visibility_off, size: 18),
                SizedBox(width: 8),
                Text('Hide'),
              ],
            ),
          ),
          if (onDelete != null)
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
        ],
        onSelected: (value) {
          if (value == 'hide') onHide();
          if (value == 'delete') onDelete?.call();
        },
      ),
      onTap: onTap,
    );
  }
}
