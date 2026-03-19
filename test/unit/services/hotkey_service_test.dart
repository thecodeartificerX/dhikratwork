// test/unit/services/hotkey_service_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
    });

    // -----------------------------------------------------------------------
    // F-key — solo (no modifiers)
    // -----------------------------------------------------------------------

    test('f9 returns non-null with key == f9 and empty modifiers', () {
      final hotKey = parseHotKey('f9');
      expect(hotKey, isNotNull);
      expect(hotKey!.key, equals(LogicalKeyboardKey.f9));
      expect(hotKey.modifiers, anyOf(isNull, isEmpty));
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
  });
}
