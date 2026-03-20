// lib/services/hotkey_service.dart

import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

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

HotKeyModifier? _parseModifier(String modifier) {
  return switch (modifier) {
    'ctrl' || 'control' => HotKeyModifier.control,
    'shift' => HotKeyModifier.shift,
    'alt' => HotKeyModifier.alt,
    'meta' || 'win' || 'cmd' => HotKeyModifier.meta,
    _ => null,
  };
}

/// Manages registration and unregistration of the global hotkey.
class HotkeyService {
  HotkeyService._();

  static final HotkeyService instance = HotkeyService._();

  HotKey? _currentHotKey;
  bool _isRegistered = false;

  bool get isRegistered => _isRegistered;
  HotKey? get currentHotKey => _currentHotKey;

  /// Registers [hotkeyString] (e.g., 'ctrl+shift+d') as a system-wide hotkey.
  ///
  /// [onTriggered] is called each time the hotkey fires.
  /// [onRegistrationFailed] is called with a reason string if registration
  /// fails: `'unsupported_key'` if the key cannot be parsed, or
  /// `'registration_failed'` if the OS rejected the hotkey.
  ///
  /// Returns true if registration succeeded.
  Future<bool> register({
    required String hotkeyString,
    required VoidCallback onTriggered,
    void Function(String reason)? onRegistrationFailed,
  }) async {
    await unregister();

    final hotKey = parseHotKey(hotkeyString);
    if (hotKey == null) {
      onRegistrationFailed?.call('unsupported_key');
      return false;
    }

    try {
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: (_) => onTriggered(),
      );
      _currentHotKey = hotKey;
      _isRegistered = true;
      return true;
    } catch (e) {
      _isRegistered = false;
      _currentHotKey = null;
      onRegistrationFailed?.call('registration_failed');
      return false;
    }
  }

  /// Unregisters the currently active hotkey.
  Future<void> unregister() async {
    if (_currentHotKey != null) {
      try {
        await hotKeyManager.unregister(_currentHotKey!);
      } catch (_) {
        // Ignore — key may already be unregistered.
      }
    }
    _currentHotKey = null;
    _isRegistered = false;
  }

  /// Unregisters all hotkeys registered by this app.
  Future<void> unregisterAll() async {
    await hotKeyManager.unregisterAll();
    _currentHotKey = null;
    _isRegistered = false;
  }
}
