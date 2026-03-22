# Contributing to DhikrAtWork

Thank you for your interest in contributing! This guide covers everything you need to get started.

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) 3.11 or later
- Windows 10+ or macOS 12+ for desktop builds
- Git

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/dhikratwork.git
   cd dhikratwork
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run -d windows   # or: -d macos
   ```

## Development Workflow

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Make your changes
3. Run analysis and tests:
   ```bash
   flutter analyze
   flutter test
   ```
4. Commit with a descriptive message
5. Push and open a pull request against `main`

## Code Conventions

### Architecture

MVVM + Provider with manual constructor injection. No code generation or service locators (except `AppLocator` for two cross-feature ViewModels).

### SQL Constants

All table and column names live in `lib/utils/constants.dart`. Never use raw SQL strings:
- Tables: `t{Name}` (e.g., `tDhikr`)
- Columns: `c{Table}{Column}` (e.g., `cDhikrName`)
- Domain values: `k{Category}{Value}` (e.g., `kCategoryGeneral`)

### Imports

Always use package imports:
```dart
import 'package:dhikratwork/models/dhikr.dart';
```
Never use relative imports.

### Typing

Use explicit, specific types everywhere. Avoid `dynamic` unless absolutely necessary.

### Models

Immutable with `const` constructors, `copyWith`, `fromMap`/`toMap`.

## Testing

Three tiers, all using **fakes** (never mocks):

- **Unit (repositories)** --- `FakeDatabaseService` with in-memory map store
- **Unit (ViewModels)** --- `Fake{Repository}` classes with `seed()`/`reset()` methods
- **Widget** --- `ChangeNotifierProvider.value` wrapping fakes, pump the screen, verify UI
- **Integration** --- Real `DatabaseService` with an in-memory SQLite database

All fakes live in `test/fakes/` and follow the naming pattern `Fake{ClassName}`.

### Running Tests

```bash
flutter test                                   # Unit + widget tests
flutter test integration_test/ -d windows      # Integration tests (needs running window)
```

## Priority: Donation System

The donation system is our most important missing feature. The `SubscriptionService` interface and settings UI are already scaffolded, but there is no real payment backend. We need help wiring up a payment provider (Stripe, RevenueCat, or similar) so users can subscribe to a $5/month donation that funds charitable relief efforts. If you have experience with payment integrations in Flutter, please reach out — this is where we need the most help right now.

See the [Donations & Payments roadmap](README.md#donations--payments) for the full scope.

## Good First Contributions

- **New preloaded adhkar** --- Add well-sourced dhikrs with Arabic text, transliteration, translation, and hadith references
- **Achievement ideas** --- New milestones and badges for the gamification system
- **Translations / localization** --- Help make the app accessible in more languages
- **Bug fixes** --- Check the [issues](https://github.com/thecodeartificerX/dhikratwork/issues) tab

## Pull Request Process

1. Open an issue (or comment on an existing one) to discuss your idea before starting work
2. Keep PRs focused --- one feature or fix per PR
3. Ensure `flutter analyze` and `flutter test` pass
4. Fill out the PR template
5. A maintainer will review your PR and may request changes

## Commit Messages

Use clear, descriptive commit messages:
- `feat: add Turkish localization`
- `fix: compact bar position not saved on multi-monitor`
- `test: add widget tests for stats tab`
- `docs: update installation instructions`

## Release Workflow

Releases are a two-machine, sequential process. **Windows must run first** (it builds the MSIX, bumps the version, and creates the draft GitHub Release). **macOS runs second** (it builds the macOS app, signs it with Sparkle, finalizes the release notes, and publishes the release).

This split exists because MSIX packaging requires Windows, and Sparkle EdDSA signing requires the private key that lives only in the macOS Keychain.

> **Never mark a release as pre-release.** The `.appinstaller` URI uses `releases/latest/download/` which only resolves to full (non-prerelease) releases. Publishing as pre-release silently breaks auto-updates for all existing Windows users. The v0.1.0 pre-release was a one-time bootstrap — all future releases must be full releases.

### Prerequisites

#### On Windows (one-time setup)

1. Run `.\generate-cert.ps1` — produces `DhikrAtWork.cer` (committed to repo) and `windows\signing\CERTIFICATE.pfx` (gitignored, never committed).
2. Note the certificate password you chose — you will pass it via the `MSIX_CERT_PASSWORD` environment variable. The `pubspec.yaml` placeholder `YOUR_CERT_PASSWORD` is **never replaced**; the password is always supplied at build time via the env var.
3. Install and authenticate `gh` CLI: `gh auth login`.

#### On macOS (one-time setup)

1. Check which Sparkle version `auto_updater` bundles: inspect `macos/Pods/Sparkle/` (after `pod install`) or read `auto_updater`'s podspec.
2. Download the **matching** Sparkle release archive from `https://github.com/sparkle-project/Sparkle/releases`. Do **not** use `brew install --cask sparkle` (installs the framework app, not the CLI tools).
3. Extract the archive and run `./bin/generate_keys` — the private key is saved to your macOS Keychain and the public key is printed to the terminal. Add the public key to `macos/Runner/Info.plist` as `SUPublicEDKey`.
4. Keep the extracted `./bin/sign_update` binary accessible for future releases (pass its directory via `--sparkle-tools-dir` each time you run `release.sh`).
5. Install and authenticate `gh` CLI: `gh auth login`.

