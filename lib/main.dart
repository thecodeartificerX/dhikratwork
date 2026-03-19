// lib/main.dart
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dhikratwork/app/router.dart';
import 'package:dhikratwork/app/theme.dart';

void main() {
  // Required for sqflite on Windows and macOS desktop.
  // Must be called before any database operations.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(const DhikrAtWorkApp());
}

/// Root widget. Wires up theme + go_router.
///
/// Provider tree for ViewModels is added in Phase 2 once repositories and
/// ViewModels are implemented. For now this is the minimal working shell.
class DhikrAtWorkApp extends StatelessWidget {
  const DhikrAtWorkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DhikrAtWork',
      theme: buildAppTheme(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
