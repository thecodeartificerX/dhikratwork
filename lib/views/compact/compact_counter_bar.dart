// lib/views/compact/compact_counter_bar.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:dhikratwork/app/theme.dart';
import 'package:dhikratwork/viewmodels/app_shell_viewmodel.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';

class CompactCounterBar extends StatelessWidget {
  const CompactCounterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final counterVm = context.watch<CounterViewModel>();
    final settingsVm = context.watch<SettingsViewModel>();
    final appShellVm = context.read<AppShellViewModel>();
    final activeDhikr = counterVm.activeDhikr;

    if (activeDhikr == null) {
      return _NoActiveDhikrBar(
        onExpand: () => appShellVm.setMode(AppMode.expanded),
      );
    }

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: kDeepNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGoldAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DragHandle(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      activeDhikr.arabicText,
                      style: GoogleFonts.amiri(
                        fontSize: 16,
                        color: kGoldAccent,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activeDhikr.transliteration,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const _VerticalDivider(),
          _CountArea(counterVm: counterVm),
          const _VerticalDivider(),
          _HotkeyBadge(hotkeyString: settingsVm.hotkeyString),
          _WindowControls(
            onMinimize: () async {
              try { await windowManager.hide(); } catch (_) {}
            },
            onExpand: () => appShellVm.setMode(AppMode.expanded),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// No active dhikr state
// ---------------------------------------------------------------------------

class _NoActiveDhikrBar extends StatelessWidget {
  final VoidCallback onExpand;

  const _NoActiveDhikrBar({required this.onExpand});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: kDeepNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGoldAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DragHandle(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'No dhikr selected',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
          _WindowControls(
            onMinimize: () async {
              try { await windowManager.hide(); } catch (_) {}
            },
            onExpand: onExpand,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drag handle
// ---------------------------------------------------------------------------

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Icon(
        Icons.drag_indicator,
        color: Colors.white38,
        size: 18,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Count area with right-click context menu
// ---------------------------------------------------------------------------

class _CountArea extends StatelessWidget {
  final CounterViewModel counterVm;

  const _CountArea({required this.counterVm});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) => _showContextMenu(context, details),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CountDisplay(
              label: 'Session',
              count: counterVm.sessionCount,
              onReset: counterVm.resetSessionCount,
            ),
            const SizedBox(width: 24),
            _CountDisplay(
              label: 'Today',
              count: counterVm.todayCount,
              onReset: counterVm.resetTodayCount,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showContextMenu(
    BuildContext context,
    TapDownDetails details,
  ) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem(value: 'reset_session', child: Text('Reset session')),
        PopupMenuItem(value: 'reset_today', child: Text('Reset today')),
        PopupMenuItem(value: 'end_session', child: Text('End session')),
      ],
    );

    if (result == null) return;
    switch (result) {
      case 'reset_session':
        await counterVm.resetSessionCount();
      case 'reset_today':
        await counterVm.resetTodayCount();
      case 'end_session':
        await counterVm.endSession();
    }
  }
}

// ---------------------------------------------------------------------------
// Single count display (label + number)
// ---------------------------------------------------------------------------

class _CountDisplay extends StatelessWidget {
  final String label;
  final int count;
  final Future<void> Function()? onReset;

  const _CountDisplay({
    required this.label,
    required this.count,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kGoldAccent,
              ),
            ),
            if (onReset != null)
              Tooltip(
                message: 'Reset $label',
                preferBelow: false,
                verticalOffset: 14,
                textStyle: GoogleFonts.inter(fontSize: 10, color: Colors.white),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(4),
                ),
                waitDuration: const Duration(milliseconds: 400),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onReset,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: Icon(
                        Icons.restart_alt_rounded,
                        size: 15,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Vertical divider
// ---------------------------------------------------------------------------

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: kGoldAccent.withValues(alpha: 0.2),
    );
  }
}

// ---------------------------------------------------------------------------
// Hotkey badge
// ---------------------------------------------------------------------------

class _HotkeyBadge extends StatelessWidget {
  final String hotkeyString;

  const _HotkeyBadge({required this.hotkeyString});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: kGoldAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kGoldAccent.withValues(alpha: 0.3)),
        ),
        child: Text(
          hotkeyString,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: kGoldAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Window controls (minimize + expand)
// ---------------------------------------------------------------------------

class _WindowControls extends StatelessWidget {
  final VoidCallback onMinimize;
  final VoidCallback onExpand;

  const _WindowControls({required this.onMinimize, required this.onExpand});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onMinimize,
            icon: const Icon(Icons.minimize),
            iconSize: 14,
            color: Colors.white54,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            tooltip: 'Minimize to tray',
          ),
          const SizedBox(height: 4),
          IconButton(
            onPressed: onExpand,
            icon: const Icon(Icons.open_in_full),
            iconSize: 14,
            color: Colors.white54,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            tooltip: 'Expand',
          ),
        ],
      ),
    );
  }
}
