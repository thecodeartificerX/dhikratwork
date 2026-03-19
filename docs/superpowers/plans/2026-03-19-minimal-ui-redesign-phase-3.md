# Phase 3: Compact Counter Bar

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the compact always-on-top horizontal counter bar widget.

**Architecture:** A stateless widget that reads from `CounterViewModel` and `SettingsViewModel` via Provider. Window operations (drag, always-on-top) are handled by the parent `AppShell` — this widget only renders UI and emits callbacks.

**Depends on:** Phase 1 (CounterViewModel with sessionCount, AppShellViewModel)

**Spec:** `docs/superpowers/specs/2026-03-19-minimal-ui-redesign-design.md` — "Compact Mode" section

---

## Task 3.1: Build CompactCounterBar Widget

**Files:**
- Create: `lib/views/compact/compact_counter_bar.dart`
- Create: `test/widget/views/compact/compact_counter_bar_test.dart`

- [ ] **Step 1: Write failing widget tests**

```dart
// test/widget/views/compact/compact_counter_bar_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/viewmodels/app_shell_viewmodel.dart';
import 'package:dhikratwork/views/compact/compact_counter_bar.dart';
import '../../../../fakes/fake_dhikr_repository.dart';
import '../../../../fakes/fake_session_repository.dart';
import '../../../../fakes/fake_stats_repository.dart';
import '../../../../fakes/fake_streak_repository.dart';
import '../../../../fakes/fake_achievement_repository.dart';
import '../../../../fakes/fake_settings_repository.dart';
import '../../../../fakes/fake_subscription_service.dart';

Widget _buildTestApp({
  required CounterViewModel counterVm,
  required SettingsViewModel settingsVm,
  required AppShellViewModel appShellVm,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<CounterViewModel>.value(value: counterVm),
      ChangeNotifierProvider<SettingsViewModel>.value(value: settingsVm),
      ChangeNotifierProvider<AppShellViewModel>.value(value: appShellVm),
    ],
    child: const MaterialApp(home: Scaffold(body: CompactCounterBar())),
  );
}

void main() {
  late CounterViewModel counterVm;
  late SettingsViewModel settingsVm;
  late AppShellViewModel appShellVm;

  setUp(() {
    final settingsRepo = FakeSettingsRepository();
    counterVm = CounterViewModel(
      dhikrRepository: FakeDhikrRepository(),
      sessionRepository: FakeSessionRepository(),
      statsRepository: FakeStatsRepository(),
      streakRepository: FakeStreakRepository(),
      achievementRepository: FakeAchievementRepository(),
      settingsRepository: settingsRepo,
    );
    settingsVm = SettingsViewModel(
      settingsRepository: settingsRepo,
      dhikrRepository: FakeDhikrRepository(),
      subscriptionService: FakeSubscriptionService(),
    );
    appShellVm = AppShellViewModel(settingsRepository: settingsRepo);
  });

  testWidgets('shows "No dhikr selected" when no active dhikr', (tester) async {
    await tester.pumpWidget(_buildTestApp(
      counterVm: counterVm,
      settingsVm: settingsVm,
      appShellVm: appShellVm,
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('No dhikr selected'), findsOneWidget);
  });

  testWidgets('shows Arabic text when active dhikr is set', (tester) async {
    await counterVm.setActiveDhikr(1);
    await counterVm.startSession(1);

    await tester.pumpWidget(_buildTestApp(
      counterVm: counterVm,
      settingsVm: settingsVm,
      appShellVm: appShellVm,
    ));
    await tester.pumpAndSettle();
    expect(find.text('سُبْحَانَ اللَّهِ'), findsOneWidget);
  });

  testWidgets('shows session count and today count', (tester) async {
    await counterVm.setActiveDhikr(1);
    await counterVm.startSession(1);

    await tester.pumpWidget(_buildTestApp(
      counterVm: counterVm,
      settingsVm: settingsVm,
      appShellVm: appShellVm,
    ));
    await tester.pumpAndSettle();
    expect(find.text('session'), findsOneWidget);
    expect(find.text('today'), findsOneWidget);
  });

  testWidgets('shows hotkey badge text', (tester) async {
    await counterVm.setActiveDhikr(1);
    await counterVm.startSession(1);

    await tester.pumpWidget(_buildTestApp(
      counterVm: counterVm,
      settingsVm: settingsVm,
      appShellVm: appShellVm,
    ));
    await tester.pumpAndSettle();
    // Default hotkey from FakeSettingsRepository is 'ctrl+shift+d'
    expect(find.text('ctrl+shift+d'), findsOneWidget);
  });

  testWidgets('expand button exists', (tester) async {
    await tester.pumpWidget(_buildTestApp(
      counterVm: counterVm,
      settingsVm: settingsVm,
      appShellVm: appShellVm,
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.open_in_full), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/widget/views/compact/compact_counter_bar_test.dart`
Expected: FAIL — `compact_counter_bar.dart` does not exist

