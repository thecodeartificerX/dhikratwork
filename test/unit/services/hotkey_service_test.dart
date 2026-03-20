// test/unit/services/hotkey_service_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:dhikratwork/services/hotkey_service.dart';

void main() {
  group('parseHotKey', () {
    // -----------------------------------------------------------------------
    // Letter key with modifiers
    // -----------------------------------------------------------------------

    test('ctrl+shift+d returns non-null with key == keyD', () {
      final hotKey = parseHotKey('ctrl+shift+d');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.keyD));
      expect(hotKey.scope, equals(HotKeyScope.system));
    });

    // -----------------------------------------------------------------------
    // F-key — solo (no modifiers)
    // -----------------------------------------------------------------------

    test('f9 returns non-null with key == f9 and empty modifiers', () {
      final hotKey = parseHotKey('f9');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.f9));
      expect(hotKey.modifiers, anyOf(isNull, isEmpty));
      expect(hotKey.scope, equals(HotKeyScope.inapp));
    });

    // -----------------------------------------------------------------------
    // F1-F12 all resolve
    // -----------------------------------------------------------------------

    test('f1 returns non-null', () {
      expect(parseHotKey('f1'), isNotNull);
      expect(parseHotKey('f1')!.key, equals(LogicalKeyboardKey.f1));
    });

    test('f2 returns non-null', () {
      expect(parseHotKey('f2'), isNotNull);
      expect(parseHotKey('f2')!.key, equals(LogicalKeyboardKey.f2));
    });

    test('f3 returns non-null', () {
      expect(parseHotKey('f3'), isNotNull);
      expect(parseHotKey('f3')!.key, equals(LogicalKeyboardKey.f3));
    });

    test('f4 returns non-null', () {
      expect(parseHotKey('f4'), isNotNull);
      expect(parseHotKey('f4')!.key, equals(LogicalKeyboardKey.f4));
    });

    test('f5 returns non-null', () {
      expect(parseHotKey('f5'), isNotNull);
      expect(parseHotKey('f5')!.key, equals(LogicalKeyboardKey.f5));
    });

    test('f6 returns non-null', () {
      expect(parseHotKey('f6'), isNotNull);
      expect(parseHotKey('f6')!.key, equals(LogicalKeyboardKey.f6));
    });

    test('f7 returns non-null', () {
      expect(parseHotKey('f7'), isNotNull);
      expect(parseHotKey('f7')!.key, equals(LogicalKeyboardKey.f7));
    });

    test('f8 returns non-null', () {
      expect(parseHotKey('f8'), isNotNull);
      expect(parseHotKey('f8')!.key, equals(LogicalKeyboardKey.f8));
    });

    test('f9 returns non-null', () {
      expect(parseHotKey('f9'), isNotNull);
      expect(parseHotKey('f9')!.key, equals(LogicalKeyboardKey.f9));
    });

    test('f10 returns non-null', () {
      expect(parseHotKey('f10'), isNotNull);
      expect(parseHotKey('f10')!.key, equals(LogicalKeyboardKey.f10));
    });

    test('f11 returns non-null', () {
      expect(parseHotKey('f11'), isNotNull);
      expect(parseHotKey('f11')!.key, equals(LogicalKeyboardKey.f11));
    });

    test('f12 returns non-null', () {
      expect(parseHotKey('f12'), isNotNull);
      expect(parseHotKey('f12')!.key, equals(LogicalKeyboardKey.f12));
    });

    // -----------------------------------------------------------------------
    // F-key with modifier
    // -----------------------------------------------------------------------

    test('ctrl+f10 returns non-null with key == f10 and control modifier', () {
      final hotKey = parseHotKey('ctrl+f10');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.f10));
      expect(hotKey.modifiers, isNotNull);
      expect(hotKey.modifiers, isNotEmpty);
    });

    // -----------------------------------------------------------------------
    // Invalid inputs return null
    // -----------------------------------------------------------------------

    test('empty string returns null', () {
      expect(parseHotKey(''), isNull);
    });

    test('ctrl+mousebutton3 returns null (unrecognised key)', () {
      expect(parseHotKey('ctrl+mousebutton3'), isNull);
    });

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

    // -----------------------------------------------------------------
    // Bare unrecognised key returns null
    // -----------------------------------------------------------------

    test('nonsense returns null', () {
      expect(parseHotKey('nonsense'), isNull);
    });
  });
}
