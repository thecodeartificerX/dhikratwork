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
