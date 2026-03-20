# Hotkey Recording Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Before implementing:** Read `docs/superpowers/specs/2026-03-20-hotkey-recording-fix-design.md` for the full design spec and key-label reference table.

**Goal:** Fix hotkey recording so any key (digits, punctuation, arrows, etc.) can be registered — with or without modifiers — using dual-scope (system vs inapp) registration.

**Architecture:** Three files change. `parseHotKey()` in the service layer gains expanded key mappings and auto-selects scope. `HotkeyRecordDialog` drops the modifier requirement and adds a scope hint. `SettingsViewModel` gets reason-aware error callbacks. TDD throughout — tests first, then implementation.

**Tech Stack:** Flutter, `hotkey_manager` ^0.2.3, `flutter_test`

---

## File Map

| File | Responsibility | Action |
|---|---|---|
| `lib/services/hotkey_service.dart` | Parse hotkey strings, register/unregister with OS | Modify: expand `_parseLogicalKey`, refactor `parseHotKey` for space handling + dual scope, change `onRegistrationFailed` signature |
| `lib/views/settings/hotkey_record_dialog.dart` | Capture keyboard input in a dialog | Modify: remove modifier gate, add `_hasModifier` state, replace error hint with scope hint |
| `lib/viewmodels/settings_viewmodel.dart` | Hotkey registration orchestration, error state | Modify: update `_onHotkeyRegistrationFailed` signature, remove `_hotkeyError` from `changeHotkey` else branch |
| `test/unit/services/hotkey_service_test.dart` | Unit tests for `parseHotKey` | Modify: add digit, punctuation, arrow, space, numpad, scope assertion tests |
| `test/widget/views/settings/hotkey_record_dialog_test.dart` | Widget tests for recorder dialog | Create new |
| `test/unit/viewmodels/settings_viewmodel_test.dart` | Unit tests for SettingsViewModel | Modify: add `changeHotkey` error-path tests |

---

## Phase 1: Expand `parseHotKey` (service layer)

These tasks are independent of dialog/VM changes and can be tested in isolation.

### Task 1: Add failing tests for new key types

**Files:**
- Modify: `test/unit/services/hotkey_service_test.dart`

- [ ] **Step 1: Add import for HotKeyScope**

Add at the top of the test file, below the existing imports:

```dart
import 'package:hotkey_manager/hotkey_manager.dart';
```

This is needed for `HotKeyScope.system` and `HotKeyScope.inapp` references in all new tests.

- [ ] **Step 2: Add digit key tests**

Add inside the existing `group('parseHotKey', ...)`:

```dart
    // -----------------------------------------------------------------
    // Digit keys
    // -----------------------------------------------------------------

    test('ctrl+1 returns digit1 with system scope', () {
      final hotKey = parseHotKey('ctrl+1');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.digit1));
      expect(hotKey.scope, equals(HotKeyScope.system));
    });

    test('0 (bare digit) returns digit0 with inapp scope', () {
      final hotKey = parseHotKey('0');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.digit0));
      expect(hotKey.scope, equals(HotKeyScope.inapp));
    });
```

- [ ] **Step 3: Add punctuation key tests**

```dart
    // -----------------------------------------------------------------
    // Punctuation keys
    // -----------------------------------------------------------------

    test('. (bare period) returns period with inapp scope', () {
      final hotKey = parseHotKey('.');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.period));
      expect(hotKey.scope, equals(HotKeyScope.inapp));
    });

    test('ctrl+. returns period with system scope', () {
      final hotKey = parseHotKey('ctrl+.');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.period));
      expect(hotKey.scope, equals(HotKeyScope.system));
    });

    test('ctrl+, returns comma with system scope', () {
      final hotKey = parseHotKey('ctrl+,');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.comma));
      expect(hotKey.scope, equals(HotKeyScope.system));
    });

    test('/ (bare slash) returns slash with inapp scope', () {
      final hotKey = parseHotKey('/');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.slash));
      expect(hotKey.scope, equals(HotKeyScope.inapp));
    });

    test('ctrl+- returns minus with system scope', () {
      final hotKey = parseHotKey('ctrl+-');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.minus));
      expect(hotKey.scope, equals(HotKeyScope.system));
    });

    test('ctrl+= returns equal with system scope', () {
      final hotKey = parseHotKey('ctrl+=');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.equal));
      expect(hotKey.scope, equals(HotKeyScope.system));
    });
```

- [ ] **Step 4: Add navigation and arrow key tests**

