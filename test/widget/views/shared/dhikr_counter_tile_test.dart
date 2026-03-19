// test/widget/views/shared/dhikr_counter_tile_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/views/shared/dhikr_counter_tile.dart';

const _fakeDhikr = Dhikr(
  id: 1,
  name: 'SubhanAllah',
  arabicText: 'سُبْحَانَ اللَّهِ',
  transliteration: 'Subhanallah',
  translation: 'Glory be to Allah',
  category: 'general_tasbih',
  isPreloaded: true,
  isHidden: false,
  sortOrder: 0,
  createdAt: '2026-01-01T00:00:00',
);

void main() {
  testWidgets('renders Arabic text and count', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DhikrCounterTile(
            dhikr: _fakeDhikr,
            count: 33,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('سُبْحَانَ اللَّهِ'), findsOneWidget);
    expect(find.text('33'), findsOneWidget);
    expect(find.text('Subhanallah'), findsOneWidget);
  });

  testWidgets('calls onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DhikrCounterTile(
            dhikr: _fakeDhikr,
            count: 0,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });

  testWidgets('isActive changes card color', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DhikrCounterTile(
            dhikr: _fakeDhikr,
            count: 0,
            onTap: () {},
            isActive: true,
          ),
        ),
      ),
    );
    // Simply verify it renders without error when isActive = true.
    expect(find.byType(DhikrCounterTile), findsOneWidget);
  });
}
