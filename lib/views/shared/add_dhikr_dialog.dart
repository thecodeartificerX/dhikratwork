// lib/views/shared/add_dhikr_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dhikratwork/models/dhikr.dart';

/// Dialog for adding a custom dhikr.
/// Returns the created [Dhikr] via [Navigator.pop], or null on cancel.
class AddDhikrDialog extends StatefulWidget {
  const AddDhikrDialog({super.key});

  @override
  State<AddDhikrDialog> createState() => _AddDhikrDialogState();
}

class _AddDhikrDialogState extends State<AddDhikrDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _arabicController = TextEditingController();
  final _transliterationController = TextEditingController();
  final _translationController = TextEditingController();
  final _targetCountController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _arabicController.dispose();
    _transliterationController.dispose();
    _translationController.dispose();
    _targetCountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final int? targetCount = _targetCountController.text.trim().isEmpty
        ? null
        : int.tryParse(_targetCountController.text.trim());

    final dhikr = Dhikr(
      name: _nameController.text.trim(),
      arabicText: _arabicController.text.trim(),
      transliteration: _transliterationController.text.trim(),
      translation: _translationController.text.trim(),
      category: 'custom',
      isPreloaded: false,
      isHidden: false,
      targetCount: targetCount,
      sortOrder: 0,
      createdAt: DateTime.now().toIso8601String(),
    );

    Navigator.of(context).pop(dhikr);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Add Custom Dhikr'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'e.g. Astaghfirullah',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _arabicController,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'Arabic Text *',
                    hintText: 'أَسْتَغْفِرُ اللَّهَ',
                  ),
                  style: theme.textTheme.headlineMedium,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Arabic text is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _transliterationController,
                  decoration: const InputDecoration(
                    labelText: 'Transliteration *',
                    hintText: 'e.g. Astaghfirullah',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Transliteration is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _translationController,
                  decoration: const InputDecoration(
                    labelText: 'Translation *',
                    hintText: 'e.g. I seek forgiveness from Allah',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Translation is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _targetCountController,
                  decoration: const InputDecoration(
                    labelText: 'Target Count (optional)',
                    hintText: 'e.g. 33',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final n = int.tryParse(value.trim());
                      if (n == null || n <= 0) {
                        return 'Must be a positive integer';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
