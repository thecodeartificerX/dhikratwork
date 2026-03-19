// lib/views/library/add_dhikr_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/viewmodels/dhikr_library_viewmodel.dart';

class AddDhikrScreen extends StatefulWidget {
  const AddDhikrScreen({super.key});

  @override
  State<AddDhikrScreen> createState() => _AddDhikrScreenState();
}

class _AddDhikrScreenState extends State<AddDhikrScreen> {
  // Form key — instantiated once in State, never inside build().
  final _formKey = GlobalKey<FormState>();

  // Controllers for each field.
  final _nameController = TextEditingController();
  final _arabicController = TextEditingController();
  final _transliterationController = TextEditingController();
  final _translationController = TextEditingController();
  final _targetCountController = TextEditingController();

  String _selectedCategory = 'general_tasbih';
  bool _isSaving = false;

  static const _categories = [
    ('general_tasbih', 'General Tasbih'),
    ('post_salah', 'Post-Salah'),
    ('istighfar', 'Istighfar'),
    ('salawat', 'Salawat'),
    ('dua_remembrance', 'Dua & Remembrance'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _arabicController.dispose();
    _transliterationController.dispose();
    _translationController.dispose();
    _targetCountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final dhikr = Dhikr(
      name: _nameController.text.trim(),
      arabicText: _arabicController.text.trim(),
      transliteration: _transliterationController.text.trim(),
      translation: _translationController.text.trim(),
      category: _selectedCategory,
      isPreloaded: false,
      isHidden: false,
      targetCount: _targetCountController.text.isEmpty
          ? null
          : int.tryParse(_targetCountController.text.trim()),
      sortOrder: 999,
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      await context.read<DhikrLibraryViewModel>().addDhikr(dhikr);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dhikr added successfully.')),
        );
        context.go('/library');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving dhikr: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Custom Dhikr'),
        leading: Tooltip(
          message: 'Back to Library',
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/library'),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        hintText: 'e.g. SubhanAllah',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Name is required.';
                        }
                        if (v.trim().length < 2) {
                          return 'Name must be at least 2 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Arabic text
                    TextFormField(
                      controller: _arabicController,
                      decoration: const InputDecoration(
                        labelText: 'Arabic Text *',
                        hintText: 'سُبْحَانَ اللَّهِ',
                        border: OutlineInputBorder(),
                      ),
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 20,
                        height: 1.8,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Arabic text is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Transliteration
                    TextFormField(
                      controller: _transliterationController,
                      decoration: const InputDecoration(
                        labelText: 'Transliteration *',
                        hintText: 'e.g. Subhanallah',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Transliteration is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Translation
                    TextFormField(
                      controller: _translationController,
                      decoration: const InputDecoration(
                        labelText: 'Translation *',
                        hintText: 'e.g. Glory be to Allah',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Translation is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Category dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.$1,
                              child: Text(c.$2),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedCategory = v);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Target count (optional)
                    TextFormField(
                      controller: _targetCountController,
                      decoration: const InputDecoration(
                        labelText: 'Target Count (optional)',
                        hintText: 'e.g. 33 for post-salah',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = int.tryParse(v.trim());
                        if (n == null || n <= 0) {
                          return 'Enter a positive whole number.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // Submit button.
                    FilledButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Dhikr'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
