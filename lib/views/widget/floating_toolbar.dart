// lib/views/widget/floating_toolbar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/services/floating_window_manager.dart';
import 'package:dhikratwork/viewmodels/widget_toolbar_viewmodel.dart';

/// Root widget for the floating toolbar OS window.
///
/// This is the widget tree mounted by the sub-window entry point in main.dart.
/// The sub-window has its own Dart isolate and its own ViewModel instances.
/// State is synced with the main window via WindowMethodChannel IPC.
class FloatingToolbarApp extends StatefulWidget {
  final String windowId;

  const FloatingToolbarApp({super.key, required this.windowId});

  @override
  State<FloatingToolbarApp> createState() => _FloatingToolbarAppState();
}

class _FloatingToolbarAppState extends State<FloatingToolbarApp>
    with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _configureThisWindow();
  }

  /// Configures the floating toolbar window properties from within its own
  /// Dart context. window_manager APIs apply to the current window.
  Future<void> _configureThisWindow() async {
    await windowManager.ensureInitialized();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setSkipTaskbar(true);
    await windowManager.setResizable(false);
    await windowManager.setBackgroundColor(Colors.transparent);
    await windowManager.show();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B6914), // Gold seed matching main app
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const FloatingToolbar(),
    );
  }
}

/// The actual toolbar widget. Handles drag, expand/collapse, dhikr buttons.
class FloatingToolbar extends StatefulWidget {
  const FloatingToolbar({super.key});

  @override
  State<FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends State<FloatingToolbar> {
  // Track drag offset relative to the window's top-left.
  Offset _dragStartCursorPosition = Offset.zero;
  Offset _dragStartWindowPosition = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // Load toolbar data when the floating window first renders.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WidgetToolbarViewModel>().loadToolbar();
      }
    });
  }

  Future<void> _onDragStart(DragStartDetails details) async {
    _isDragging = true;
    _dragStartCursorPosition = details.globalPosition;
    final pos = await windowManager.getPosition();
    _dragStartWindowPosition = Offset(pos.dx, pos.dy);
  }

  Future<void> _onDragUpdate(DragUpdateDetails details) async {
    if (!_isDragging) return;
    final delta = details.globalPosition - _dragStartCursorPosition;
    final newX = _dragStartWindowPosition.dx + delta.dx;
    final newY = _dragStartWindowPosition.dy + delta.dy;
    await windowManager.setPosition(Offset(newX, newY));
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    _isDragging = false;
    final pos = await windowManager.getPosition();
    // Persist final position to user_settings.
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    await context.read<WidgetToolbarViewModel>().updatePosition(pos.dx, pos.dy);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WidgetToolbarViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const _ToolbarShell(
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return _ToolbarShell(
          onDragStart: _onDragStart,
          onDragUpdate: _onDragUpdate,
          onDragEnd: _onDragEnd,
          child: vm.isExpanded
              ? _ExpandedToolbar(vm: vm)
              : _CollapsedToolbar(vm: vm),
        );
      },
    );
  }
}

/// The outer shell: rounded card with drag gesture detection and drag handle.
class _ToolbarShell extends StatelessWidget {
  final Widget child;
  final GestureDragStartCallback? onDragStart;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;

  const _ToolbarShell({
    required this.child,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onPanStart: onDragStart,
      onPanUpdate: onDragUpdate,
      onPanEnd: onDragEnd,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Collapsed state: a single 48x48 icon button to re-expand.
class _CollapsedToolbar extends StatelessWidget {
  final WidgetToolbarViewModel vm;

  const _CollapsedToolbar({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Tooltip(
        message: 'Expand DhikrAtWork toolbar',
        child: IconButton(
          onPressed: () async {
            vm.toggleExpand();
            await FloatingWindowManager.setExpandedSize(
              vm.toolbarDhikrs.length,
            );
          },
          icon: const Text(
            '☽',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}

/// Expanded state: header row + dhikr buttons.
class _ExpandedToolbar extends StatelessWidget {
  final WidgetToolbarViewModel vm;

  const _ExpandedToolbar({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToolbarHeader(vm: vm),
        const Divider(height: 1, thickness: 1),
        ...vm.toolbarDhikrs.map(
          (dhikr) => _DhikrButton(
            dhikr: dhikr,
            count: vm.todayCounts[dhikr.id] ?? 0,
            isActive: vm.activeDhikrId == dhikr.id,
            onTap: () =>
                context.read<WidgetToolbarViewModel>().incrementDhikr(dhikr.id!),
            onLongPress: () =>
                context.read<WidgetToolbarViewModel>().setActiveDhikr(dhikr.id!),
          ),
        ),
      ],
    );
  }
}

/// Header row: drag handle indicator + collapse button + hide (x) button.
class _ToolbarHeader extends StatelessWidget {
  final WidgetToolbarViewModel vm;

  const _ToolbarHeader({required this.vm});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 36,
      child: Row(
        children: [
          const SizedBox(width: 8),
          // Drag handle visual indicator
          Icon(
            Icons.drag_indicator,
            size: 16,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const Spacer(),
          // Collapse button
          Tooltip(
            message: 'Collapse',
            child: IconButton(
              onPressed: () async {
                vm.toggleExpand();
                await FloatingWindowManager.setCollapsedSize();
              },
              icon: Icon(
                Icons.remove,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ),
          // Hide (x) button — hides the window, does not quit the app
          Tooltip(
            message: 'Hide (app stays in tray)',
            child: IconButton(
              onPressed: () =>
                  FloatingWindowManager.instance.hideFloatingWidget(),
              icon: Icon(
                Icons.close,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// A single dhikr button in the toolbar.
/// Tap = increment. Long-press = set as active (receives hotkey presses).
class _DhikrButton extends StatelessWidget {
  final Dhikr dhikr;
  final int count;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _DhikrButton({
    required this.dhikr,
    required this.count,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: isActive
          ? '${dhikr.name} (active — hotkey increments this)'
          : '${dhikr.name} — long-press to set as active',
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.zero,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : Colors.transparent,
            border: isActive
                ? Border(
                    left: BorderSide(
                      color: colorScheme.primary,
                      width: 3,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              // Active indicator dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isActive ? colorScheme.primary : Colors.transparent,
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dhikr.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isActive
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      dhikr.arabicText,
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontFamily: 'Amiri',
                                color: colorScheme.onSurfaceVariant,
                              ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              // Today's count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
