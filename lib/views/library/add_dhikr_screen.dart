// lib/views/library/add_dhikr_screen.dart
import 'package:flutter/material.dart';

class AddDhikrScreen extends StatelessWidget {
  const AddDhikrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Custom Dhikr')),
      body: const Center(
        child: Text('Add Dhikr Form — Phase 2'),
      ),
    );
  }
}
