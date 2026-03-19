// lib/views/expanded/expanded_shell.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:dhikratwork/app/theme.dart';
import 'package:dhikratwork/viewmodels/app_shell_viewmodel.dart';
import 'package:dhikratwork/views/expanded/dhikr_tab.dart';
import 'package:dhikratwork/views/expanded/stats_tab.dart';
import 'package:dhikratwork/views/expanded/settings_tab.dart';

/// The expanded full-window shell with a tab bar and custom title bar.
/// Tabs: Dhikr (0), Stats (1), Settings (2).
class ExpandedShell extends StatefulWidget {
  const ExpandedShell({super.key});

  @override
  State<ExpandedShell> createState() => _ExpandedShellState();
}

class _ExpandedShellState extends State<ExpandedShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _switchToSettings() {
    _tabController.animateTo(2);
  }

  Future<void> _minimize() async {
    try {
      await windowManager.minimize();
    } catch (_) {
      // Not available in test environment — ignore.
    }
  }

  Future<void> _close() async {
    try {
      await windowManager.hide();
    } catch (_) {
      // Not available in test environment — ignore.
    }
  }

  void _collapseToCompact() {
    context.read<AppShellViewModel>().setMode(AppMode.compact);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: kDarkNavy,
      body: Column(
        children: [
          // Custom title bar
          _TitleBar(
            tabController: _tabController,
            onMinimize: _minimize,
            onCollapseToCompact: _collapseToCompact,
            onClose: _close,
          ),

          // Tab content
          Expanded(
            child: IndexedStack(
              index: _tabController.index,
              children: [
                DhikrTab(onSwitchToSettings: _switchToSettings),
                const StatsTab(),
                const SettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.tabController,
    required this.onMinimize,
    required this.onCollapseToCompact,
    required this.onClose,
  });

  final TabController tabController;
  final VoidCallback onMinimize;
  final VoidCallback onCollapseToCompact;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: kDeepNavy,
      child: Column(
        children: [
          // Title row with window controls
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
            child: Row(
              children: [
                // App name / drag area
                Expanded(
                  child: GestureDetector(
                    onPanStart: (_) async {
                      try {
                        await windowManager.startDragging();
                      } catch (_) {}
                    },
                    child: Text(
                      'DhikrAtWork',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: kGoldAccent,
                      ),
                    ),
                  ),
                ),

                // Window control buttons
                Tooltip(
                  message: 'Collapse to compact',
                  child: IconButton(
                    icon: const Icon(Icons.compress, size: 16),
                    onPressed: onCollapseToCompact,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Tooltip(
                  message: 'Minimize',
                  child: IconButton(
                    icon: const Icon(Icons.minimize, size: 16),
                    onPressed: onMinimize,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Tooltip(
                  message: 'Close to tray',
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: onClose,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Tab bar
          TabBar(
            controller: tabController,
            tabs: const [
              Tab(text: 'Dhikr'),
              Tab(text: 'Stats'),
              Tab(text: 'Settings'),
            ],
          ),
        ],
      ),
    );
  }
}