```dart
    // -----------------------------------------------------------------
    // Navigation and arrow keys
    // -----------------------------------------------------------------

    test('alt+arrow up returns arrowUp with system scope', () {
      final hotKey = parseHotKey('alt+arrow up');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.arrowUp));
      expect(hotKey.scope, equals(HotKeyScope.system));
    });

    test('enter (bare) returns enter with inapp scope', () {
      final hotKey = parseHotKey('enter');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.enter));
      expect(hotKey.scope, equals(HotKeyScope.inapp));
    });

    test('ctrl+backspace returns backspace with system scope', () {
      final hotKey = parseHotKey('ctrl+backspace');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.backspace));
      expect(hotKey.scope, equals(HotKeyScope.system));
    });
```

- [ ] **Step 5: Add space key test (special handling)**

```dart
    // -----------------------------------------------------------------
    // Space (special trim handling)
    // -----------------------------------------------------------------

    test('bare space returns space with inapp scope', () {
      final hotKey = parseHotKey(' ');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.space));
      expect(hotKey.scope, equals(HotKeyScope.inapp));
    });

    test('ctrl+space returns space with system scope', () {
      final hotKey = parseHotKey('ctrl+ ');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.space));
      expect(hotKey.scope, equals(HotKeyScope.system));
    });
```

- [ ] **Step 6: Add numpad key tests**

```dart
    // -----------------------------------------------------------------
    // Numpad keys
    // -----------------------------------------------------------------

    test('numpad 5 returns numpad5 with inapp scope', () {
      final hotKey = parseHotKey('numpad 5');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.numpad5));
      expect(hotKey.scope, equals(HotKeyScope.inapp));
    });

    test('ctrl+numpad add returns numpadAdd with system scope', () {
      final hotKey = parseHotKey('ctrl+numpad add');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.numpadAdd));
      expect(hotKey.scope, equals(HotKeyScope.system));
    });
```

- [ ] **Step 7: Add bare 'nonsense' returns null test**

```dart
    // -----------------------------------------------------------------
    // Bare unrecognised key returns null
    // -----------------------------------------------------------------

    test('nonsense returns null', () {
      expect(parseHotKey('nonsense'), isNull);
    });
```

- [ ] **Step 8: Add scope assertion to existing tests**

Update the existing `ctrl+shift+d` test to assert scope:

```dart
    test('ctrl+shift+d returns non-null with key == keyD', () {
      final hotKey = parseHotKey('ctrl+shift+d');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.keyD));
      expect(hotKey.scope, equals(HotKeyScope.system));
    });
```

Update the existing `f9` solo test to assert inapp scope:

```dart
    test('f9 returns non-null with key == f9 and empty modifiers', () {
      final hotKey = parseHotKey('f9');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.f9));
      expect(hotKey.modifiers, anyOf(isNull, isEmpty));
      expect(hotKey.scope, equals(HotKeyScope.inapp));
    });
```

- [ ] **Step 9: Run tests to verify they fail**

Run: `flutter test test/unit/services/hotkey_service_test.dart`

Expected: All new tests FAIL (digits, punctuation, arrows, space, numpad return null; scope assertions fail on existing tests since current code hardcodes `HotKeyScope.system`).

- [ ] **Step 10: Commit failing tests**

```bash
git add test/unit/services/hotkey_service_test.dart
git commit -m "test: add failing tests for expanded parseHotKey key coverage and dual scope"
```

---

### Task 2: Implement expanded `parseHotKey` and `_parseLogicalKey`

**Files:**
- Modify: `lib/services/hotkey_service.dart:8-83`

- [ ] **Step 1: Refactor `parseHotKey` for space handling and dual scope**

Replace the entire `parseHotKey` function (lines 8-29) with:

