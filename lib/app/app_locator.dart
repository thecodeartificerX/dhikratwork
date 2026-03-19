// lib/app/app_locator.dart

import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';

/// Top-level singleton registry for ViewModels that must be accessible
/// outside of the Provider tree (e.g. from platform callbacks).
///
/// Only the two core VMs are registered here. All other VMs are distributed
/// via Provider in the widget tree.
class AppLocator {
  AppLocator._();

  static AppLocator? _instance;
  static AppLocator get instance {
    assert(_instance != null,
        'AppLocator.initialize() must be called before accessing instance.');
    return _instance!;
  }

  late final CounterViewModel counterViewModel;
  late final SettingsViewModel settingsViewModel;

  static void initialize({
    required CounterViewModel counterViewModel,
    required SettingsViewModel settingsViewModel,
  }) {
    _instance = AppLocator._();
    _instance!.counterViewModel = counterViewModel;
    _instance!.settingsViewModel = settingsViewModel;
  }

  /// Reset for testing purposes only.
  static void reset() {
    _instance = null;
  }
}
