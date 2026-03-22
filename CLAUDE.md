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

# Release pipeline (Windows)
# Step 1 — generate self-signed cert (run once per machine; requires admin)
.\generate-cert.ps1                            # creates windows\signing\CERTIFICATE.pfx and DhikrAtWork.cer
# Step 2 — build MSIX + zip artifact + create draft GitHub release
$env:MSIX_CERT_PASSWORD="yourpassword" ; .\release.ps1 -Version 0.2.0 -Changelog "Release notes here"
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
dist/          # README-windows.txt, README-macos.txt — distribution README templates ({{VERSION}} substituted at release time)
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
- **Build cache corruption on Windows**: If `flutter build windows` fails with `PathExistsException` or `PathNotFoundException` for `sqlite3.dll` in `native_assets`, kill any running `dhikratwork.exe` processes, then `rm -rf build .dart_tool` and rebuild. `flutter clean` alone may fail to remove locked files.
- **Session lifecycle guard**: Any code that creates a new session must end the existing `_activeSession` first (check `_activeSession?.id != null`). See `setActiveDhikr`, `startSession`, `resetSessionCount` in `CounterViewModel` — all follow this pattern. Missing it causes duplicate open sessions and flaky tests on Linux CI (different sort order for same-timestamp records).
- **MSIX cert password via env var**: `release.ps1` reads the cert password from `$env:MSIX_CERT_PASSWORD`. Never hard-code the password. Set `$env:MSIX_CERT_PASSWORD` in the shell before running `release.ps1` or `flutter pub run msix:create`. The `.pfx` file (`windows\signing\CERTIFICATE.pfx`) is git-ignored; generate it once per machine with `.\generate-cert.ps1`.
- **Self-signed cert install required**: The MSIX package built with the self-signed cert will only install on machines that trust that cert. End-users must run the provided installer script (`Install.bat`) as admin, or import `DhikrAtWork.cer` into `Trusted Root Certification Authorities` manually, before installing the MSIX. Without this step, Windows shows "publisher can't be verified" and blocks installation.
- **appcast.xml ED25519 signature**: After each release build, regenerate the `sparkle:edSignature` value in `appcast.xml` using the Sparkle `sign_update` tool with the private key. Never ship a release with `YOUR_ED25519_SIGNATURE` still present — the macOS auto-updater will reject the update silently.

## Testing

Three tiers, all using fakes (never mocks):
- **Unit/repos**: `FakeDatabaseService` (in-memory map store) + real repository
- **Unit/VMs**: `Fake{Repository}` classes with `seed()`/`reset()` methods
- **Widget**: `ChangeNotifierProvider.value` wrapping fakes, pump screen, verify UI
- **Integration**: Real `DatabaseService` with `dbPath: inMemoryDatabasePath`

Fake naming: `Fake{ClassName}`. All in `test/fakes/`.

## Release Workflow

Two-step process: Windows first (creates draft release), then macOS (publishes it).

### Step 1 — Build MSIX + Draft Release (Windows)

Generate the cert once per machine (requires admin, commits `DhikrAtWork.cer`):
```powershell
.\generate-cert.ps1
```

Then run the release pipeline:
```powershell
$env:MSIX_CERT_PASSWORD = "your-cert-password"
.\release.ps1 -Version X.Y.Z -Changelog "What changed in this release"
```

This bumps `pubspec.yaml`, builds the MSIX, creates a distribution zip, and opens a **draft** GitHub Release. Do NOT publish the draft manually — `release.sh` does that.

### Step 2 — Build macOS + Publish Release (macOS)

Switch to a Mac and run:
```bash
./release.sh X.Y.Z
```

This builds the macOS app bundle, signs the zip with Sparkle, updates `appcast.xml`, uploads all macOS artifacts, and **publishes** the release as a full release (not pre-release).

**CRITICAL:** Never pass `--prerelease` to `gh release edit`. The `.appinstaller` URI uses `releases/latest/download/` which only resolves to full releases. Publishing as pre-release silently breaks Windows auto-updates for all existing users.

- Naming convention: `DhikrAtWork-v{X.Y.Z}-windows-x64.zip` / `DhikrAtWork-v{X.Y.Z}-macos-arm64.zip`
- SHA256 checksums are in separate `.sha256` files attached to the release — not embedded in the zip's README
- v0.1.0 released as Windows-only pre-release (2026-03-22)

## Release Checklist

- [ ] Run `.\generate-cert.ps1` and commit `DhikrAtWork.cer` to the repo
- [x] Replace `YOUR_CERT_PASSWORD` in `pubspec.yaml` msix_config — resolved: cert password now read from `$env:MSIX_CERT_PASSWORD` env var via `release.ps1`; never hard-coded
- [x] Replace `YOUR_ORG` in msix_config `uri` field
- [ ] Replace `YOUR_ED25519_SIGNATURE` in `appcast.xml`
- [x] Replace `YOUR_ORG` in `README.md` (5 occurrences)
- [x] Replace `YOUR_ORG` in `lib/services/update_service.dart` appcast URL
- [ ] Provide `.ico` tray icon for Windows production (PNG fallback works for dev)
- [ ] Add macOS app icon (`.icns`) in `macos/Runner/Assets.xcassets`
- [ ] Set Apple Developer Team ID in Xcode project for macOS code signing
- [x] Choose and add a LICENSE file