```dart
/// Parses a hotkey string like 'ctrl+shift+d' into a [HotKey].
/// Returns null if the string is malformed or the key is unrecognised.
///
/// Scope is determined automatically:
/// - Has modifiers → [HotKeyScope.system] (works in background)
/// - No modifiers → [HotKeyScope.inapp] (works when app has focus)
HotKey? parseHotKey(String hotkeyString) {
  if (hotkeyString.isEmpty) return null;

  // Space requires special handling: split('+') then trim() would destroy it.
  final String keyLabel;
  final List<String> modifierStrings;

  if (hotkeyString == ' ' || hotkeyString.endsWith('+ ')) {
    // Space is the key part.
    keyLabel = ' ';
    final lastPlus = hotkeyString.lastIndexOf('+');
    modifierStrings = lastPlus > 0
        ? hotkeyString
            .substring(0, lastPlus)
            .toLowerCase()
            .split('+')
            .map((s) => s.trim())
            .toList()
        : [];
  } else {
    final parts = hotkeyString
        .toLowerCase()
        .split('+')
        .map((s) => s.trim())
        .toList();
    if (parts.isEmpty) return null;
    keyLabel = parts.last;
    modifierStrings = parts.sublist(0, parts.length - 1);
  }

  final LogicalKeyboardKey? logicalKey = _parseLogicalKey(keyLabel);
  if (logicalKey == null) return null;

  final modifiers = modifierStrings
      .map(_parseModifier)
      .whereType<HotKeyModifier>()
      .toList();

  return HotKey(
    key: logicalKey,
    modifiers: modifiers,
    scope: modifiers.isEmpty ? HotKeyScope.inapp : HotKeyScope.system,
  );
}
```

- [ ] **Step 2: Expand `_parseLogicalKey` switch**

Replace the entire `_parseLogicalKey` function (lines 31-73) with:

