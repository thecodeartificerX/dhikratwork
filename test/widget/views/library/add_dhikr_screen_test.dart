// test/widget/views/library/add_dhikr_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dhikratwork/viewmodels/dhikr_library_viewmodel.dart';
import 'package:dhikratwork/views/library/add_dhikr_screen.dart';
import '../../../fakes/fake_dhikr_repository.dart';

Widget _wrap(Widget child) {
  final vm = DhikrLibraryViewModel(dhikrRepository: FakeDhikrRepository());
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, state) => const Scaffold()),
    GoRoute(path: '/library', builder: (context, state) => const Scaffold()),
    GoRoute(path: '/library/add', builder: (context, state) => child),
  ], initialLocation: '/library/add');

  return ChangeNotifierProvider.value(
    value: vm,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows validation errors on empty submit', (tester) async {
    await tester.pumpWidget(_wrap(const AddDhikrScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Dhikr'));
    await tester.pumpAndSettle();

    expect(find.text('Name is required.'), findsOneWidget);
    expect(find.text('Arabic text is required.'), findsOneWidget);
    expect(find.text('Transliteration is required.'), findsOneWidget);
    expect(find.text('Translation is required.'), findsOneWidget);
  });

  testWidgets('valid form clears errors', (tester) async {
    await tester.pumpWidget(_wrap(const AddDhikrScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Name *'), 'Test');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Arabic Text *'), 'بِسْمِ اللَّهِ');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Transliteration *'), 'Bismillah');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Translation *'), 'In the name of Allah');

    await tester.tap(find.text('Save Dhikr'));
    await tester.pumpAndSettle();

    expect(find.text('Name is required.'), findsNothing);
  });

  testWidgets('invalid target count shows error', (tester) async {
    await tester.pumpWidget(_wrap(const AddDhikrScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Target Count (optional)'), '-5');
    await tester.tap(find.text('Save Dhikr'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a positive whole number.'), findsOneWidget);
  });
}
