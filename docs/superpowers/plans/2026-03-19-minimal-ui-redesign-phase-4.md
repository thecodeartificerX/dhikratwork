# Phase 4: Expanded Mode — Shell + 3 Tabs

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the expanded mode UI: a tabbed shell with Dhikr, Stats, and Settings tabs.

**Architecture:** `ExpandedShell` owns a `TabController` with `IndexedStack`. Each tab is a separate widget. Shared dialogs (add dhikr, dhikr selection confirmation) live in `lib/views/shared/`. Tasks 4.2-4.4 can run in parallel since they don't share files.

**Depends on:** Phase 1 (ViewModels), Phase 2 (theme)

**Spec:** `docs/superpowers/specs/2026-03-19-minimal-ui-redesign-design.md` — "Expanded Mode" section

---

## Task 4.1: Build ExpandedShell

The container with TabBar + IndexedStack + custom title bar buttons.

**Files:**
- Create: `lib/views/expanded/expanded_shell.dart`
- Create: `test/widget/views/expanded/expanded_shell_test.dart`

- [ ] **Step 1: Write failing widget tests**

```dart
// test/widget/views/expanded/expanded_shell_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dhikratwork/viewmodels/app_shell_viewmodel.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/viewmodels/dhikr_library_viewmodel.dart';
import 'package:dhikratwork/viewmodels/stats_viewmodel.dart';
import 'package:dhikratwork/viewmodels/gamification_viewmodel.dart';
import 'package:dhikratwork/viewmodels/goal_viewmodel.dart';
import 'package:dhikratwork/views/expanded/expanded_shell.dart';
import '../../../../fakes/fake_dhikr_repository.dart';
import '../../../../fakes/fake_session_repository.dart';
import '../../../../fakes/fake_stats_repository.dart';
import '../../../../fakes/fake_streak_repository.dart';
import '../../../../fakes/fake_achievement_repository.dart';
import '../../../../fakes/fake_settings_repository.dart';
import '../../../../fakes/fake_subscription_service.dart';
import '../../../../fakes/fake_goal_repository.dart';

Widget _buildTestApp() {
  final settingsRepo = FakeSettingsRepository();
  final dhikrRepo = FakeDhikrRepository();
  final statsRepo = FakeStatsRepository();
  final streakRepo = FakeStreakRepository();
  final achievementRepo = FakeAchievementRepository();
  final goalRepo = FakeGoalRepository();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => AppShellViewModel(settingsRepository: settingsRepo),
      ),
      ChangeNotifierProvider(
        create: (_) => CounterViewModel(
          dhikrRepository: dhikrRepo,
          sessionRepository: FakeSessionRepository(),
          statsRepository: statsRepo,
          streakRepository: streakRepo,
          achievementRepository: achievementRepo,
          settingsRepository: settingsRepo,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => SettingsViewModel(
          settingsRepository: settingsRepo,
          dhikrRepository: dhikrRepo,
          subscriptionService: FakeSubscriptionService(),
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => DhikrLibraryViewModel(dhikrRepository: dhikrRepo),
      ),
      ChangeNotifierProvider(
        create: (_) => StatsViewModel(
          statsRepository: statsRepo,
          streakRepository: streakRepo,
          dhikrRepository: dhikrRepo,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => GamificationViewModel(
          achievementRepository: achievementRepo,
          streakRepository: streakRepo,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => GoalViewModel(
          goalRepository: goalRepo,
          statsRepository: statsRepo,
        ),
      ),
    ],
    child: const MaterialApp(home: ExpandedShell()),
  );
}

void main() {
  testWidgets('renders three tabs: Dhikr, Stats, Settings', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    expect(find.text('Dhikr'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('tapping Stats tab switches content', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    // Stats tab content should be visible — check for period selector.
    expect(find.text('Day'), findsOneWidget);
  });

  testWidgets('title bar buttons exist', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    // Collapse (compact) button, minimize, close.
    expect(find.byIcon(Icons.minimize), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/widget/views/expanded/expanded_shell_test.dart`