- [ ] **Step 3: Create CompactCounterBar widget**

```dart
// lib/views/compact/compact_counter_bar.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dhikratwork/app/theme.dart';
import 'package:dhikratwork/viewmodels/app_shell_viewmodel.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';

/// Compact always-on-top horizontal counter bar (~360 x 60px).
///
/// Layout (left to right): drag handle | Arabic + transliteration | divider |
/// session count | today count | divider | hotkey badge | expand button.
///
/// When no dhikr is active, shows dimmed "No dhikr selected" message.
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
          // Drag handle.
          const _DragHandle(),

          // Arabic text + transliteration.
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

          // Session count + Today count (with right-click context menu).
          _CountArea(counterVm: counterVm),

          const _VerticalDivider(),

          // Hotkey badge.
          _HotkeyBadge(hotkeyString: settingsVm.hotkeyString),

          // Expand button.
          _ExpandButton(
            onTap: () => appShellVm.setMode(AppMode.expanded),
          ),
        ],
      ),
    );
  }
}

class _NoActiveDhikrBar extends StatelessWidget {
  final VoidCallback onExpand;
  const _NoActiveDhikrBar({required this.onExpand});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: kDeepNavy.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'No dhikr selected \u2014 Click expand to choose one',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          _ExpandButton(onTap: onExpand, highlighted: true),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Icon(Icons.drag_indicator, color: Colors.white38, size: 20),
    );
  }
}

/// Wraps session and today counts with right-click context menu:
/// Reset Session Count, Reset Today's Count, End Session.
class _CountArea extends StatelessWidget {
  final CounterViewModel counterVm;
  const _CountArea({required this.counterVm});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CountDisplay(
            count: counterVm.sessionCount,
            label: 'session',
            isLarge: true,
          ),
          _CountDisplay(
            count: counterVm.todayCount,
            label: 'today',
            isLarge: false,
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        const PopupMenuItem(
          value: 'reset_session',
          child: Text('Reset Session Count'),
        ),
        const PopupMenuItem(
          value: 'reset_today',
          child: Text("Reset Today's Count"),
        ),
        const PopupMenuItem(
          value: 'end_session',
          child: Text('End Session'),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'reset_session':
          counterVm.resetSessionCount();
        case 'reset_today':
          counterVm.resetTodayCount();
        case 'end_session':
          counterVm.endSession();
      }
    });
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white24,
    );
  }
}

class _CountDisplay extends StatelessWidget {
  final int count;
  final String label;
  final bool isLarge;

  const _CountDisplay({
    required this.count,
    required this.label,
    required this.isLarge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: isLarge ? 20 : 14,
              fontWeight: isLarge ? FontWeight.bold : FontWeight.w500,
              color: isLarge ? kGoldAccent : Colors.white70,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 9, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _HotkeyBadge extends StatelessWidget {
  final String hotkeyString;
  const _HotkeyBadge({required this.hotkeyString});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        hotkeyString,
        style: GoogleFonts.firaCode(fontSize: 10, color: Colors.white70),
      ),
    );
  }
}

class _ExpandButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool highlighted;
  const _ExpandButton({required this.onTap, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        Icons.open_in_full,
        color: highlighted ? kGoldAccent : Colors.white70,
        size: 18,
      ),
      tooltip: 'Expand',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/widget/views/compact/compact_counter_bar_test.dart`
Expected: All 5 tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/views/compact/compact_counter_bar.dart test/widget/views/compact/compact_counter_bar_test.dart
git commit -m "feat: add CompactCounterBar widget with no-active-dhikr state"
```
