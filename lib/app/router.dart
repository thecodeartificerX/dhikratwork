// lib/app/router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:dhikratwork/views/dashboard/dashboard_screen.dart';
import 'package:dhikratwork/views/library/add_dhikr_screen.dart';
import 'package:dhikratwork/views/library/dhikr_detail_screen.dart';
import 'package:dhikratwork/views/library/library_screen.dart';
import 'package:dhikratwork/views/settings/settings_screen.dart';
import 'package:dhikratwork/views/stats/stats_screen.dart';

/// Route path constants. Use these wherever navigation is triggered
/// (e.g., `context.go(AppRoutes.library)`) to avoid raw strings.
abstract final class AppRoutes {
  static const String home = '/';
  static const String library = '/library';
  static const String libraryAdd = '/library/add';
  static const String libraryDetail = '/library/:id';
  static const String stats = '/stats';
  static const String settings = '/settings';

  /// Builds the concrete path for a dhikr detail screen.
  static String dhikrDetail(String id) => '/library/$id';
}

/// Global [GoRouter] instance for the main window.
///
/// The floating widget has its own separate window and does NOT use this router.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: false,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (BuildContext context, GoRouterState state) {
        return const DashboardScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.library,
      name: 'library',
      builder: (BuildContext context, GoRouterState state) {
        return const LibraryScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'add',
          name: 'library-add',
          builder: (BuildContext context, GoRouterState state) {
            return const AddDhikrScreen();
          },
        ),
        GoRoute(
          path: ':id',
          name: 'library-detail',
          builder: (BuildContext context, GoRouterState state) {
            final int dhikrId =
                int.parse(state.pathParameters['id']!);
            return DhikrDetailScreen(dhikrId: dhikrId);
          },
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.stats,
      name: 'stats',
      builder: (BuildContext context, GoRouterState state) {
        return const StatsScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsScreen();
      },
    ),
  ],
  // Error page shown for unknown routes
  errorBuilder: (BuildContext context, GoRouterState state) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  },
);
