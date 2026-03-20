// lib/views/settings/hotkey_record_dialog.dart

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A dialog that captures keyboard input and formats it as a hotkey string.
/// Returns the recorded hotkey string via [Navigator.pop], or null on cancel.
class HotkeyRecordDialog extends StatefulWidget {
  const HotkeyRecordDialog({super.key});

  @override
  State<HotkeyRecordDialog> createState() => _HotkeyRecordDialogState();
}

class _HotkeyRecordDialogState extends State<HotkeyRecordDialog> {
  String _recorded = 'Press a key combination...';
  String? _pendingHotkey;
  bool _hasModifier = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final parts = <String>[];
    if (HardwareKeyboard.instance.isControlPressed) parts.add('ctrl');
    if (HardwareKeyboard.instance.isAltPressed) parts.add('alt');
    if (HardwareKeyboard.instance.isShiftPressed) parts.add('shift');
    if (HardwareKeyboard.instance.isMetaPressed) parts.add('meta');

    final key = event.logicalKey;
    // Exclude lone modifier key presses.
    if (key != LogicalKeyboardKey.control &&
        key != LogicalKeyboardKey.alt &&
        key != LogicalKeyboardKey.shift &&
        key != LogicalKeyboardKey.meta &&
        key != LogicalKeyboardKey.controlLeft &&
        key != LogicalKeyboardKey.controlRight &&
        key != LogicalKeyboardKey.altLeft &&
        key != LogicalKeyboardKey.altRight &&
        key != LogicalKeyboardKey.shiftLeft &&
        key != LogicalKeyboardKey.shiftRight &&
        key != LogicalKeyboardKey.metaLeft &&
        key != LogicalKeyboardKey.metaRight) {
      final label = key.keyLabel.toLowerCase();
      parts.add(label);
      final hotkey = parts.join('+');
      final hasModifier = parts.length >= 2;
      setState(() {
        _recorded = hotkey;
        _pendingHotkey = hotkey;
        _hasModifier = hasModifier;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Hotkey'),
      content: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Press your desired key combination:'),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border:
                    Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
                color:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: SelectableText(
                _recorded,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ),
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
          ],
        ),
      ),
      actions: [
        Row(
          // Windows: confirm left; macOS/Linux: confirm right.
          textDirection: _isWindows ? TextDirection.rtl : TextDirection.ltr,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Tooltip(
                message: 'Discard and keep current hotkey',
                child: Text('Cancel'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _pendingHotkey == null
                  ? null
                  : () => Navigator.of(context).pop(_pendingHotkey),
              child: const Tooltip(
                message: 'Apply recorded hotkey',
                child: Text('Apply'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool get _isWindows {
    try {
      return Platform.isWindows;
    } catch (_) {
      return false;
    }
  }
}
