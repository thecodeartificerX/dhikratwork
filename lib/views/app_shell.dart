// lib/views/app_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'package:dhikratwork/viewmodels/app_shell_viewmodel.dart';
import 'package:dhikratwork/views/compact/compact_counter_bar.dart';
import 'package:dhikratwork/views/expanded/expanded_shell.dart';

/// Root UI widget that switches between [CompactCounterBar] and [ExpandedShell]
/// based on [AppShellViewModel.mode].
///
/// Handles:
/// - AnimatedSwitcher crossfade between modes (250 ms)
/// - Window dimension + decoration transitions via window_manager
/// - Esc key collapse from expanded → compact
/// - Drag-to-reposition in compact mode
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppMode? _previousMode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentMode = context.read<AppShellViewModel>().mode;
    if (_previousMode != null && _previousMode != currentMode) {
      _applyWindowTransition(currentMode);
    }
    _previousMode = currentMode;
  }

  Future<void> _applyWindowTransition(AppMode mode) async {
    try {
      if (mode == AppMode.expanded) {
        await windowManager.setAlwaysOnTop(false);
        await windowManager.setTitleBarStyle(TitleBarStyle.normal);
        await windowManager.setSkipTaskbar(false);
        await windowManager.setSize(const Size(700, 500));
        await windowManager.setAlignment(Alignment.center);
      } else {
        final vm = context.read<AppShellViewModel>();
        await windowManager.setSize(const Size(360, 60));
        final savedX = vm.compactPositionX;
        final savedY = vm.compactPositionY;
        if (savedX != null && savedY != null) {
          await windowManager.setPosition(Offset(savedX, savedY));
        }
        await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
        await windowManager.setSkipTaskbar(true);
        await windowManager.setAlwaysOnTop(true);
      }
    } catch (_) {
      // window_manager calls may not be available in test environments.
    }
  }

  void _onModeChanged(AppMode newMode) {
    _applyWindowTransition(newMode);
    context.read<AppShellViewModel>().setMode(newMode);
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<AppShellViewModel>().mode;

    // Track mode changes for window transitions.
    if (_previousMode != mode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _previousMode != null && _previousMode != mode) {
          _applyWindowTransition(mode);
        }
        _previousMode = mode;
      });
    }

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            mode == AppMode.expanded) {
          _onModeChanged(AppMode.compact);
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: mode == AppMode.compact
            ? _DraggableCompactBar(key: const ValueKey('compact'))
            : const ExpandedShell(key: ValueKey('expanded')),
      ),
    );
  }
}

/// Wraps [CompactCounterBar] with a [GestureDetector] that handles pan-drag
/// to reposition the compact window and persists the final position.
class _DraggableCompactBar extends StatelessWidget {
  const _DraggableCompactBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (_) async {
        try {
          await windowManager.startDragging();
        } catch (_) {
          // Not available in test environments.
        }
      },
      onPanEnd: (_) async {
        try {
          final vm = context.read<AppShellViewModel>();
          final position = await windowManager.getPosition();
          await vm.saveCompactPosition(position.dx, position.dy);
        } catch (_) {
          // Not available in test environments.
        }
      },
      child: const CompactCounterBar(),
    );
  }
}