Expected: FAIL — `expanded_shell.dart` does not exist

- [ ] **Step 3: Implement ExpandedShell**

```dart
// lib/views/expanded/expanded_shell.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dhikratwork/app/theme.dart';
import 'package:dhikratwork/viewmodels/app_shell_viewmodel.dart';
import 'package:dhikratwork/views/expanded/dhikr_tab.dart';
import 'package:dhikratwork/views/expanded/stats_tab.dart';
import 'package:dhikratwork/views/expanded/settings_tab.dart';

/// Expanded mode container: custom title bar + TabBar + IndexedStack body.
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
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom title bar row.
          _TitleBarRow(
            onMinimize: () {
              // Handled by window_manager in AppShell.
            },
            onCollapse: () {
              context.read<AppShellViewModel>().setMode(AppMode.compact);
            },
            onClose: () {
              // Close to tray — handled by window_manager in AppShell.
            },
          ),

          // Tab bar.
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Dhikr'),
              Tab(text: 'Stats'),
              Tab(text: 'Settings'),
            ],
          ),

          // Tab content.
          Expanded(
            child: IndexedStack(
              index: _tabController.index,
              children: [
                DhikrTab(
                  onSwitchToSettings: () => _tabController.animateTo(2),
                ),
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

class _TitleBarRow extends StatelessWidget {
  final VoidCallback onMinimize;
  final VoidCallback onCollapse;
  final VoidCallback onClose;

  const _TitleBarRow({
    required this.onMinimize,
    required this.onCollapse,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Text(
            'DhikrAtWork',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: kGoldAccent),
          ),
          const Spacer(),
          // Minimize (gray).
          _TitleButton(
            icon: Icons.minimize,
            color: Colors.white54,
            onTap: onMinimize,
            tooltip: 'Minimize',
          ),
          // Collapse to compact (gold).
          _TitleButton(
            icon: Icons.unfold_less,
            color: kGoldAccent,
            onTap: onCollapse,
            tooltip: 'Compact mode',
          ),
          // Close to tray (red).
          _TitleButton(
            icon: Icons.close,
            color: Colors.redAccent,
            onTap: onClose,
            tooltip: 'Close to tray',
          ),
        ],
      ),
    );
  }
}

class _TitleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _TitleButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }
}
```

Note: `DhikrTab`, `StatsTab`, and `SettingsTab` are created in Tasks 4.2-4.4. To avoid compile errors, create minimal stub files first if running this task before the others:

```dart
// Stub: lib/views/expanded/dhikr_tab.dart
import 'package:flutter/material.dart';
class DhikrTab extends StatelessWidget {
  const DhikrTab({super.key});
  @override Widget build(BuildContext context) => const Placeholder();
}

// Stub: lib/views/expanded/stats_tab.dart
import 'package:flutter/material.dart';
class StatsTab extends StatelessWidget {
  const StatsTab({super.key});
  @override Widget build(BuildContext context) => const Placeholder();
}

// Stub: lib/views/expanded/settings_tab.dart
import 'package:flutter/material.dart';
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});
  @override Widget build(BuildContext context) => const Placeholder();
}
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/widget/views/expanded/expanded_shell_test.dart`
Expected: All 3 tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/views/expanded/expanded_shell.dart test/widget/views/expanded/expanded_shell_test.dart
git commit -m "feat: add ExpandedShell with TabBar, IndexedStack, and title bar buttons"
```

---

## Task 4.2: Build DhikrTab + Shared Dialogs

**Files:**
- Create: `lib/views/expanded/dhikr_tab.dart`
- Create: `lib/views/shared/add_dhikr_dialog.dart`
- Create: `lib/views/shared/dhikr_selection_dialog.dart`
- Create: `test/widget/views/expanded/dhikr_tab_test.dart`

- [ ] **Step 1: Write failing widget tests**

```dart
// test/widget/views/expanded/dhikr_tab_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/viewmodels/dhikr_library_viewmodel.dart';
import 'package:dhikratwork/views/expanded/dhikr_tab.dart';
import '../../../../fakes/fake_dhikr_repository.dart';
import '../../../../fakes/fake_session_repository.dart';
import '../../../../fakes/fake_stats_repository.dart';
import '../../../../fakes/fake_streak_repository.dart';
import '../../../../fakes/fake_achievement_repository.dart';
import '../../../../fakes/fake_settings_repository.dart';
import '../../../../fakes/fake_subscription_service.dart';

