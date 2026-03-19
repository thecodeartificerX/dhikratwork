// lib/viewmodels/app_shell_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:dhikratwork/repositories/settings_repository.dart';

enum AppMode { compact, expanded }

class AppShellViewModel extends ChangeNotifier {
  final SettingsRepository _settingsRepository;

  AppShellViewModel({required SettingsRepository settingsRepository})
      : _settingsRepository = settingsRepository;

  AppMode _mode = AppMode.compact;
  AppMode get mode => _mode;

  double? _compactPositionX;
  double? _compactPositionY;
  double? get compactPositionX => _compactPositionX;
  double? get compactPositionY => _compactPositionY;

  Future<void> setMode(AppMode newMode) async {
    if (_mode == newMode) return;
    _mode = newMode;
    notifyListeners();
  }

  Future<void> loadSavedPosition() async {
    final settings = await _settingsRepository.getSettings();
    _compactPositionX = settings.widgetPositionX;
    _compactPositionY = settings.widgetPositionY;
  }

  Future<void> saveCompactPosition(double x, double y) async {
    _compactPositionX = x;
    _compactPositionY = y;
    await _settingsRepository.setWidgetPosition(x, y);
  }
}
