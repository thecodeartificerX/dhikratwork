// lib/viewmodels/dhikr_library_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';

class DhikrLibraryViewModel extends ChangeNotifier {
  final DhikrRepository _dhikrRepository;

  DhikrLibraryViewModel({required DhikrRepository dhikrRepository})
      : _dhikrRepository = dhikrRepository;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  List<Dhikr> _dhikrList = const [];

  /// Full master list, unmodifiable. Excludes hidden items.
  List<Dhikr> get dhikrList => _dhikrList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ---------------------------------------------------------------------------
  // Commands
  // ---------------------------------------------------------------------------

  /// Fetch all non-hidden dhikr from the repository.
  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      final all = await _dhikrRepository.getAll();
      _dhikrList = List.unmodifiable(all.where((d) => !d.isHidden).toList());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Insert a new dhikr and refresh.
  Future<void> addDhikr(Dhikr dhikr) async {
    await _dhikrRepository.add(dhikr);
    await loadAll();
  }

  /// Update an existing dhikr and refresh.
  Future<void> updateDhikr(Dhikr dhikr) async {
    await _dhikrRepository.update(dhikr);
    await loadAll();
  }

  /// Delete a user-created dhikr by [id] and refresh.
  Future<void> deleteDhikr(int id) async {
    await _dhikrRepository.delete(id);
    await loadAll();
  }

  /// Hide a preloaded dhikr (cannot be deleted) and refresh.
  Future<void> hideDhikr(int id) async {
    await _dhikrRepository.hide(id);
    await loadAll();
  }
}
