// lib/viewmodels/widget_toolbar_viewmodel.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:dhikratwork/models/dhikr.dart';
import 'package:dhikratwork/repositories/dhikr_repository.dart';
import 'package:dhikratwork/repositories/session_repository.dart';
import 'package:dhikratwork/repositories/settings_repository.dart';

class WidgetToolbarViewModel extends ChangeNotifier {
  final DhikrRepository _dhikrRepository;
  final SettingsRepository _settingsRepository;
  final SessionRepository _sessionRepository;

  WidgetToolbarViewModel({
    required DhikrRepository dhikrRepository,
    required SettingsRepository settingsRepository,
    required SessionRepository sessionRepository,
  })  : _dhikrRepository = dhikrRepository,
        _settingsRepository = settingsRepository,
        _sessionRepository = sessionRepository;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  List<Dhikr> _toolbarDhikrs = const [];
  int? _activeDhikrId;
  bool _isExpanded = true;
  bool _isLoading = false;
  Map<int, int> _todayCounts = const {};

  List<Dhikr> get toolbarDhikrs => List.unmodifiable(_toolbarDhikrs);
  int? get activeDhikrId => _activeDhikrId;
  bool get isExpanded => _isExpanded;
  bool get isLoading => _isLoading;
  Map<int, int> get todayCounts => Map.unmodifiable(_todayCounts);

  // ---------------------------------------------------------------------------
  // Commands
  // ---------------------------------------------------------------------------

  /// Loads toolbar dhikrs, active dhikr, and today's counts from persistence.
  /// Falls back to first 3 dhikrs from library if no widget_dhikr_ids
  /// configured.
  Future<void> loadToolbar() async {
    _isLoading = true;
    notifyListeners();

    try {
      final settings = await _settingsRepository.getSettings();
      _activeDhikrId = settings.activeDhikrId;

      List<Dhikr> dhikrs;
      final widgetDhikrIdsJson = settings.widgetDhikrIds;
      if (widgetDhikrIdsJson != null && widgetDhikrIdsJson.isNotEmpty) {
        final decoded = jsonDecode(widgetDhikrIdsJson);
        final ids = (decoded as List<dynamic>).cast<int>();
        if (ids.isNotEmpty) {
          dhikrs = await _dhikrRepository.getByIds(ids);
        } else {
          final all = await _dhikrRepository.getAll();
          dhikrs = all.take(3).toList();
        }
      } else {
        final all = await _dhikrRepository.getAll();
        dhikrs = all.take(3).toList();
      }

      _toolbarDhikrs = dhikrs;

      // Load today's count for each toolbar dhikr individually.
      final Map<int, int> counts = {};
      for (final dhikr in dhikrs) {
        if (dhikr.id != null) {
          counts[dhikr.id!] =
              await _sessionRepository.getTodaySessionCount(dhikr.id!);
        }
      }
      _todayCounts = Map.unmodifiable(counts);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Increments today's count for [dhikrId] via an active session and updates
  /// the in-memory map.
  Future<void> incrementDhikr(int dhikrId) async {
    var session = await _sessionRepository.getActiveSession(dhikrId);
    session ??= await _sessionRepository.createSession(dhikrId, 'widget');
    await _sessionRepository.incrementCount(session.id!);
    final newCount = await _sessionRepository.getTodaySessionCount(dhikrId);
    _todayCounts = Map.unmodifiable({..._todayCounts, dhikrId: newCount});
    notifyListeners();
  }

  /// Sets [dhikrId] as the active dhikr and persists to settings.
  Future<void> setActiveDhikr(int dhikrId) async {
    _activeDhikrId = dhikrId;
    notifyListeners();
    await _settingsRepository.setActiveDhikr(dhikrId);
  }

  /// Toggles the expanded/collapsed state of the floating toolbar.
  void toggleExpand() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }

  /// Persists the new dragged position to settings.
  Future<void> updatePosition(double x, double y) async {
    await _settingsRepository.setWidgetPosition(x, y);
    // No notifyListeners needed — position is a window property, not UI state.
  }
}
