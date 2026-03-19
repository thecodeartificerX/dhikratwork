// lib/views/library/library_screen.dart
import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dhikr Library')),
      body: const Center(
        child: Text('Library — Phase 2'),
      ),
    );
  }
}
