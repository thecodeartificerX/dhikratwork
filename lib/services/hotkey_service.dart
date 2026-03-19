// lib/services/hotkey_service.dart

import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

/// Parses a hotkey string like 'ctrl+shift+d' into a [HotKey].
/// Returns null if the string is malformed or the key is unrecognised.
HotKey? parseHotKey(String hotkeyString) {
  final parts =
      hotkeyString.toLowerCase().split('+').map((s) => s.trim()).toList();
  if (parts.isEmpty) return null;

  final keyLabel = parts.last;
  final modifierStrings = parts.sublist(0, parts.length - 1);

  final LogicalKeyboardKey? logicalKey = _parseLogicalKey(keyLabel);
  if (logicalKey == null) return null;

  final modifiers = modifierStrings
      .map(_parseModifier)
      .whereType<HotKeyModifier>()
      .toList();

  return HotKey(
    key: logicalKey,
    modifiers: modifiers,
    scope: HotKeyScope.system,
  );
}

LogicalKeyboardKey? _parseLogicalKey(String label) {
  return switch (label) {
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
  /// [onRegistrationFailed] is called if the hotkey is already owned by
  /// another application.
  ///
  /// Returns true if registration succeeded.
  Future<bool> register({
    required String hotkeyString,
    required VoidCallback onTriggered,
    VoidCallback? onRegistrationFailed,
  }) async {
    await unregister();

    final hotKey = parseHotKey(hotkeyString);
    if (hotKey == null) {
      onRegistrationFailed?.call();
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
      onRegistrationFailed?.call();
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
