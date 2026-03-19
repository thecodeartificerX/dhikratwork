# DhikrAtWork

Islamic dhikr tracking desktop app (Windows + macOS). Flutter, MVVM + Provider, local SQLite.

## Commands

```bash
# Dev
.\run.ps1                          # debug with hot reload (r/R/q)
.\run.ps1 -Release                 # release mode run

# Build pipeline (clean → pub get → analyze → test → build)
.\build.ps1                        # full clean release build
.\build.ps1 -SkipClean -SkipTests  # quick rebuild

# Individual steps
flutter test                                    # 261 unit + widget tests
flutter test integration_test/ -d windows       # integration tests (needs running window)
flutter pub run msix:create                     # MSIX package (needs cert configured)
```

## Architecture

MVVM + Provider. Manual constructor injection — no service locator except `AppLocator` for 3 cross-feature VMs.

```
lib/
  app/         # router, theme, AppLocator
  data/        # seed data
  models/      # immutable domain objects (const, copyWith, fromMap/toMap)
  repositories/ # DB access with in-memory cache + List.unmodifiable returns
  services/    # platform integrations (DB, tray, hotkey, floating window)
  utils/       # constants.dart — ALL SQL names live here
  viewmodels/  # ChangeNotifier VMs
  views/       # screens + shared widgets
```

## Gotchas

- **Debug CRT on Windows**: x64 `ucrtbased.dll` is missing from System32. After `flutter clean`, debug builds fail with "The log reader stopped unexpectedly". Fix: `Copy-Item "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\ucrt\ucrtbased.dll" "F:\Tools\Projects\dhikratwork\build\windows\x64\runner\Debug\"` — or copy to `C:\Windows\System32\` as admin for a permanent fix.
- **SQL constants only**: Never use raw table/column strings. All names are in `lib/utils/constants.dart` — tables: `t{Name}`, columns: `c{Table}{Column}`, domain values: `k{Category}{Value}`.
- **Multi-window isolation**: The floating toolbar (`desktop_multi_window` v0.3.0) runs in a separate Dart isolate. It does NOT share `AppLocator` or main-window VMs — it has its own DB/repos/VMs and syncs via `WindowMethodChannel` IPC.
- **Window close → tray**: `onWindowClose()` hides the window; it doesn't destroy it. Quit only via tray menu.
- **Hotkey callback wiring**: `SettingsViewModel` and `CounterViewModel` have a circular dependency broken by post-construction callback: `settingsVm.setHotkeyTriggerCallback(() => counterVm.incrementActiveDhikr(source: 'hotkey'))`.
- **Boolean fields in SQLite**: Stored as `int` (0/1). Deserialize with `(map[col] as int) == 1`.
- **Cache invalidation**: All repo writes call `_invalidateCache()` (sets `_cache = null`). Reads check `_cache != null` before querying.
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
- [ ] Replace `YOUR_ORG` in msix_config `uri` field
- [ ] Replace `YOUR_ORG` and `YOUR_ED25519_SIGNATURE` in `appcast.xml`
- [ ] Provide `.ico` tray icon for Windows production (PNG fallback works for dev)
