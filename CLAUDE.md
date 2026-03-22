# DhikrAtWork

Islamic dhikr tracking desktop app (Windows + macOS). Flutter, MVVM + Provider, local SQLite. Single window with two modes: compact always-on-top counter bar (520x100) and expanded tabbed interface (700x500).

## Commands

```bash
# Dev
.\run.ps1                          # debug with hot reload (r/R/q)
.\run.ps1 -Release                 # release mode run

# Build pipeline (clean → pub get → analyze → test → build)
.\build.ps1                        # full clean release build
.\build.ps1 -SkipClean -SkipTests  # quick rebuild

# macOS build pipeline (same steps, bash)
./build.sh                          # full clean release build
./build.sh --skip-clean --skip-tests  # quick rebuild

# Individual steps
flutter test                                    # ~300 unit + widget tests
flutter test integration_test/ -d windows       # integration tests (needs running window)
flutter pub run msix:create                     # MSIX package (needs cert configured)
```

## Architecture

MVVM + Provider. Manual constructor injection — no service locator except `AppLocator` for 2 cross-feature VMs (CounterViewModel, SettingsViewModel).

```
lib/
  app/         # theme, AppLocator
  data/        # seed data
  models/      # immutable domain objects (const, copyWith, fromMap/toMap)
  repositories/ # DB access with in-memory cache + List.unmodifiable returns
  services/    # platform integrations (DB, tray, hotkey, update, subscription)
  utils/       # constants.dart — ALL SQL names live here
  viewmodels/  # ChangeNotifier VMs
  views/       # app_shell.dart, compact/, expanded/, shared/, stats/, settings/
```

## Gotchas

- **Debug CRT on Windows**: x64 `ucrtbased.dll` is missing from System32. After `flutter clean`, debug builds fail with "The log reader stopped unexpectedly". Fix: `Copy-Item "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\ucrt\ucrtbased.dll" "F:\Tools\Projects\dhikratwork\build\windows\x64\runner\Debug\"` — or copy to `C:\Windows\System32\` as admin for a permanent fix.
- **SQL constants only**: Never use raw table/column strings. All names are in `lib/utils/constants.dart` — tables: `t{Name}`, columns: `c{Table}{Column}`, domain values: `k{Category}{Value}`.
- **Single-window, two modes**: `AppShellViewModel` owns `AppMode.compact`/`AppMode.expanded`. `AppShell` widget crossfades between `CompactCounterBar` and `ExpandedShell`, calling `window_manager` for OS-level transitions (size, always-on-top, title bar, taskbar). No multi-window or IPC.
- **Compact bar position**: Persisted via `widgetPositionX`/`widgetPositionY` in `UserSettings`. `AppShellViewModel.saveCompactPosition()` writes; `loadSavedPosition()` reads.
- **Test import depth**: From `test/widget/views/{subfolder}/`, fakes are at `../../../fakes/` (3 levels up, not 4).
- **Window close → tray**: `onWindowClose()` hides the window; it doesn't destroy it. Quit only via tray menu.
- **Hotkey callback wiring**: `SettingsViewModel` and `CounterViewModel` have a circular dependency broken by post-construction callback: `settingsVm.setHotkeyTriggerCallback(() => counterVm.incrementActiveDhikr(source: 'hotkey'))`.
- **Hotkey scope fallback**: `HotkeyRecordDialog` allows bare keys. Modifier combos register as `system` scope (works in background); bare single keys try `system` first, then fall back to `inapp` scope (works only when app is focused). The dialog shows a scope hint to the user. `onRegistrationFailed` callback receives a `reason` string.
- **Boolean fields in SQLite**: Stored as `int` (0/1). Deserialize with `(map[col] as int) == 1`.
- **Cache invalidation**: All repo writes call `_invalidateCache()` (sets `_cache = null`). Reads check `_cache != null` before querying.
- **fl_chart zero guard**: Stats charts clamp `maxY` to `5.0` minimum. Without this, all-zero periods make `horizontalInterval` zero, crashing fl_chart with an assertion.
- **macOS sandbox disabled**: Entitlements have `app-sandbox = false`. Required for system-scope global hotkeys (`hotkey_manager`). If re-enabled for Mac App Store, system-scope hotkeys will silently fail — only `inapp` scope will work.
- **Build output paths**: Windows: `build\windows\x64\runner\Release\` (zip entire folder). macOS: `build/macos/Build/Products/Release/dhikratwork.app`.
- **Package imports only**: Always use `package:dhikratwork/...` — never relative imports.
- **Subscription is NoOp**: `NoOpSubscriptionService` always returns `false`. The `SubscriptionService` interface is ready for a real backend later.
- **AppLocator.reset()**: Must be called in teardown of any test that calls `AppLocator.initialize()`.

## Testing

Three tiers, all using fakes (never mocks):
- **Unit/repos**: `FakeDatabaseService` (in-memory map store) + real repository
- **Unit/VMs**: `Fake{Repository}` classes with `seed()`/`reset()` methods
- **Widget**: `ChangeNotifierProvider.value` wrapping fakes, pump screen, verify UI
- **Integration**: Real `DatabaseService` with `dbPath: inMemoryDatabasePath`

Fake naming: `Fake{ClassName}`. All in `test/fakes/`.

## Release Checklist

- [ ] Replace `YOUR_CERT_PASSWORD` in `pubspec.yaml` msix_config
- [x] Replace `YOUR_ORG` in msix_config `uri` field
- [ ] Replace `YOUR_ED25519_SIGNATURE` in `appcast.xml`
- [x] Replace `YOUR_ORG` in `README.md` (5 occurrences)
- [x] Replace `YOUR_ORG` in `lib/services/update_service.dart` appcast URL
- [ ] Provide `.ico` tray icon for Windows production (PNG fallback works for dev)
- [ ] Add macOS app icon (`.icns`) in `macos/Runner/Assets.xcassets`
- [ ] Set Apple Developer Team ID in Xcode project for macOS code signing
- [x] Choose and add a LICENSE file
