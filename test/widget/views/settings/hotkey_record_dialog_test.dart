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
