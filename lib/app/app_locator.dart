// lib/app/app_locator.dart

import 'package:dhikratwork/viewmodels/widget_toolbar_viewmodel.dart';
import 'package:dhikratwork/viewmodels/counter_viewmodel.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';

/// Top-level singleton registry for ViewModels that must be shared
/// across both the main window and the floating toolbar window.
///
/// NOTE on desktop_multi_window v0.3.0: Each sub-window runs in its own
/// Flutter engine / Dart isolate. Direct object references do NOT cross
/// isolate boundaries. ViewModels registered here are only accessible from
/// within the main window isolate. The floating toolbar window communicates
/// via WindowMethodChannel IPC (see FloatingWindowManager).
class AppLocator {
  AppLocator._();

  static AppLocator? _instance;
  static AppLocator get instance {
    assert(_instance != null,
        'AppLocator.initialize() must be called before accessing instance.');
    return _instance!;
  }

  late final WidgetToolbarViewModel widgetToolbarViewModel;
  late final CounterViewModel counterViewModel;
  late final SettingsViewModel settingsViewModel;

  static void initialize({
    required WidgetToolbarViewModel widgetToolbarViewModel,
    required CounterViewModel counterViewModel,
    required SettingsViewModel settingsViewModel,
  }) {
    _instance = AppLocator._();
    _instance!.widgetToolbarViewModel = widgetToolbarViewModel;
    _instance!.counterViewModel = counterViewModel;
    _instance!.settingsViewModel = settingsViewModel;
  }

  /// Reset for testing purposes only.
  static void reset() {
    _instance = null;
  }
}
