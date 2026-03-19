# Hotkey Recording Fix — Design Spec

## Problem

Two bugs prevent users from recording custom hotkeys:

1. **`parseHotKey()` only supports a-z and F1-F12.** Any other key (digits, punctuation like `.`, arrows, space, etc.) causes `parseHotKey` to return `null`. This triggers the misleading error *"Could not register — it may be in use by another app"* when the real problem is an unsupported key.

2. **`HotkeyRecordDialog` requires a modifier key.** The Apply button stays disabled unless at least one modifier (Ctrl/Alt/Shift/Meta) is held. Users cannot register single-key hotkeys like `.` or `F9`.

## Solution: Expand Key Support + Dual-Scope Hotkeys

### 1. Expand `parseHotKey()` key coverage

**File**: `lib/services/hotkey_service.dart`

The `_parseLogicalKey` switch statement expands to cover all common keys. The mapping must match what `event.logicalKey.keyLabel.toLowerCase()` produces in the recorder dialog.

#### Key label reference (after `.toLowerCase()`)

Flutter's `LogicalKeyboardKey.keyLabel` uses two paths:
- **Printable ASCII keys** (keyId in unicode plane): returns the literal character via `String.fromCharCode(keyId).toUpperCase()`. E.g., period → `'.'`, digit1 → `'1'`, space → `' '`.
- **Non-printable / special keys** (keyId has platform prefix): falls through to the `_keyLabels` map. E.g., enter → `'Enter'`, arrowUp → `'Arrow Up'`, numpad0 → `'Numpad 0'`.

After `.toLowerCase()` in the dialog, the switch cases in `_parseLogicalKey` must match these exact strings. **Important**: digit keys are `'0'`-`'9'` (literal characters), NOT `'digit 0'`-`'digit 9'`.

| Category | keyLabel (lowercased) | LogicalKeyboardKey |
|---|---|---|
| Letters | `'a'`-`'z'` | `keyA`-`keyZ` |
| Digits | `'0'`-`'9'` | `digit0`-`digit9` |
| F-keys | `'f1'`-`'f12'` | `f1`-`f12` |
| Period | `'.'` | `period` |
| Comma | `','` | `comma` |
| Slash | `'/'` | `slash` |
| Semicolon | `';'` | `semicolon` |
| Quote (single) | `"'"` | `quoteSingle` |
| Bracket left | `'['` | `bracketLeft` |
| Bracket right | `']'` | `bracketRight` |
| Backslash | `'\'` | `backslash` |
| Minus | `'-'` | `minus` |
| Equal | `'='` | `equal` |
| Backquote | `` '`' `` | `backquote` |
| Space | `' '` (literal space) | `space` |
| Enter | `'enter'` | `enter` |
| Backspace | `'backspace'` | `backspace` |
| Tab | `'tab'` | `tab` |
| Escape | `'escape'` | `escape` |
| Delete | `'delete'` | `delete` |
| Arrow Up | `'arrow up'` | `arrowUp` |
| Arrow Down | `'arrow down'` | `arrowDown` |
| Arrow Left | `'arrow left'` | `arrowLeft` |
| Arrow Right | `'arrow right'` | `arrowRight` |
| Home | `'home'` | `home` |
| End | `'end'` | `end` |
| Page Up | `'page up'` | `pageUp` |
| Page Down | `'page down'` | `pageDown` |
| Numpad 0-9 | `'numpad 0'`-`'numpad 9'` | `numpad0`-`numpad9` |
| Numpad Add | `'numpad add'` | `numpadAdd` |
| Numpad Subtract | `'numpad subtract'` | `numpadSubtract` |
| Numpad Multiply | `'numpad multiply'` | `numpadMultiply` |
| Numpad Decimal | `'numpad decimal'` | `numpadDecimal` |
| Numpad Divide | `'numpad divide'` | `numpadDivide` |

### 2. Dual-scope hotkey logic

**File**: `lib/services/hotkey_service.dart`

`parseHotKey()` determines scope automatically based on whether modifiers are present:

- **Has modifiers** (e.g., `'ctrl+.'`) → `HotKeyScope.system` — works in background
- **No modifiers** (e.g., `'.'`) → `HotKeyScope.inapp` — works when app has focus

The scope detection happens inside `parseHotKey` by checking if the `modifiers` list is empty:

```dart
return HotKey(
  key: logicalKey,
  modifiers: modifiers,
  scope: modifiers.isEmpty ? HotKeyScope.inapp : HotKeyScope.system,
);
```

**Space handling**: Space (`' '`) requires special treatment because `parseHotKey` splits by `'+'` then trims each part. A bare space input `' '` would trim to `''` and fail lookup. Fix: before splitting, check if the trimmed input equals `' '` (bare space) or ends with `+ ` (modifier+space). Handle space as a special case before the `split('+')`/`trim()` logic:

```dart
// Before split: detect space as the key part
String keyPart;
List<String> modifierParts;
if (hotkeyString.endsWith('+ ') || hotkeyString.trim() == '') {
  // Space is the key — everything before the last '+' is modifiers
  final lastPlus = hotkeyString.lastIndexOf('+');
  keyPart = ' ';
  modifierParts = lastPlus > 0
      ? hotkeyString.substring(0, lastPlus).split('+').map((s) => s.trim()).toList()
      : [];
} else {
  final parts = hotkeyString.toLowerCase().split('+').map((s) => s.trim()).toList();
  keyPart = parts.last;
  modifierParts = parts.sublist(0, parts.length - 1);
}
```

