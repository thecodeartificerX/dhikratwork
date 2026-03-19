// lib/views/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DhikrAtWork')),
      body: const Center(
        child: Text('Dashboard — Phase 2'),
      ),
    );
  }
}
