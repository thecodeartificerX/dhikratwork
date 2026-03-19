// lib/services/tray_service.dart

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';

import 'package:dhikratwork/viewmodels/widget_toolbar_viewmodel.dart';
import 'package:dhikratwork/services/floating_window_manager.dart';

/// Manages the system tray icon and context menu.
///
/// NOTE: The tray icon asset must be registered in pubspec.yaml:
///   flutter:
///     assets:
///       - assets/tray/tray_icon.png
///
/// On Windows, tray_manager requires a .ico file for best quality. A .png
/// will also work for basic use. Provide a 32x32 PNG at assets/tray/tray_icon.png.
class TrayService with TrayListener {
  TrayService._();

  static final TrayService instance = TrayService._();

  VoidCallback? _onShowMainWindow;
  VoidCallback? _onHideMainWindow;
  VoidCallback? _onQuit;
  WidgetToolbarViewModel? _widgetToolbarViewModel;

  // Track whether the main window is currently visible.
  bool _mainWindowVisible = true;

  /// Must be called once after the tray icon asset is set in main.dart.
  Future<void> setup({
    required VoidCallback onShowMainWindow,
    required VoidCallback onHideMainWindow,
    required VoidCallback onQuit,
    required WidgetToolbarViewModel widgetToolbarViewModel,
  }) async {
    _onShowMainWindow = onShowMainWindow;
    _onHideMainWindow = onHideMainWindow;
    _onQuit = onQuit;
    _widgetToolbarViewModel = widgetToolbarViewModel;

    trayManager.addListener(this);

    // Set tooltip on the tray icon.
    await trayManager.setToolTip('DhikrAtWork');

    // Build the initial context menu.
    await _rebuildContextMenu();

    // Listen for ViewModel changes to rebuild the menu when counts update.
    widgetToolbarViewModel.addListener(_onViewModelChanged);
  }

  Future<void> _onViewModelChanged() async {
    await _rebuildContextMenu();
  }

  Future<void> _rebuildContextMenu() async {
    final vm = _widgetToolbarViewModel;

    String activeDhikrName = 'None';
    int activeDhikrCount = 0;

    if (vm != null) {
      if (vm.activeDhikrId != null) {
        final activeDhikr = vm.toolbarDhikrs
            .where((d) => d.id == vm.activeDhikrId)
            .firstOrNull;
        if (activeDhikr != null) {
          activeDhikrName = activeDhikr.name;
          activeDhikrCount = vm.todayCounts[vm.activeDhikrId!] ?? 0;
        }
      }
    }

    final menu = Menu(
      items: [
        MenuItem(
          key: 'toggle_main_window',
          label: _mainWindowVisible ? 'Hide Main Window' : 'Show Main Window',
        ),
        MenuItem(
          key: 'toggle_floating_widget',
          label: FloatingWindowManager.instance.isVisible
              ? 'Hide Floating Widget'
              : 'Show Floating Widget',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'active_dhikr_info',
          label: 'Active: $activeDhikrName — $activeDhikrCount today',
          disabled: true, // Display only, not clickable
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'quit',
          label: 'Quit DhikrAtWork',
        ),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  // Called when user left-clicks the tray icon.
  @override
  void onTrayIconMouseDown() {
    if (_mainWindowVisible) {
      _mainWindowVisible = false;
      _onHideMainWindow?.call();
    } else {
      _mainWindowVisible = true;
      _onShowMainWindow?.call();
    }
    _rebuildContextMenu();
  }

  // Called when user right-clicks (shows context menu automatically on Windows;
  // on macOS this must be triggered manually).
  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'toggle_main_window':
        if (_mainWindowVisible) {
          _mainWindowVisible = false;
          _onHideMainWindow?.call();
        } else {
          _mainWindowVisible = true;
          _onShowMainWindow?.call();
        }
        _rebuildContextMenu();

      case 'toggle_floating_widget':
        if (FloatingWindowManager.instance.isVisible) {
          FloatingWindowManager.instance.hideFloatingWidget();
        } else {
          FloatingWindowManager.instance.showFloatingWidget();
        }
        _rebuildContextMenu();

      case 'quit':
        _onQuit?.call();
    }
  }

  void dispose() {
    trayManager.removeListener(this);
    _widgetToolbarViewModel?.removeListener(_onViewModelChanged);
  }
}