Widget _buildTestApp({CounterViewModel? counterVm}) {
  final settingsRepo = FakeSettingsRepository();
  final dhikrRepo = FakeDhikrRepository();
  final cVm = counterVm ??
      CounterViewModel(
        dhikrRepository: dhikrRepo,
        sessionRepository: FakeSessionRepository(),
        statsRepository: FakeStatsRepository(),
        streakRepository: FakeStreakRepository(),
        achievementRepository: FakeAchievementRepository(),
        settingsRepository: settingsRepo,
      );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<CounterViewModel>.value(value: cVm),
      ChangeNotifierProvider(
        create: (_) => SettingsViewModel(
          settingsRepository: settingsRepo,
          dhikrRepository: dhikrRepo,
          subscriptionService: FakeSubscriptionService(),
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => DhikrLibraryViewModel(dhikrRepository: dhikrRepo),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: DhikrTab())),
  );
}

void main() {
  testWidgets('renders dhikr list items after load', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    // FakeDhikrRepository seeds SubhanAllah and Alhamdulillah.
    expect(find.text('Subhanallah'), findsOneWidget);
    expect(find.text('Alhamdulillah'), findsOneWidget);
  });

  testWidgets('shows active dhikr banner when active dhikr is set',
      (tester) async {
    final settingsRepo = FakeSettingsRepository();
    final dhikrRepo = FakeDhikrRepository();
    final counterVm = CounterViewModel(
      dhikrRepository: dhikrRepo,
      sessionRepository: FakeSessionRepository(),
      statsRepository: FakeStatsRepository(),
      streakRepository: FakeStreakRepository(),
      achievementRepository: FakeAchievementRepository(),
      settingsRepository: settingsRepo,
    );
    await counterVm.setActiveDhikr(1);
    await counterVm.startSession(1);

    await tester.pumpWidget(_buildTestApp(counterVm: counterVm));
    await tester.pumpAndSettle();
    expect(find.text('CURRENTLY ACTIVE'), findsOneWidget);
  });

  testWidgets('Add Custom button exists', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('Add Custom'), findsOneWidget);
  });

  testWidgets('shows hotkey display with Change in Settings link',
      (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    expect(find.text('ctrl+shift+d'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/widget/views/expanded/dhikr_tab_test.dart`
Expected: FAIL — `dhikr_tab.dart` does not exist (or has stub `Placeholder`)

- [ ] **Step 3: Create DhikrSelectionDialog**

```dart
// lib/views/shared/dhikr_selection_dialog.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dhikratwork/app/theme.dart';
import 'package:dhikratwork/models/dhikr.dart';

/// Confirmation dialog shown when user selects a dhikr to make active.
/// Displays Arabic text, transliteration, translation. Cancel / Confirm buttons.
class DhikrSelectionDialog extends StatelessWidget {
  final Dhikr dhikr;

  const DhikrSelectionDialog({super.key, required this.dhikr});

  static Future<bool?> show(BuildContext context, Dhikr dhikr) {
    return showDialog<bool>(
      context: context,
      builder: (_) => DhikrSelectionDialog(dhikr: dhikr),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Active Dhikr'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              dhikr.arabicText,
              style: GoogleFonts.amiri(
                fontSize: 26,
                color: kGoldAccent,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dhikr.transliteration,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 4),
          Text(
            dhikr.translation,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Create AddDhikrDialog**

```dart
// lib/views/shared/add_dhikr_dialog.dart

import 'package:flutter/material.dart';
import 'package:dhikratwork/models/dhikr.dart';

/// Dialog form for adding a custom dhikr.
///
/// Fields: Name, Arabic Text, Transliteration, Translation, Target Count (optional).
/// Category is always 'custom' and not exposed in the form.
class AddDhikrDialog extends StatefulWidget {
  const AddDhikrDialog({super.key});

  static Future<Dhikr?> show(BuildContext context) {
    return showDialog<Dhikr>(
      context: context,
      builder: (_) => const AddDhikrDialog(),
    );
  }

  @override
  State<AddDhikrDialog> createState() => _AddDhikrDialogState();
}

class _AddDhikrDialogState extends State<AddDhikrDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _arabicCtrl = TextEditingController();
  final _translitCtrl = TextEditingController();
  final _translationCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _arabicCtrl.dispose();
    _translitCtrl.dispose();
    _translationCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Dhikr'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _arabicCtrl,
                  decoration: const InputDecoration(labelText: 'Arabic Text'),
                  textDirection: TextDirection.rtl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _translitCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Transliteration'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _translationCtrl,
                  decoration: const InputDecoration(labelText: 'Translation'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _targetCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Target Count (optional)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v);
                    if (n == null || n < 1) return 'Must be a positive number';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final dhikr = Dhikr(
      name: _nameCtrl.text.trim(),
      arabicText: _arabicCtrl.text.trim(),
      transliteration: _translitCtrl.text.trim(),
      translation: _translationCtrl.text.trim(),
      category: 'custom',
      targetCount: _targetCtrl.text.trim().isEmpty
          ? null
          : int.parse(_targetCtrl.text.trim()),
      createdAt: DateTime.now().toIso8601String(),
    );

    Navigator.of(context).pop(dhikr);
  }
}
```

- [ ] **Step 5: Create DhikrTab**

```dart
// lib/views/expanded/dhikr_tab.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dhikratwork/app/theme.dart';
import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/dhikr_library_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/views/shared/add_dhikr_dialog.dart';
import 'package:dhikratwork/views/shared/dhikr_selection_dialog.dart';

/// Dhikr tab in expanded mode: active banner, hotkey display, flat list, add custom.
///
/// [onSwitchToSettings] is called when user taps "Change in Settings" link.
/// Pass the `TabController.animateTo(2)` callback from [ExpandedShell].
class DhikrTab extends StatefulWidget {
  final VoidCallback? onSwitchToSettings;
  const DhikrTab({super.key, this.onSwitchToSettings});

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

  @override
  Widget build(BuildContext context) {
    final counterVm = context.watch<CounterViewModel>();
    final settingsVm = context.watch<SettingsViewModel>();
    final libraryVm = context.watch<DhikrLibraryViewModel>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Active Dhikr Banner.
          if (counterVm.activeDhikr != null)
            _ActiveBanner(dhikr: counterVm.activeDhikr!, sessionCount: counterVm.sessionCount),

          const SizedBox(height: 12),

          // Hotkey display with link to Settings tab.
          _HotkeyDisplay(
            hotkeyString: settingsVm.hotkeyString,
            onSettingsTap: widget.onSwitchToSettings,
          ),

          const SizedBox(height: 12),

          // Header row with Add Custom button.
          Row(
            children: [
              Text('All Dhikr',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _onAddCustom(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Custom'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Flat dhikr list.
          Expanded(
            child: libraryVm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: libraryVm.dhikrList.length,
                    itemBuilder: (context, index) {
                      final dhikr = libraryVm.dhikrList[index];
                      final isActive =
                          counterVm.activeDhikr?.id == dhikr.id;
                      return _DhikrListRow(
                        dhikr: dhikr,
                        isActive: isActive,
                        todayCount: isActive ? counterVm.todayCount : null,
                        onTap: () => _onSelectDhikr(context, dhikr),
                        onHide: () => libraryVm.hideDhikr(dhikr.id!),
                        onDelete: dhikr.isPreloaded
                            ? null
                            : () => libraryVm.deleteDhikr(dhikr.id!),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSelectDhikr(BuildContext context, Dhikr dhikr) async {
    final confirmed = await DhikrSelectionDialog.show(context, dhikr);
    if (confirmed != true || !context.mounted) return;

    final counterVm = context.read<CounterViewModel>();
    await counterVm.endSession();
    await counterVm.setActiveDhikr(dhikr.id!);
    await counterVm.startSession(dhikr.id!);
  }

  Future<void> _onAddCustom(BuildContext context) async {
    final dhikr = await AddDhikrDialog.show(context);
    if (dhikr == null || !context.mounted) return;
    await context.read<DhikrLibraryViewModel>().addDhikr(dhikr);
  }
}

class _ActiveBanner extends StatelessWidget {
  final Dhikr dhikr;
  final int sessionCount;

  const _ActiveBanner({required this.dhikr, required this.sessionCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kGoldAccent.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENTLY ACTIVE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kGoldAccent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      dhikr.arabicText,
                      style: GoogleFonts.amiri(
                        fontSize: 20,
                        color: kGoldAccent,
                      ),
                    ),
                  ),
                  Text(
                    '${dhikr.transliteration} — ${dhikr.translation}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '$sessionCount',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kGoldAccent,
                  ),
                ),
                Text('session',
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HotkeyDisplay extends StatelessWidget {
  final String hotkeyString;
  final VoidCallback? onSettingsTap;
  const _HotkeyDisplay({required this.hotkeyString, this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            hotkeyString,
            style: GoogleFonts.firaCode(fontSize: 12, color: Colors.white70),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSettingsTap,
          child: Text(
            'Change in Settings',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: kGoldAccent,
                  decoration: TextDecoration.underline,
                ),
          ),
        ),
      ],
    );
  }
}

class _DhikrListRow extends StatelessWidget {
  final Dhikr dhikr;
  final bool isActive;
  final int? todayCount;
  final VoidCallback onTap;
  final VoidCallback onHide;
  final VoidCallback? onDelete;

  const _DhikrListRow({
    required this.dhikr,
    required this.isActive,
    this.todayCount,
    required this.onTap,
    required this.onHide,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        isActive ? Icons.circle : Icons.circle_outlined,
        size: 12,
        color: isActive ? kGoldAccent : Colors.white38,
      ),
      title: Row(
        children: [
          Text(dhikr.transliteration),
          const SizedBox(width: 8),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              dhikr.arabicText,
              style: GoogleFonts.amiri(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (todayCount != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: kGoldAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$todayCount',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kGoldAccent),
              ),
            ),
          if (isActive)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'Active',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kGoldAccent),
              ),
            ),
          PopupMenuButton<String>(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'hide', child: Text('Hide')),
              if (onDelete != null)
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            onSelected: (action) {
              if (action == 'hide') onHide();
              if (action == 'delete') onDelete?.call();
            },
            icon: const Icon(Icons.more_vert, size: 18),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Run tests**

Run: `flutter test test/widget/views/expanded/dhikr_tab_test.dart`
Expected: All 4 tests PASS

- [ ] **Step 7: Commit**

```bash
git add lib/views/expanded/dhikr_tab.dart lib/views/shared/add_dhikr_dialog.dart lib/views/shared/dhikr_selection_dialog.dart test/widget/views/expanded/dhikr_tab_test.dart
git commit -m "feat: add DhikrTab with active banner, flat list, and selection/add dialogs"
```

---

## Task 4.3: Build StatsTab

**Files:**
- Create: `lib/views/expanded/stats_tab.dart`
- Create: `test/widget/views/expanded/stats_tab_test.dart`

- [ ] **Step 1: Write failing widget tests**

```dart
// test/widget/views/expanded/stats_tab_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dhikratwork/viewmodels/stats_viewmodel.dart';
import 'package:dhikratwork/viewmodels/gamification_viewmodel.dart';
import 'package:dhikratwork/viewmodels/goal_viewmodel.dart';
import 'package:dhikratwork/views/expanded/stats_tab.dart';
import '../../../../fakes/fake_stats_repository.dart';
import '../../../../fakes/fake_streak_repository.dart';
import '../../../../fakes/fake_dhikr_repository.dart';
import '../../../../fakes/fake_achievement_repository.dart';
import '../../../../fakes/fake_goal_repository.dart';

Widget _buildTestApp() {
  final statsRepo = FakeStatsRepository();
  final streakRepo = FakeStreakRepository();
  final dhikrRepo = FakeDhikrRepository();
  final achievementRepo = FakeAchievementRepository();
  final goalRepo = FakeGoalRepository();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => StatsViewModel(
          statsRepository: statsRepo,
          streakRepository: streakRepo,
          dhikrRepository: dhikrRepo,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => GamificationViewModel(
          achievementRepository: achievementRepo,
          streakRepository: streakRepo,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => GoalViewModel(
          goalRepository: goalRepo,
          statsRepository: statsRepo,
        ),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: StatsTab())),
  );
}

void main() {
  testWidgets('renders period selector with Day/Week/Month', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    expect(find.text('Day'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
  });

  testWidgets('renders stat cards row', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Streak'), findsOneWidget);
  });

  testWidgets('renders XP progress section', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('Level'), findsWidgets);
  });

  testWidgets('renders Achievements header', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    expect(find.text('Achievements'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/widget/views/expanded/stats_tab_test.dart`
Expected: FAIL — `stats_tab.dart` is a stub

- [ ] **Step 3: Implement StatsTab**

```dart
// lib/views/expanded/stats_tab.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dhikratwork/app/theme.dart';
import 'package:dhikratwork/viewmodels/stats_viewmodel.dart';
import 'package:dhikratwork/viewmodels/gamification_viewmodel.dart';
import 'package:dhikratwork/viewmodels/goal_viewmodel.dart';
import 'package:dhikratwork/views/stats/stats_bar_chart.dart';
import 'package:dhikratwork/views/stats/stats_line_chart.dart';
import 'package:dhikratwork/views/stats/xp_progress_bar.dart';
import 'package:dhikratwork/views/stats/goal_progress_card.dart';
import 'package:dhikratwork/views/shared/achievement_badge.dart';

/// Stats tab in expanded mode: period selector, stat cards, XP, charts,
/// achievements, goals.
class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsViewModel>().loadStats();
      context.read<GamificationViewModel>().loadGamification();
      context.read<GoalViewModel>().loadGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsVm = context.watch<StatsViewModel>();
    final gamificationVm = context.watch<GamificationViewModel>();
    final goalVm = context.watch<GoalViewModel>();

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period selector.
            _PeriodSelector(
              selected: statsVm.selectedPeriod,
              onChanged: (p) => statsVm.setPeriod(p),
            ),

            const SizedBox(height: 16),

            // Stat cards row.
            _StatCardsRow(
              totalCount: statsVm.totalCountForPeriod,
              currentStreak: statsVm.currentStreak,
              currentLevel: gamificationVm.currentLevel,
              levelName: gamificationVm.levelName,
            ),

            const SizedBox(height: 16),

            // XP progress bar (reuses existing widget).
            XpProgressBar(
              levelName: gamificationVm.levelName,
              currentLevel: gamificationVm.currentLevel,
              totalXp: gamificationVm.totalXp,
              xpForNextLevel: gamificationVm.xpForNextLevel,
              progress: gamificationVm.xpProgress,
              currentStreak: gamificationVm.currentStreak,
              longestStreak: gamificationVm.longestStreak,
            ),

            const SizedBox(height: 16),

            // Charts.
            if (statsVm.barChartData.isNotEmpty) ...[
              Text('By Dhikr',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: StatsBarChart(data: statsVm.barChartData),
              ),
              const SizedBox(height: 16),
            ],

            if (statsVm.lineChartData.isNotEmpty) ...[
              Text('Daily Totals',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: StatsLineChart(data: statsVm.lineChartData),
              ),
              const SizedBox(height: 16),
            ],

            // Achievements.
            Text('Achievements',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: gamificationVm.achievements
                  .map((a) => AchievementBadge(achievement: a))
                  .toList(),
            ),

            const SizedBox(height: 16),

            // Goals.
            if (goalVm.goals.isNotEmpty) ...[
              Text('Goals',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...goalVm.goals.map((goal) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GoalProgressCard(
                      goal: goal,
                      progress: goalVm.goalProgress[goal.id] ?? 0.0,
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'day', label: Text('Day')),
        ButtonSegment(value: 'week', label: Text('Week')),
        ButtonSegment(value: 'month', label: Text('Month')),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _StatCardsRow extends StatelessWidget {
  final int totalCount;
  final int currentStreak;
  final int currentLevel;
  final String levelName;

  const _StatCardsRow({
    required this.totalCount,
    required this.currentStreak,
    required this.currentLevel,
    required this.levelName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total',
            value: '$totalCount',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Streak',
            value: '$currentStreak \ud83d\udd25',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Level $currentLevel',
            value: levelName,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kGoldAccent)),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
```

**Note:** The `StatsBarChart`, `StatsLineChart`, `XpProgressBar`, `GoalProgressCard`, and `AchievementBadge` widgets are reused from their existing locations. Their constructor signatures may need minor adaptation — read the existing widget files during implementation to match exact prop names. If constructor params differ, create thin wrapper methods.

- [ ] **Step 4: Run tests**

Run: `flutter test test/widget/views/expanded/stats_tab_test.dart`
Expected: All 4 tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/views/expanded/stats_tab.dart test/widget/views/expanded/stats_tab_test.dart
git commit -m "feat: add StatsTab with period selector, stat cards, charts, achievements, goals"
```

---

## Task 4.4: Build SettingsTab

**Files:**
- Create: `lib/views/expanded/settings_tab.dart`
- Create: `test/widget/views/expanded/settings_tab_test.dart`

- [ ] **Step 1: Write failing widget tests**

```dart
// test/widget/views/expanded/settings_tab_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/views/expanded/settings_tab.dart';
import '../../../../fakes/fake_settings_repository.dart';
import '../../../../fakes/fake_dhikr_repository.dart';
import '../../../../fakes/fake_subscription_service.dart';

Widget _buildTestApp(SettingsViewModel vm) {
  return MaterialApp(
    home: ChangeNotifierProvider<SettingsViewModel>.value(
      value: vm,
      child: const Scaffold(body: SettingsTab()),
    ),
  );
}

void main() {
  late SettingsViewModel vm;

  setUp(() {
    vm = SettingsViewModel(
      settingsRepository: FakeSettingsRepository(),
      dhikrRepository: FakeDhikrRepository(),
      subscriptionService: FakeSubscriptionService(),
    );
  });

  testWidgets('renders all section headings', (tester) async {
    await tester.pumpWidget(_buildTestApp(vm));
    await tester.pumpAndSettle();
    expect(find.text('Global Hotkey'), findsOneWidget);
    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('Data Export'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('hotkey string is displayed', (tester) async {
    await tester.pumpWidget(_buildTestApp(vm));
    await tester.pumpAndSettle();
    expect(find.text('ctrl+shift+d'), findsOneWidget);
  });

  testWidgets('no Floating Widget section', (tester) async {
    await tester.pumpWidget(_buildTestApp(vm));
    await tester.pumpAndSettle();
    expect(find.text('Floating Widget'), findsNothing);
  });

  testWidgets('Subscribe button shown when not subscribed', (tester) async {
    await tester.pumpWidget(_buildTestApp(vm));
    await tester.pumpAndSettle();
    expect(find.text('Subscribe \u2014 \$5/month'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/widget/views/expanded/settings_tab_test.dart`
Expected: FAIL — `settings_tab.dart` is a stub

- [ ] **Step 3: Implement SettingsTab**

```dart
// lib/views/expanded/settings_tab.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dhikratwork/app/theme.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/views/settings/hotkey_record_dialog.dart';

/// Settings tab in expanded mode: hotkey, subscription, export, about.
/// No floating widget section (removed in redesign).
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsViewModel>().loadSettings();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final textTheme = Theme.of(context).textTheme;

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Global Hotkey ---
                Text('Global Hotkey', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        vm.hotkeyString,
                        style: GoogleFonts.firaCode(
                            fontSize: 14, color: kGoldAccent),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => _onRecordHotkey(context, vm),
                      child: const Text('Record New'),
                    ),
                  ],
                ),
                if (vm.hotkeyError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(vm.hotkeyError!,
                        style: textTheme.bodySmall
                            ?.copyWith(color: Colors.redAccent)),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Supports modifier+key combos (Ctrl+Shift+D) and single F-keys (F9).',
                  style: textTheme.bodySmall,
                ),

                const _SectionDivider(),

                // --- Subscription ---
                Text('Subscription', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  vm.isSubscribed
                      ? 'Subscribed as ${vm.subscriptionEmail ?? "unknown"}'
                      : 'Free plan',
                  style: textTheme.bodyMedium,
                ),
                if (!vm.isSubscribed) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => launchUrl(
                        Uri.parse('https://buy.stripe.com/placeholder')),
                    icon: const Icon(Icons.star),
                    label: const Text('Subscribe \u2014 \$5/month'),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'your@email.com',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    vm.isVerifyingSubscription
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : OutlinedButton(
                            onPressed: () => vm.verifySubscription(
                                _emailController.text.trim()),
                            child: const Text('Verify'),
                          ),
                  ],
                ),
                if (vm.subscriptionError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(vm.subscriptionError!,
                        style: textTheme.bodySmall
                            ?.copyWith(color: Colors.redAccent)),
                  ),
                if (vm.isSubscribed)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Subscription verified. JazakAllahu Khayran.',
                      style:
                          textTheme.bodySmall?.copyWith(color: Colors.green),
                    ),
                  ),

                const _SectionDivider(),

                // --- Data Export ---
                Text('Data Export', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: vm.isExporting
                          ? null
                          : () => vm.exportData('json'),
                      icon: const Icon(Icons.file_download),
                      label: const Text('Export JSON'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: vm.isExporting
                          ? null
                          : () => vm.exportData('csv'),
                      icon: const Icon(Icons.file_download),
                      label: const Text('Export CSV'),
                    ),
                  ],
                ),
                if (vm.exportError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(vm.exportError!,
                        style: textTheme.bodySmall
                            ?.copyWith(color: Colors.redAccent)),
                  ),

                const _SectionDivider(),

                // --- About ---
                Text('About', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('DhikrAtWork v0.1.0', style: textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onRecordHotkey(
      BuildContext context, SettingsViewModel vm) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const HotkeyRecordDialog(),
    );
    if (result != null && context.mounted) {
      await vm.changeHotkey(result);
    }
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Divider(),
    );
  }
}
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/widget/views/expanded/settings_tab_test.dart`
Expected: All 4 tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/views/expanded/settings_tab.dart test/widget/views/expanded/settings_tab_test.dart
git commit -m "feat: add SettingsTab with hotkey recorder, subscription, export, about"
```

---

## Phase 4 Validation

```bash
flutter analyze
flutter test test/widget/views/expanded/
```

Expected: All analyze issues are clean (aside from old files scheduled for Phase 6 deletion). All widget tests PASS.
