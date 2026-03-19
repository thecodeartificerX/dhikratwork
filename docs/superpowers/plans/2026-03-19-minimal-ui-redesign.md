# Minimal UI Redesign — Master Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform DhikrAtWork from a multi-window desktop app into a single-window, two-mode app (compact counter bar + expanded tabbed interface).

**Architecture:** Single Flutter window that morphs between a small always-on-top counter bar (compact mode) and a normal tabbed window (expanded mode). `AppShellViewModel` owns the mode state; `window_manager` handles OS-level window properties. Multi-window/IPC infrastructure (desktop_multi_window, FloatingWindowManager, WindowMethodChannel) is removed entirely. ViewModels drop from 8 to 7 (remove WidgetToolbarViewModel + DashboardViewModel, add AppShellViewModel).

**Tech Stack:** Flutter 3.x, Provider, window_manager, hotkey_manager, tray_manager, sqflite_common_ffi, fl_chart, google_fonts

**Spec:** `docs/superpowers/specs/2026-03-19-minimal-ui-redesign-design.md`

---

## Phase Dependency Graph

```
Phase 1 (Backend)  ─┬─→ Phase 3 (Compact Bar)  ─┐
                     ├─→ Phase 4 (Expanded Mode)  ├─→ Phase 5 (AppShell + main.dart) → Phase 6 (Cleanup)
Phase 2 (Theme)    ─┘                             │
                                                   │
(Phase 2 has no deps, can run with Phase 1)       ─┘
```

## Phases

| Phase | File | Description | Depends On |
|-------|------|-------------|------------|
| 1 | `2026-03-19-minimal-ui-redesign-phase-1.md` | Backend: ViewModels & HotkeyService (5 tasks) | — |
| 2 | `2026-03-19-minimal-ui-redesign-phase-2.md` | Dark theme | — |
| 3 | `2026-03-19-minimal-ui-redesign-phase-3.md` | Compact Counter Bar widget | Phase 1 |
| 4 | `2026-03-19-minimal-ui-redesign-phase-4.md` | Expanded Mode: shell + 3 tabs | Phase 1 |
| 5 | `2026-03-19-minimal-ui-redesign-phase-5.md` | AppShell + main.dart + AppLocator + TrayService rewrite | Phases 1-4 |
| 6 | `2026-03-19-minimal-ui-redesign-phase-6.md` | Cleanup: delete old files, remove packages, integration tests | Phase 5 |

## Parallelization Strategy

- **Phase 1** has 5 independent tasks — all can run in parallel (TrayService + AppLocator moved to Phase 5)
- **Phase 2** has no dependencies — can run in parallel with Phase 1
- **Phases 3 and 4** depend on Phase 1 but are independent of each other — run in parallel
- **Phase 5** depends on 1-4 — sequential
- **Phase 6** depends on 5 — sequential

## File Structure (New/Modified)

### New Files
```
lib/viewmodels/app_shell_viewmodel.dart        # AppMode enum + mode/position state
lib/views/app_shell.dart                        # Top-level widget, crossfade between modes
lib/views/compact/compact_counter_bar.dart      # Compact horizontal bar
lib/views/expanded/expanded_shell.dart          # TabController + IndexedStack + window controls
lib/views/expanded/dhikr_tab.dart               # Active banner + flat dhikr list + add dialog
lib/views/expanded/stats_tab.dart               # Period selector, stat cards, charts, achievements, goals
lib/views/expanded/settings_tab.dart            # Hotkey, subscription, export, about
lib/views/shared/add_dhikr_dialog.dart          # Dialog version of add custom dhikr
lib/views/shared/dhikr_selection_dialog.dart     # Confirmation dialog for selecting active dhikr
test/unit/viewmodels/app_shell_viewmodel_test.dart
test/unit/services/hotkey_service_test.dart
test/widget/views/compact/compact_counter_bar_test.dart
test/widget/views/expanded/expanded_shell_test.dart
test/widget/views/expanded/dhikr_tab_test.dart
test/widget/views/expanded/stats_tab_test.dart
test/widget/views/expanded/settings_tab_test.dart
integration_test/mode_switch_integration_test.dart
```

### Modified Files
```
lib/viewmodels/counter_viewmodel.dart           # Remove toolbar sync, add session tracking + reset methods
lib/viewmodels/dhikr_library_viewmodel.dart     # Remove category filtering
lib/viewmodels/stats_viewmodel.dart             # Add streak, dhikr name resolution dependencies
lib/services/hotkey_service.dart                # Add F1-F12 key support
lib/services/tray_service.dart                  # Simplify to quit-only (Phase 5, atomic with main.dart)
lib/app/app_locator.dart                        # Remove WidgetToolbarViewModel, 2-VM signature (Phase 5, atomic with main.dart)
lib/app/theme.dart                              # Dark navy + gold accent
lib/repositories/stats_repository.dart          # Add resetDailySummary method
lib/main.dart                                   # Full rewrite: single window, compact start
pubspec.yaml                                    # Remove desktop_multi_window, go_router
test/fakes/fake_stats_repository.dart           # Add resetDailySummary
test/unit/viewmodels/counter_viewmodel_test.dart
test/unit/viewmodels/dhikr_library_viewmodel_test.dart
test/unit/viewmodels/stats_viewmodel_test.dart
integration_test/hotkey_integration_test.dart
```

### Files to Delete
```
lib/viewmodels/widget_toolbar_viewmodel.dart
lib/viewmodels/dashboard_viewmodel.dart
lib/views/widget/floating_toolbar.dart
lib/views/dashboard/dashboard_screen.dart
lib/views/library/library_screen.dart
lib/views/library/dhikr_detail_screen.dart
lib/views/library/add_dhikr_screen.dart
lib/views/settings/settings_screen.dart
lib/views/settings/dhikr_multi_select.dart
lib/views/shared/dhikr_counter_tile.dart
lib/views/shared/subscription_prompt.dart
lib/views/stats/stats_screen.dart
lib/services/floating_window_manager.dart
lib/app/router.dart
test/unit/viewmodels/widget_toolbar_viewmodel_test.dart
test/unit/viewmodels/dashboard_viewmodel_test.dart
test/widget/views/floating_toolbar_test.dart
test/widget/views/dashboard/dashboard_screen_test.dart
test/widget/views/library/library_screen_test.dart
test/widget/views/library/add_dhikr_screen_test.dart
test/widget/views/settings/settings_screen_test.dart
test/widget/views/stats/stats_screen_test.dart
```

### Files Kept As-Is (reused by new tabs)
```
lib/views/stats/stats_bar_chart.dart
lib/views/stats/stats_line_chart.dart
lib/views/stats/xp_progress_bar.dart
lib/views/stats/goal_progress_card.dart
lib/views/settings/hotkey_record_dialog.dart
lib/views/shared/achievement_badge.dart
lib/views/shared/splash_screen.dart
```

## Validation Gate (End of Each Phase)

After each phase, run:
```bash
flutter analyze
flutter test
```
All must pass before moving to the next phase.