```dart
LogicalKeyboardKey? _parseLogicalKey(String label) {
  return switch (label) {
    // Letters
    'a' => LogicalKeyboardKey.keyA,
    'b' => LogicalKeyboardKey.keyB,
    'c' => LogicalKeyboardKey.keyC,
    'd' => LogicalKeyboardKey.keyD,
    'e' => LogicalKeyboardKey.keyE,
    'f' => LogicalKeyboardKey.keyF,
    'g' => LogicalKeyboardKey.keyG,
    'h' => LogicalKeyboardKey.keyH,
    'i' => LogicalKeyboardKey.keyI,
    'j' => LogicalKeyboardKey.keyJ,
    'k' => LogicalKeyboardKey.keyK,
    'l' => LogicalKeyboardKey.keyL,
    'm' => LogicalKeyboardKey.keyM,
    'n' => LogicalKeyboardKey.keyN,
    'o' => LogicalKeyboardKey.keyO,
    'p' => LogicalKeyboardKey.keyP,
    'q' => LogicalKeyboardKey.keyQ,
    'r' => LogicalKeyboardKey.keyR,
    's' => LogicalKeyboardKey.keyS,
    't' => LogicalKeyboardKey.keyT,
    'u' => LogicalKeyboardKey.keyU,
    'v' => LogicalKeyboardKey.keyV,
    'w' => LogicalKeyboardKey.keyW,
    'x' => LogicalKeyboardKey.keyX,
    'y' => LogicalKeyboardKey.keyY,
    'z' => LogicalKeyboardKey.keyZ,
    // Digits
    '0' => LogicalKeyboardKey.digit0,
    '1' => LogicalKeyboardKey.digit1,
    '2' => LogicalKeyboardKey.digit2,
    '3' => LogicalKeyboardKey.digit3,
    '4' => LogicalKeyboardKey.digit4,
    '5' => LogicalKeyboardKey.digit5,
    '6' => LogicalKeyboardKey.digit6,
    '7' => LogicalKeyboardKey.digit7,
    '8' => LogicalKeyboardKey.digit8,
    '9' => LogicalKeyboardKey.digit9,
    // F-keys
    'f1' => LogicalKeyboardKey.f1,
    'f2' => LogicalKeyboardKey.f2,
    'f3' => LogicalKeyboardKey.f3,
    'f4' => LogicalKeyboardKey.f4,
    'f5' => LogicalKeyboardKey.f5,
    'f6' => LogicalKeyboardKey.f6,
    'f7' => LogicalKeyboardKey.f7,
    'f8' => LogicalKeyboardKey.f8,
    'f9' => LogicalKeyboardKey.f9,
    'f10' => LogicalKeyboardKey.f10,
    'f11' => LogicalKeyboardKey.f11,
    'f12' => LogicalKeyboardKey.f12,
    // Punctuation / symbols
    '.' => LogicalKeyboardKey.period,
    ',' => LogicalKeyboardKey.comma,
    '/' => LogicalKeyboardKey.slash,
    ';' => LogicalKeyboardKey.semicolon,
    "'" => LogicalKeyboardKey.quoteSingle,
    '[' => LogicalKeyboardKey.bracketLeft,
    ']' => LogicalKeyboardKey.bracketRight,
    r'\' => LogicalKeyboardKey.backslash,
    '-' => LogicalKeyboardKey.minus,
    '=' => LogicalKeyboardKey.equal,
    '`' => LogicalKeyboardKey.backquote,
    ' ' => LogicalKeyboardKey.space,
    // Navigation
    'enter' => LogicalKeyboardKey.enter,
    'backspace' => LogicalKeyboardKey.backspace,
    'tab' => LogicalKeyboardKey.tab,
    'escape' => LogicalKeyboardKey.escape,
    'delete' => LogicalKeyboardKey.delete,
    // Arrows
    'arrow up' => LogicalKeyboardKey.arrowUp,
    'arrow down' => LogicalKeyboardKey.arrowDown,
    'arrow left' => LogicalKeyboardKey.arrowLeft,
    'arrow right' => LogicalKeyboardKey.arrowRight,
    // Page navigation
    'home' => LogicalKeyboardKey.home,
    'end' => LogicalKeyboardKey.end,
    'page up' => LogicalKeyboardKey.pageUp,
    'page down' => LogicalKeyboardKey.pageDown,
    // Numpad
    'numpad 0' => LogicalKeyboardKey.numpad0,
    'numpad 1' => LogicalKeyboardKey.numpad1,
    'numpad 2' => LogicalKeyboardKey.numpad2,
    'numpad 3' => LogicalKeyboardKey.numpad3,
    'numpad 4' => LogicalKeyboardKey.numpad4,
    'numpad 5' => LogicalKeyboardKey.numpad5,
    'numpad 6' => LogicalKeyboardKey.numpad6,
    'numpad 7' => LogicalKeyboardKey.numpad7,
    'numpad 8' => LogicalKeyboardKey.numpad8,
    'numpad 9' => LogicalKeyboardKey.numpad9,
    'numpad add' => LogicalKeyboardKey.numpadAdd,
    'numpad subtract' => LogicalKeyboardKey.numpadSubtract,
    'numpad multiply' => LogicalKeyboardKey.numpadMultiply,
    'numpad decimal' => LogicalKeyboardKey.numpadDecimal,
    'numpad divide' => LogicalKeyboardKey.numpadDivide,
    _ => null,
  };
}
```

- [ ] **Step 3: Run tests to verify they pass**

Run: `flutter test test/unit/services/hotkey_service_test.dart`

Expected: ALL tests PASS — new key types resolve correctly, scope assertions match.

- [ ] **Step 4: Commit**

```bash
git add lib/services/hotkey_service.dart
git commit -m "feat: expand parseHotKey to support digits, punctuation, arrows, numpad with dual scope"
```

---

## Phase 2: Update error callback signature (service + viewmodel)

Depends on: Phase 1 complete (parseHotKey changes landed).

### Task 3: Update `HotkeyService.register` callback signature

**Files:**
- Modify: `lib/services/hotkey_service.dart:104-131`

- [ ] **Step 1: Change `onRegistrationFailed` parameter type**

In `HotkeyService.register()`, change the parameter from `VoidCallback?` to `void Function(String reason)?`:

Replace lines 104-107:
```dart
  Future<bool> register({
    required String hotkeyString,
    required VoidCallback onTriggered,
    VoidCallback? onRegistrationFailed,
  }) async {
```

With:
```dart
  Future<bool> register({
    required String hotkeyString,
    required VoidCallback onTriggered,
    void Function(String reason)? onRegistrationFailed,
  }) async {
```

- [ ] **Step 2: Pass reason strings to the callback**

Replace line 113 (`onRegistrationFailed?.call();` after `parseHotKey` returns null):
```dart
      onRegistrationFailed?.call('unsupported_key');
```

Replace line 128 (`onRegistrationFailed?.call();` in the catch block):
```dart
      onRegistrationFailed?.call('registration_failed');
```

- [ ] **Step 3: Update doc comment**

Replace lines 97-103:
```dart
  /// Registers [hotkeyString] (e.g., 'ctrl+shift+d') as a system-wide hotkey.
  ///
  /// [onTriggered] is called each time the hotkey fires.
  /// [onRegistrationFailed] is called with a reason string if registration
  /// fails: `'unsupported_key'` if the key cannot be parsed, or
  /// `'registration_failed'` if the OS rejected the hotkey.
  ///
  /// Returns true if registration succeeded.
```

- [ ] **Step 4: Verify existing tests still pass**

Run: `flutter test test/unit/services/hotkey_service_test.dart`

Expected: PASS (existing tests only test `parseHotKey`, not `register`).

- [ ] **Step 5: Commit**

```bash
git add lib/services/hotkey_service.dart
git commit -m "refactor: change onRegistrationFailed callback to accept reason string"
```

---

### Task 4: Update `SettingsViewModel` to use reason-aware callback

**Files:**
- Modify: `lib/viewmodels/settings_viewmodel.dart:255-285`

- [ ] **Step 1: Update `_onHotkeyRegistrationFailed` signature and body**

Replace lines 280-285:
```dart
  void _onHotkeyRegistrationFailed() {
    _hotkeyError =
        'Failed to register global hotkey. Another application may own this shortcut.';
    _hotkeyRegistered = false;
    notifyListeners();
  }
```

With:
```dart
  void _onHotkeyRegistrationFailed(String reason) {
    _hotkeyError = reason == 'unsupported_key'
        ? 'This key is not supported for hotkey registration.'
        : 'Could not register hotkey — it may be in use by another app.';
    _hotkeyRegistered = false;
    notifyListeners();
  }
```

- [ ] **Step 2: Remove hardcoded error from `changeHotkey` else branch**

Replace lines 255-274:
```dart
  Future<void> changeHotkey(String newHotkeyString) async {
    final success = await HotkeyService.instance.register(
      hotkeyString: newHotkeyString,
      onTriggered: _onHotkeyTriggered,
      onRegistrationFailed: _onHotkeyRegistrationFailed,
    );

    if (success) {
      _settings = _settings.copyWith(globalHotkey: newHotkeyString);
      _hotkeyError = null;
      _hotkeyRegistered = true;
      await _settingsRepository.updateSettings(_settings);
    } else {
      _hotkeyRegistered = false;
    }

    notifyListeners();
  }
```

- [ ] **Step 3: Run existing VM tests to verify no regressions**

Run: `flutter test test/unit/viewmodels/settings_viewmodel_test.dart`

Expected: PASS (existing tests don't call `changeHotkey`).

- [ ] **Step 4: Commit**

```bash
git add lib/viewmodels/settings_viewmodel.dart
git commit -m "fix: use reason-aware error callback, remove hardcoded error from changeHotkey"
```

---

### Task 5: Add `changeHotkey` error-path tests to SettingsViewModel

**Files:**
- Modify: `test/unit/viewmodels/settings_viewmodel_test.dart`

- [ ] **Step 1: Add changeHotkey test group**

Add at the end of `main()`, before the closing `}`:

```dart
  group('changeHotkey', () {
    test('unsupported key sets hotkeyError to not-supported message', () async {
      await vm.loadSettings();
      await vm.changeHotkey('nonsense');
      expect(vm.hotkeyRegistered, isFalse);
      expect(vm.hotkeyError, contains('not supported'));
    });

    // Note: Testing the success path (valid key → hotkeyError is null,
    // hotkeyRegistered is true) requires a real OS window for
    // hotKeyManager.register(). This needs HotkeyService to accept
    // injection — tracked as future improvement. The unsupported_key
    // path above is the only one reliably testable in unit tests.
  });
```

- [ ] **Step 2: Run test to verify**

Run: `flutter test test/unit/viewmodels/settings_viewmodel_test.dart`

Expected: PASS — the `'nonsense'` key triggers `parseHotKey` returning null → `onRegistrationFailed('unsupported_key')` → error message set.

- [ ] **Step 3: Commit**

```bash
git add test/unit/viewmodels/settings_viewmodel_test.dart
git commit -m "test: add changeHotkey error-path tests for unsupported key"
```

---

## Phase 3: Update `HotkeyRecordDialog` (UI layer)

Depends on: Phase 1 complete (parseHotKey can handle all keys). Independent of Phase 2.

### Task 6: Add failing widget tests for the dialog

**Files:**
- Create: `test/widget/views/settings/hotkey_record_dialog_test.dart`

- [ ] **Step 1: Write the test file**

```dart
// test/widget/views/settings/hotkey_record_dialog_test.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dhikratwork/views/settings/hotkey_record_dialog.dart';

Widget _buildTestApp() {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog<String>(
            context: context,
            builder: (_) => const HotkeyRecordDialog(),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.pumpWidget(_buildTestApp());
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  group('HotkeyRecordDialog', () {
    testWidgets('bare key press enables Apply and shows inapp hint',
        (tester) async {
      await _openDialog(tester);

      // Send a bare period key press (no modifiers).
      await tester.sendKeyEvent(LogicalKeyboardKey.period);
      await tester.pump();

      // Apply button should be enabled.
      final applyButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Apply'),
      );
      expect(applyButton.onPressed, isNotNull);

      // Scope hint for single key.
      expect(find.textContaining('works when app is focused'), findsOneWidget);
    });

    testWidgets('modifier+key press enables Apply and shows system hint',
        (tester) async {
      await _openDialog(tester);

      // Send Ctrl+K.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      // Apply button should be enabled.
      final applyButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Apply'),
      );
      expect(applyButton.onPressed, isNotNull);

      // Scope hint for system-wide.
      expect(find.textContaining('works in background'), findsOneWidget);
    });

    testWidgets('lone modifier press does not enable Apply', (tester) async {
      await _openDialog(tester);

      // Send just Ctrl (modifier only).
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      // Apply should still be disabled.
      final applyButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Apply'),
      );
      expect(applyButton.onPressed, isNull);

      // No scope hint shown.
      expect(find.textContaining('works when app is focused'), findsNothing);
      expect(find.textContaining('works in background'), findsNothing);
    });

    testWidgets('cancel returns null', (tester) async {
      await _openDialog(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed — no Apply/Cancel buttons visible.
      expect(find.text('Apply'), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/widget/views/settings/hotkey_record_dialog_test.dart`

Expected: FAIL — bare key press test fails because `_pendingHotkey` is null (modifier required), scope hints don't exist yet.

- [ ] **Step 3: Commit failing tests**

```bash
git add test/widget/views/settings/hotkey_record_dialog_test.dart
git commit -m "test: add failing widget tests for HotkeyRecordDialog single-key and scope hints"
```

---

### Task 7: Implement dialog changes

**Files:**
- Modify: `lib/views/settings/hotkey_record_dialog.dart`

- [ ] **Step 1: Replace `_needsModifier` with `_hasModifier`**

In `_HotkeyRecordDialogState`, replace line 20:
```dart
  bool _needsModifier = false;
```
With:
```dart
  bool _hasModifier = false;
```

- [ ] **Step 2: Update `_handleKeyEvent` to always set `_pendingHotkey`**

Replace lines 62-67 (the `setState` block inside the non-modifier key branch):
```dart
      setState(() {
        _recorded = hotkey;
        _pendingHotkey = hasModifier ? hotkey : null;
        _needsModifier = !hasModifier;
      });
```
With:
```dart
      setState(() {
        _recorded = hotkey;
        _pendingHotkey = hotkey;
        _hasModifier = hasModifier;
      });
```

- [ ] **Step 3: Replace modifier error hint with scope hint**

Replace lines 100-109:
```dart
            if (_needsModifier)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Add a modifier key (Ctrl, Alt, Shift, etc.)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
```
With:
```dart
            if (_pendingHotkey != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _hasModifier
                      ? 'System-wide — works in background'
                      : 'Single key — works when app is focused',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
```

- [ ] **Step 4: Run widget tests to verify they pass**

Run: `flutter test test/widget/views/settings/hotkey_record_dialog_test.dart`

Expected: ALL tests PASS.

- [ ] **Step 5: Run full test suite to check for regressions**

Run: `flutter test`

Expected: ALL tests PASS (no other widget/unit tests reference `_needsModifier` or the old hint text).

- [ ] **Step 6: Commit**

```bash
git add lib/views/settings/hotkey_record_dialog.dart
git commit -m "feat: remove modifier requirement, add scope hint to HotkeyRecordDialog"
```

---

## Phase 4: Final validation

Depends on: Phases 1, 2, and 3 all complete.

### Task 8: Full test suite and analysis

**Files:** None (validation only)

- [ ] **Step 1: Run full test suite**

Run: `flutter test`

Expected: ALL tests PASS.

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze`

Expected: No issues.

- [ ] **Step 3: Verify the complete flow manually (if running app)**

If the app can be launched (`.\run.ps1`):
1. Open Settings tab → click "Record New"
2. Press just `.` → Apply enabled, scope hint shows "works when app is focused"
3. Click Apply → hotkey saves without error
4. Press `Ctrl+.` → Apply enabled, scope hint shows "works in background"
5. Click Apply → hotkey saves without error
6. Check compact bar shows the new hotkey string

---

## Parallel Execution Guide

```
Phase 1 (Tasks 1-2) ──────► Phase 2 (Tasks 3-5)
                      └────► Phase 3 (Tasks 6-7)  ──► Phase 4 (Task 8)
```

- **Phase 1** must complete first (parseHotKey changes are needed by both Phase 2 and Phase 3)
- **Phase 2** (callback signature) and **Phase 3** (dialog UI) can run **in parallel** after Phase 1
- **Phase 4** runs after both Phase 2 and Phase 3 are complete
