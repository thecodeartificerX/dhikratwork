// lib/views/stats/stats_screen.dart
import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats & Progress')),
      body: const Center(
        child: Text('Stats — Phase 2'),
      ),
    );
  }
}
