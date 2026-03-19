# DhikrAtWork — Minimal UI Redesign

## Overview

Transform DhikrAtWork from a multi-window desktop app into a single-window app with two modes: a compact always-on-top counter bar and an expanded tabbed interface. The core principle is simplicity — one active dhikr, one hotkey, one window.

## Architecture

### Single-Window, Two-Mode Design

The app runs in a single Flutter window that transforms between two modes:

- **Compact mode**: A small horizontal bar (~360 × 60px, dimensions approximate — refine during implementation), always-on-top, no title bar, hidden from taskbar. Shows the active dhikr and its counters. Incrementing happens only via the global hotkey.
- **Expanded mode**: A normal windowed app (700 × 500px, fixed size), not always-on-top, visible title bar. Three tabs: Dhikr, Stats, Settings.

A top-level `AppShellViewModel` holds an `AppMode` enum (`compact` / `expanded`) and orchestrates window state changes via `window_manager`.

### What Gets Removed

- `desktop_multi_window` package — no more multi-window/multi-isolate architecture
- `FloatingWindowManager` service
- `FloatingToolbarApp` / `floating_toolbar.dart`
- Sub-window detection branch in `main()`
- `WidgetToolbarViewModel` — responsibilities merge into `CounterViewModel`
- All IPC / `WindowMethodChannel` code
- `DashboardScreen`, `DashboardViewModel` — replaced by compact mode + Stats tab
- `LibraryScreen` layout (category sidebar) — replaced by flat list in Dhikr tab
- `DhikrDetailScreen` — detail info shown inline in confirmation dialog and active banner
- `DhikrMultiSelect` widget — no longer needed (compact bar shows only the single active dhikr)
- Category filtering — removed; flat list only
- `go_router` package and `router.dart` — replaced by `TabController` / `IndexedStack` inside `ExpandedShell`
- `CounterViewModel.incrementActiveDhikr()` cross-VM sync block — the try/catch block that calls `AppLocator.instance.widgetToolbarViewModel.incrementDhikr()` is deleted entirely since the toolbar VM no longer exists

### What Stays (Unchanged)

- All repositories — unchanged
- All domain models — unchanged
- Database schema — unchanged
- `UpdateService` and `auto_updater` package — unchanged

### What Stays (Modified)

- `window_manager` — now also handles title bar toggling, always-on-top, taskbar visibility
- `AppLocator` — holds `CounterViewModel` and `SettingsViewModel` only (2 VMs, down from 3). `AppShellViewModel` is provided solely via the widget tree's `Provider`, not registered in `AppLocator`.
  - New `initialize()` signature: `initialize({required CounterViewModel counterViewModel, required SettingsViewModel settingsViewModel})`
- `TrayService` — simplified:
  - New `setup()` signature: `setup({required VoidCallback onQuit})`
  - Context menu: single item — "Quit DhikrAtWork"
  - Left-click tray icon: no action (previously toggled main window visibility)
- `HotkeyService` — expanded to support single keys (F-keys). Mouse button combos deferred to future enhancement (see HotkeyService section).

### ViewModel Structure (7 total, down from 8)

| ViewModel | Role | Changes |
|---|---|---|
| **`AppShellViewModel`** (new) | Holds `AppMode`, manages window state transitions | New. Provided via widget tree only, not in `AppLocator`. |
| `CounterViewModel` | Active dhikr, session, today counts | Absorbs widget toolbar counting; remove `AppLocator.instance.widgetToolbarViewModel` sync block from `incrementActiveDhikr()` |
| `DhikrLibraryViewModel` | Flat dhikr list, CRUD | Remove category filtering |
| `StatsViewModel` | Charts, period selection, summary cards | Absorbs dashboard summary data. New dependencies: `StreakRepository`, `SettingsRepository`, `DhikrRepository` (for resolving dhikr names on stat cards) |
| `GoalViewModel` | Goals and progress | Unchanged |
| `GamificationViewModel` | XP, levels, streaks, achievements | Unchanged |
| `SettingsViewModel` | Settings, hotkey, subscription, export | Unchanged |

**Removed:** `WidgetToolbarViewModel`, `DashboardViewModel`

### Navigation

The `go_router` package and `router.dart` are removed. Navigation within the expanded view is handled by a `TabController` with an `IndexedStack` inside `ExpandedShell`. The three tabs (Dhikr, Stats, Settings) are rendered as `TabBarView` children. No URL-based routing is needed for a desktop-only app with a flat tab structure.

