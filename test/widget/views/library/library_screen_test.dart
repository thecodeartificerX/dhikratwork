// test/widget/views/library/library_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dhikratwork/viewmodels/dhikr_library_viewmodel.dart';
import 'package:dhikratwork/views/library/library_screen.dart';
import '../../../fakes/fake_dhikr_repository.dart';

Widget _buildTestApp() {
  final vm = DhikrLibraryViewModel(dhikrRepository: FakeDhikrRepository());

  final router = GoRouter(
    initialLocation: '/library',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const Scaffold()),
      GoRoute(path: '/library', builder: (context, state) => const LibraryScreen()),
      GoRoute(path: '/library/add', builder: (context, state) => const Scaffold()),
      GoRoute(
        path: '/library/:id',
        builder: (context, state) => Scaffold(
          body: Text('Detail ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );

  return ChangeNotifierProvider.value(
    value: vm,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows library app bar', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    expect(find.text('Dhikr Library'), findsOneWidget);
  });

  testWidgets('shows Arabic text for each dhikr', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    expect(find.text('سُبْحَانَ اللَّهِ'), findsOneWidget);
    expect(find.text('اَلْحَمْدُ لِلَّهِ'), findsOneWidget);
  });

  testWidgets('shows category header for general_tasbih', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    // "General Tasbih" appears in both the sidebar filter and the list header.
    expect(find.text('General Tasbih'), findsAtLeastNWidgets(1));
  });

  testWidgets('Add Custom button navigates to /library/add', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Custom'));
    await tester.pumpAndSettle();
    // Router navigated — library screen no longer shown.
    expect(find.text('Dhikr Library'), findsNothing);
  });
}
