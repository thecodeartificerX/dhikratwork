// lib/views/compact/compact_counter_bar.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
      height: 60,
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    activeDhikr.transliteration,
                    style: GoogleFonts.inter(
                      fontSize: 10,
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
          _ExpandButton(onTap: () => appShellVm.setMode(AppMode.expanded)),
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
      height: 60,
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
                  fontSize: 13,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
          _ExpandButton(onTap: onExpand),
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
      padding: const EdgeInsets.symmetric(horizontal: 6),
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
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CountDisplay(
              label: 'Session',
              count: counterVm.sessionCount,
            ),
            const SizedBox(width: 10),
            _CountDisplay(
              label: 'Today',
              count: counterVm.todayCount,
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

  const _CountDisplay({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$count',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kGoldAccent,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
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
      height: 32,
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: kGoldAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kGoldAccent.withValues(alpha: 0.3)),
        ),
        child: Text(
          hotkeyString,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: kGoldAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expand button
// ---------------------------------------------------------------------------

class _ExpandButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ExpandButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: const Icon(Icons.open_in_full),
      iconSize: 16,
      color: Colors.white54,
      tooltip: 'Expand',
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
