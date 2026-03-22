// lib/views/app_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'package:dhikratwork/viewmodels/app_shell_viewmodel.dart';
import 'package:dhikratwork/views/compact/compact_counter_bar.dart';
import 'package:dhikratwork/views/expanded/expanded_shell.dart';

/// Clamps [position] so a window of [windowSize] is fully within the
/// nearest display's visible work area.
Future<Offset> _clampToScreen(Offset position, Size windowSize) async {
  try {
    final displays = await screenRetriever.getAllDisplays();
    if (displays.isEmpty) return position;

    // Find display whose work area contains the window center.
    final center = Offset(
      position.dx + windowSize.width / 2,
      position.dy + windowSize.height / 2,
    );

    Display target = displays.first;
    for (final d in displays) {
      final pos = d.visiblePosition ?? Offset.zero;
      final sz = d.visibleSize ?? d.size;
      final rect = Rect.fromLTWH(pos.dx, pos.dy, sz.width, sz.height);
      if (rect.contains(center)) {
        target = d;
        break;
      }
    }

    final areaPos = target.visiblePosition ?? Offset.zero;
    final areaSz = target.visibleSize ?? target.size;

    return Offset(
      position.dx.clamp(
        areaPos.dx,
        areaPos.dx + areaSz.width - windowSize.width,
      ),
      position.dy.clamp(
        areaPos.dy,
        areaPos.dy + areaSz.height - windowSize.height,
      ),
    );
  } catch (_) {
    // screen_retriever not available (test environments, etc.).
    return position;
  }
}

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
        await windowManager.setSize(const Size(520, 100));
        final savedX = vm.compactPositionX;
        final savedY = vm.compactPositionY;
        if (savedX != null && savedY != null) {
          final clamped = await _clampToScreen(
            Offset(savedX, savedY),
            const Size(520, 100),
          );
          await windowManager.setPosition(clamped);
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
          const compactSize = Size(520, 100);
          final clamped = await _clampToScreen(position, compactSize);
          if (clamped != position) {
            await windowManager.setPosition(clamped);
          }
          await vm.saveCompactPosition(clamped.dx, clamped.dy);
        } catch (_) {
          // Not available in test environments.
        }
      },
      child: const CompactCounterBar(),
    );
  }
}