The "Add Custom" flow and confirmation dialogs are `showDialog()` calls — not route-based navigation.

## Compact Mode

### Layout (~360 × 60px horizontal bar)

Left to right:
1. **Drag handle** — 6-dot grip pattern for repositioning
2. **Arabic text** — serif font, gold (#e2c272), RTL, ellipsis overflow
3. **Transliteration** — small text below Arabic
4. **Divider** — subtle vertical line
5. **Session count** — large bold gold number with "session" label
6. **Today count** — smaller muted number with "today" label
7. **Divider**
8. **Hotkey badge** — monospace label showing current hotkey (e.g. `Ctrl+Shift+D`)
9. **Expand button** — icon to switch to expanded mode

Dimensions are approximate. If Arabic text with diacritics (tashkeel) needs more vertical space, increase bar height to ~72px during implementation.

### Behavior

- **Always on top** unless explicitly minimized
- **Draggable** — drag handle repositions; position persisted to `UserSettings`
- **Default position**: top-right corner of screen
- **Not click-through** — captures focus when clicked
- **Hotkey-only incrementing** — no tap-to-increment; the hotkey fires `CounterViewModel.incrementActiveDhikr()`
- **Right-click context menu** on the count area (session count or today count):
  - Reset Session Count
  - Reset Today's Count
  - End Session

### No Active Dhikr State

When no dhikr is selected, the bar shows dimmed with centered text: "No dhikr selected — Click expand to choose one". The expand button is highlighted gold to draw attention.

## Expanded Mode

### Window Properties

- Size: 700 × 500px (fixed, not resizable)
- Title bar: normal (OS-native or custom)
- Always-on-top: no
- Taskbar: visible
- Custom title bar buttons: minimize (gray), collapse to compact (gold), close to tray (red)

### Tab Bar

Three tabs across the top: **Dhikr**, **Stats**, **Settings**. Active tab has gold underline and text. Inactive tabs are muted.

### Dhikr Tab

Top to bottom:
1. **Active Dhikr Banner** — highlighted card showing currently active dhikr (Arabic, transliteration, translation) with session count. "CURRENTLY ACTIVE" label.
2. **Hotkey Display** — read-only inline display of current hotkey badge with "Change in Settings" link that switches to the Settings tab.
3. **Dhikr List** — flat scrollable list (no categories). Each row shows:
   - Active indicator dot (gold filled = active, empty circle = inactive)
   - Arabic text + transliteration inline
   - Today's count badge
   - "Active" label on current dhikr
4. **"+ Add Custom" button** — top-right of list, opens add dhikr dialog

**Selection flow**: Tap a dhikr → confirmation dialog appears → shows Arabic text, transliteration, translation → Cancel / Confirm buttons. On confirm: the previous session (if any) is ended, that dhikr becomes active, and a new session starts.

**CRUD operations**: Right-click context menu on list items for Hide/Delete. Add Custom opens a dialog with fields: Name, Arabic Text, Transliteration, Translation, Target Count (optional). Custom dhikrs are assigned `category: 'custom'` automatically — the category field is not exposed in the form.

### Stats Tab

Top to bottom:
1. **Period Selector** — segmented button: Day / Week / Month
2. **Stat Cards Row** — three cards side by side:
   - Total count for period
   - Day streak (with fire emoji)
   - Current level + level name
3. **XP Progress Bar** — shows current XP / next threshold, level name, progress bar
4. **Charts** — daily totals chart (existing `StatsBarChart` / `StatsLineChart` adapted)
5. **Achievements** — grid of achievement badges (existing, adapted to fit)
6. **Goals** — goal progress cards (existing, adapted)

### Settings Tab

Sections with dividers:
1. **Global Hotkey** — full recorder with current hotkey displayed, "Record New" button, helper text about supported input types. This is the canonical location for changing the hotkey.
2. **Subscription** — status display, subscribe button, email verification
3. **Data Export** — JSON and CSV export buttons
4. **About** — version number

## Session Lifecycle

Sessions track continuous counting of a specific dhikr.

- **Start**: A new session begins when the user confirms a dhikr selection via the confirmation dialog, or on app startup if an active dhikr exists and no open session is found.
- **End**: A session ends when (a) the user selects a different dhikr (previous session auto-ends), (b) the user explicitly clicks "End Session" in the right-click context menu, or (c) the app quits.
- **Reset Session Count**: Ends the current session and immediately starts a new one for the same dhikr. The displayed session count resets to 0.
- **Reset Today's Count**: Resets the `daily_summary` total for the active dhikr for today to 0.
- **App restart**: On startup, if an active dhikr is set in settings and the last session for that dhikr is still open (no `ended_at`), resume it — the session count picks up where it left off. If the last session is closed, start a fresh one.

## Transitions

### Compact → Expanded

1. User clicks expand button
2. `AppShellViewModel.setMode(AppMode.expanded)`
3. `window_manager` sequence: `setAlwaysOnTop(false)` → `setTitleBarStyle(TitleBarStyle.normal)` → `setSkipTaskbar(false)` → `setSize(700, 500)` → `setAlignment(Alignment.center)`
4. Widget tree crossfades from `CompactCounterBar` to `ExpandedShell`

### Expanded → Compact

1. User clicks gold collapse dot or presses `Esc` (only when no dialog/overlay is open and no text field has focus)
2. `AppShellViewModel.setMode(AppMode.compact)`
3. `window_manager` sequence: `setSize(360, 60)` → `setPosition(savedX, savedY)` → `setTitleBarStyle(TitleBarStyle.hidden)` → `setSkipTaskbar(true)` → `setAlwaysOnTop(true)`
4. Widget tree crossfades to `CompactCounterBar`

### Esc Key Behavior

- **Compact mode**: `Esc` does nothing (use expand button to expand)
- **Expanded mode, dialog open**: `Esc` closes the dialog (standard Flutter behavior)
- **Expanded mode, text field focused**: `Esc` unfocuses the text field
- **Expanded mode, nothing focused/open**: `Esc` collapses to compact mode

## Startup Flow

1. `main()` → initialize `DatabaseService`, all repositories, all ViewModels
2. `AppLocator.initialize(counterViewModel: counterVm, settingsViewModel: settingsVm)`
3. Wire hotkey callback: `settingsVm.setHotkeyTriggerCallback(() => counterVm.incrementActiveDhikr(source: 'hotkey'))`
4. Defer window visibility until initialization completes (`windowManager.waitUntilReadyToShow()`)
5. Mount `AppShell` widget
6. App starts in **compact mode** — small bar, top-right, always-on-top
7. Apply saved hotkey from settings
8. Resume active session if one exists (see Session Lifecycle)
9. Initialize tray (quit option only)

## Theme

Dark theme throughout (both modes). Gold accent (#e2c272) on dark navy (#16213e / #0d1520) background. Matches the existing floating toolbar aesthetic rather than the current light main-window theme.

## HotkeyService Expansion

The existing `HotkeyService` is extended to support:
- **Modifier + key combos**: `ctrl+shift+d` (existing)
- **Single keys**: `f9`, `f10`, etc. — extend `parseHotKey()` to recognize F-key labels

**Mouse button support is deferred** to a future enhancement. The current `hotkey_manager` package uses `LogicalKeyboardKey` and cannot register mouse buttons as system-wide hotkeys. Supporting mouse buttons would require a native FFI solution or custom platform channel, which is out of scope for this redesign. The `HotkeyRecordDialog` can capture mouse events via `Listener.onPointerDown` but global registration has no existing package support.

The `parseHotKey()` function must be extended to handle F-key labels (`f1` through `f12`).

## Testing Strategy

- **Unit tests**: `AppShellViewModel` mode toggling, `CounterViewModel` with absorbed toolbar logic, session lifecycle edge cases
- **Widget tests**: `CompactCounterBar` rendering, `ExpandedShell` tab switching, confirmation dialog flow, Esc key behavior in various focus states
- **Integration tests**: full compact→expanded→compact cycle with real DB

All existing test fakes remain valid. `FakeWidgetToolbarViewModel` and `FakeDashboardViewModel` can be removed.

## Migration Notes

- Existing `UserSettings` schema is unchanged — `widgetDhikrIds` field becomes unused but harmless
- `widgetPositionX/Y` repurposed for compact bar position (same semantics)
- `widgetVisible` field becomes unused (compact mode is always the starting state)
- No database migration needed
- Custom dhikrs created without a category field get `category: 'custom'` by default
