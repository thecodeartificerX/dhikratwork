// lib/services/tray_service.dart

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';

/// Manages the system tray icon and a minimal context menu.
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

  VoidCallback? _onQuit;

  /// Must be called once after the tray icon asset is set via trayManager.setIcon().
  Future<void> setup({required VoidCallback onQuit}) async {
    _onQuit = onQuit;

    trayManager.addListener(this);

    await trayManager.setToolTip('DhikrAtWork');

    final menu = Menu(
      items: [
        MenuItem(
          key: 'quit',
          label: 'Quit DhikrAtWork',
        ),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  /// Left-click on the tray icon — no action in single-window mode.
  @override
  void onTrayIconMouseDown() {
    // No-op: the app is always visible as a compact bar or expanded window.
  }

  /// Right-click on the tray icon — pop up the context menu.
  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'quit') {
      _onQuit?.call();
    }
  }

  void dispose() {
    trayManager.removeListener(this);
  }
}