No changes needed to `HotkeyService.register()`, `SettingsViewModel.changeHotkey()`, or `SettingsViewModel.applyHotkeyFromString()` — the scope is embedded in the `HotKey` object.

### 3. `HotkeyRecordDialog` changes

**File**: `lib/views/settings/hotkey_record_dialog.dart`

- Remove the modifier requirement: any valid key press (with or without modifiers) sets `_pendingHotkey` and enables Apply
- Replace `_needsModifier` flag with `_hasModifier` bool (true when `parts.length >= 2` at recording time). Store this in `setState` alongside `_pendingHotkey`.
- Add a scope hint below the recorded key display, driven by `_hasModifier`:
  - `_hasModifier == false`: *"Single key — works when app is focused"* (info style, not error)
  - `_hasModifier == true`: *"System-wide — works in background"* (info style)
- Keep filtering out lone modifier key presses (pressing just Ctrl still does nothing)
- `_pendingHotkey` is always set to the hotkey string when a non-modifier key is pressed (regardless of whether modifiers are held). `_recorded` remains the display string. Both fields stay separate.

### 4. Error message fix

**File**: `lib/viewmodels/settings_viewmodel.dart` + `lib/services/hotkey_service.dart`

Split the error into two distinct messages:

- `parseHotKey` returns null → `HotkeyService.register()` calls `onRegistrationFailed` with a distinguishable signal
- `hotKeyManager.register` throws → different error

**Approach**: Change `onRegistrationFailed` callback signature from `VoidCallback?` to `void Function(String reason)?`:

In `HotkeyService.register()`:
- `parseHotKey` returns null → `onRegistrationFailed?.call('unsupported_key')`
- `hotKeyManager.register` throws → `onRegistrationFailed?.call('registration_failed')`

In `SettingsViewModel`:
- `_onHotkeyRegistrationFailed(String reason)` becomes the **sole owner** of `_hotkeyError`:
  - `'unsupported_key'` → `_hotkeyError = 'This key is not supported for hotkey registration.'`
  - `'registration_failed'` → `_hotkeyError = 'Could not register hotkey — it may be in use by another app.'`
  - Calls `notifyListeners()` after setting the error.

- **`changeHotkey`'s `else` branch must NOT set `_hotkeyError`** — the callback already handled it. The `else` branch only sets `_hotkeyRegistered = false` (the error string is already set by the callback).

- **`applyHotkeyFromString`** also passes the updated callback signature: `onRegistrationFailed: _onHotkeyRegistrationFailed` — the method reference automatically matches since `_onHotkeyRegistrationFailed` now accepts `String reason`.

## Files Changed

| File | Change |
|---|---|
| `lib/services/hotkey_service.dart` | Expand `_parseLogicalKey` switch, add scope logic to `parseHotKey`, update `onRegistrationFailed` callback signature |
| `lib/views/settings/hotkey_record_dialog.dart` | Remove modifier requirement, add scope hint text |
| `lib/viewmodels/settings_viewmodel.dart` | Update `_onHotkeyRegistrationFailed` to accept reason, update error messages in `changeHotkey` |

## Testing

### Unit tests — `test/unit/services/hotkey_service_test.dart`

**New cases for `parseHotKey`:**
- Digits: `parseHotKey('ctrl+1')` → HotKey with `digit1`, scope `system`
- Punctuation: `parseHotKey('.')` → HotKey with `period`, scope `inapp`
- Punctuation with modifier: `parseHotKey('ctrl+.')` → HotKey with `period`, scope `system`
- Arrows: `parseHotKey('alt+arrow up')` → HotKey with `arrowUp`, scope `system`
- Space: `parseHotKey(' ')` → HotKey with `space`, scope `inapp`
- Numpad: `parseHotKey('numpad 5')` → HotKey with `numpad5`, scope `inapp`
- Bare F-key: `parseHotKey('f9')` → HotKey with `f9`, scope `inapp`
- Existing: `parseHotKey('ctrl+shift+d')` → unchanged behavior, scope `system`
- Invalid: `parseHotKey('nonsense')` → still returns `null`

### Widget tests — `test/widget/views/settings/hotkey_record_dialog_test.dart`

- Bare key press (`.`) → Apply enabled, scope hint shows "works when app is focused"
- Modifier+key press (`ctrl+k`) → Apply enabled, scope hint shows "works in background"
- Lone modifier press (just Ctrl) → Apply stays disabled, no hint
- Returned string format matches `parseHotKey` expectations

### Unit tests — `test/unit/viewmodels/settings_viewmodel_test.dart`

**New cases for `changeHotkey` error paths:**
- Unsupported key string (e.g., `'nonsense'`) → `hotkeyError` is *"This key is not supported..."*
- Valid key string → `hotkeyError` is null, `hotkeyRegistered` is true

Note: `HotkeyService` is a singleton, making it hard to fake in unit tests. If `changeHotkey` tests need to simulate `hotKeyManager.register` throwing, the test must either use the real `HotkeyService` with a parseable key (testing the happy path) or rely on an unparseable key to test the `null` path. Full registration-failure simulation requires refactoring `HotkeyService` to accept injection — out of scope for this fix but noted as future improvement.

### Existing tests

- `settings_tab_test.dart` — no changes expected
- Integration tests — no changes needed
