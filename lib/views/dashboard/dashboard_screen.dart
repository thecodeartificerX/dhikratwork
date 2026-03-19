// lib/views/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dhikratwork/viewmodels/dashboard_viewmodel.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/views/shared/dhikr_counter_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data after the first frame so the provider tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DhikrAtWork'),
        actions: [
          Tooltip(
            message: 'Dhikr Library',
            child: IconButton(
              icon: const Icon(Icons.menu_book),
              onPressed: () => context.go('/library'),
            ),
          ),
        ],
      ),
      body: Consumer<DashboardViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return _DashboardBody(vm: vm);
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.vm});

  final DashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop: single wide column capped at 900 px, centred.
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatsRow(vm: vm),
                    const SizedBox(height: 24),
                    _ProgressRing(progress: vm.dailyGoalProgress),
                    const SizedBox(height: 24),
                    _ActiveDhikrBanner(vm: vm),
                    const SizedBox(height: 24),
                    _QuickAccessGrid(vm: vm),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Stats Row — total count + streak
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.vm});

  final DashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: "Today's Total",
            value: vm.totalTodayCount.toString(),
            icon: Icons.touch_app,
            color: colorScheme.primaryContainer,
            onColor: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Day Streak',
            value: '${vm.currentStreak} 🔥',
            icon: Icons.local_fire_department,
            color: colorScheme.tertiaryContainer,
            onColor: colorScheme.onTertiaryContainer,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: onColor, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: onColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: onColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress Ring — TweenAnimationBuilder for smooth fill
// ---------------------------------------------------------------------------

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: value,
                        strokeWidth: 8,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        color: colorScheme.primary,
                      ),
                      Center(
                        child: Text(
                          '${(value * 100).round()}%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Goal Progress',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  progress >= 1.0
                      ? "Goal complete! Masha'Allah 🎉"
                      : 'Keep going — every dhikr counts.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active Dhikr Banner
// ---------------------------------------------------------------------------

class _ActiveDhikrBanner extends StatelessWidget {
  const _ActiveDhikrBanner({required this.vm});

  final DashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dhikr = vm.activeDhikr;

    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.keyboard, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: dhikr == null
                  ? Text(
                      'No active dhikr — tap one below or go to Library.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active (hotkey target)',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                        SelectableText(
                          dhikr.arabicText,
                          textDirection: TextDirection.rtl,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontFamily: 'Amiri',
                            color: colorScheme.onSecondaryContainer,
                            height: 1.8,
                          ),
                        ),
                        Text(
                          dhikr.transliteration,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
            ),
            if (dhikr != null)
              Tooltip(
                message: 'Change active dhikr in Library',
                child: TextButton(
                  onPressed: () => context.go('/library'),
                  child: const Text('Change'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Access Grid
// ---------------------------------------------------------------------------

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid({required this.vm});

  final DashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (vm.quickAccessDhikrs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Access', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // 2 columns on narrow, 3 on wide desktop.
            final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: vm.quickAccessDhikrs.length,
              itemBuilder: (context, index) {
                final dhikr = vm.quickAccessDhikrs[index];
                // Count for this dhikr from today's summaries.
                final summary = vm.todaySummaries
                    .where((s) => s.dhikrId == dhikr.id)
                    .firstOrNull;
                final count = summary?.totalCount ?? 0;
                final isActive = vm.activeDhikr?.id == dhikr.id;

                return DhikrCounterTile(
                  dhikr: dhikr,
                  count: count,
                  isActive: isActive,
                  onTap: () {
                    // Capture ViewModels before async gap.
                    final counterVm = context.read<CounterViewModel>();
                    final dashboardVm = context.read<DashboardViewModel>();
                    // Fire increment via CounterViewModel.
                    counterVm
                        .setActiveDhikr(dhikr.id!)
                        .then((_) => counterVm.increment());
                    // Refresh dashboard after increment.
                    dashboardVm.refreshSummary();
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
