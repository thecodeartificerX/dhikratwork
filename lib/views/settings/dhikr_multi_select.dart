// lib/views/settings/dhikr_multi_select.dart

import 'package:flutter/material.dart';

import '../../models/dhikr.dart';

/// Scrollable checklist of dhikrs. Emits [onChanged] with the updated id list.
class DhikrMultiSelect extends StatefulWidget {
  final List<Dhikr> dhikrs;
  final List<int> selectedIds;
  final ValueChanged<List<int>> onChanged;

  const DhikrMultiSelect({
    super.key,
    required this.dhikrs,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  State<DhikrMultiSelect> createState() => _DhikrMultiSelectState();
}

class _DhikrMultiSelectState extends State<DhikrMultiSelect> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        itemCount: widget.dhikrs.length,
        itemBuilder: (context, index) {
          final dhikr = widget.dhikrs[index];
          // Skip dhikrs that have no id (unsaved entries).
          if (dhikr.id == null) return const SizedBox.shrink();
          final selected = widget.selectedIds.contains(dhikr.id);
          return CheckboxListTile(
            title: Text(dhikr.name),
            subtitle: Text(dhikr.arabicText),
            value: selected,
            onChanged: (checked) {
              final updated = List<int>.from(widget.selectedIds);
              if (checked == true) {
                if (!updated.contains(dhikr.id)) updated.add(dhikr.id!);
              } else {
                updated.remove(dhikr.id);
              }
              widget.onChanged(updated);
            },
          );
        },
      ),
    );
  }
}
