// lib/views/library/dhikr_detail_screen.dart
import 'package:flutter/material.dart';

class DhikrDetailScreen extends StatelessWidget {
  final String dhikrId;

  const DhikrDetailScreen({super.key, required this.dhikrId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dhikr Detail')),
      body: Center(
        child: Text('Dhikr Detail (id: $dhikrId) — Phase 2'),
      ),
    );
  }
}