### Step-by-Step Release Process

#### Step 1 — Windows: build MSIX and create draft release

```powershell
# Set the certificate password before running
$env:MSIX_CERT_PASSWORD = "your-cert-password"

# Run the release script
.\release.ps1 -Version X.Y.Z -Changelog "Added statistics screen, fixed hotkey bug"

# Multi-line changelog example:
.\release.ps1 -Version X.Y.Z -Changelog @"
- Added statistics screen
- Fixed global hotkey registration on Windows 11
- Performance improvements
"@
```

What this does:
- Validates prerequisites (`.pfx`, `.cer`, `MSIX_CERT_PASSWORD`, `gh` CLI)
- Pulls `main` and aborts if the working tree is dirty
- Bumps `version` and `msix_version` in `pubspec.yaml`, commits, and pushes to `main`
- Builds `flutter build windows --release` and signs the MSIX
- Packages the distribution zip (`README.txt`, `Install.bat`, `.cer`, `.msix`)
- Creates a **draft** GitHub Release with the changelog and uploads the Windows artifacts

Do **not** manually publish the draft — `release.sh` handles that.

#### Step 2 — macOS: build app, sign, and publish

```bash
# Pass the directory containing sign_update (from the extracted Sparkle archive)
./release.sh X.Y.Z --sparkle-tools-dir ~/sparkle-2.x/bin

# If sign_update is on your PATH or at ./bin/sign_update, omit the flag:
./release.sh X.Y.Z
```

What this does:
- Pulls `main` and verifies `pubspec.yaml` version matches (aborts if not, which means `release.ps1` did not complete)
- Builds `flutter build macos --release`
- Signs the macOS zip with Sparkle `sign_update` (EdDSA signature)
- Generates `DhikrAtWork.appinstaller` XML and updates `appcast.xml`
- Uploads macOS artifacts to the draft release
- Generates full release notes (SHA256 table, security notice, download links)
- Publishes the release as a **full release** (never pre-release)
- Commits updated `appcast.xml` to `main` and pushes

#### Step 3 — Post-release (manual)

After `release.sh` completes:

1. Drag the Windows zip to [VirusTotal](https://www.virustotal.com) and scan.
2. Drag the macOS zip to [VirusTotal](https://www.virustotal.com) and scan.
3. Edit the GitHub Release notes to add the VirusTotal scan links.

### Environment Variables

| Variable | Required on | Purpose |
|----------|-------------|---------|
| `MSIX_CERT_PASSWORD` | Windows | Password for `windows\signing\CERTIFICATE.pfx`. Set before running `release.ps1`. Never stored in `pubspec.yaml`. |
