// lib/services/floating_window_manager.dart

import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Manages the lifecycle of the floating toolbar OS window.
///
/// Uses desktop_multi_window v0.3.0 which creates sub-windows as separate
/// Flutter engine instances with their own Dart isolates. State is synced
/// via WindowMethodChannel IPC.
///
/// NOTE on desktop_multi_window v0.3.0 architecture:
/// - Each sub-window is a separate FlutterEngine instance.
/// - The sub-window's main() is called fresh with the configuration arguments.
/// - State is NOT automatically shared — use WindowMethodChannel for IPC.
/// - Steps 2 and 3 (Windows runner and macOS config modifications) must be
///   applied manually during native builds. They are not automated here.
class FloatingWindowManager {
  FloatingWindowManager._();

  static final FloatingWindowManager instance = FloatingWindowManager._();

  WindowController? _windowController;
  bool _isVisible = false;

  bool get isVisible => _isVisible;

  /// Creates (or reveals) the floating toolbar window.
  /// [initialX] and [initialY] are the last saved position from user_settings.
  Future<void> showFloatingWidget({double? initialX, double? initialY}) async {
    if (_windowController != null) {
      // Window already exists — just show it.
      await _windowController!.show();
      _isVisible = true;
      return;
    }

    // Create the sub-window. desktop_multi_window passes the arguments string
    // to the new window's main() via WindowController.fromCurrentEngine().
    final controller = await WindowController.create(
      WindowConfiguration(
        arguments: jsonEncode({
          'type': 'floating_toolbar',
          'initialX': initialX ?? 100.0,
          'initialY': initialY ?? 100.0,
        }),
        hiddenAtLaunch: false,
      ),
    );

    _windowController = controller;
    _isVisible = true;
  }

  /// Hides the floating widget without destroying it.
  Future<void> hideFloatingWidget() async {
    if (_windowController == null) return;
    await _windowController!.hide();
    _isVisible = false;
  }

  /// Destroys the floating widget window entirely.
  Future<void> destroyFloatingWidget() async {
    if (_windowController == null) return;
    // WindowController v0.3.0 doesn't have a close() method directly;
    // we send a method call to the sub-window asking it to close itself.
    try {
      await _windowController!.invokeMethod('close');
    } catch (_) {
      // Ignore — window may already be closed.
    }
    _windowController = null;
    _isVisible = false;
  }

  /// Sends a dhikr increment notification to the floating toolbar window via
  /// WindowMethodChannel. The floating toolbar listens for this and updates
  /// its displayed count.
  Future<void> notifyDhikrIncremented(int dhikrId, int newCount) async {
    if (_windowController == null) return;
    try {
      await _windowController!.invokeMethod('onDhikrIncremented', {
        'dhikrId': dhikrId,
        'newCount': newCount,
      });
    } catch (_) {
      // Ignore — floating window may not be connected yet.
    }
  }

  /// Sends updated toolbar state to the floating window.
  Future<void> syncToolbarState({
    required List<Map<String, dynamic>> dhikrs,
    required Map<int, int> todayCounts,
    required int? activeDhikrId,
  }) async {
    if (_windowController == null) return;
    try {
      await _windowController!.invokeMethod('syncState', {
        'dhikrs': dhikrs,
        'todayCounts':
            todayCounts.map((k, v) => MapEntry(k.toString(), v)),
        'activeDhikrId': activeDhikrId,
      });
    } catch (_) {
      // Ignore — floating window may not be ready yet.
    }
  }

  /// Resizes to collapsed state (single icon, 48x48).
  /// Called from within the floating toolbar window via window_manager.
  static Future<void> setCollapsedSize() async {
    await windowManager.setSize(const Size(48, 48));
  }

  /// Resizes to expanded state (full toolbar height).
  /// Called from within the floating toolbar window via window_manager.
  static Future<void> setExpandedSize(int dhikrCount) async {
    final height = 36.0 + dhikrCount * 56.0 + 16.0;
    await windowManager.setSize(Size(240, height));
  }
}
