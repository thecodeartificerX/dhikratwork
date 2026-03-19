// lib/services/update_service.dart
//
// Auto-update service using auto_updater (Sparkle) for macOS distribution.
//
// Windows auto-update is handled via the .appinstaller / MSIX mechanism
// configured in pubspec.yaml (msix_config.app_installer). This service is
// macOS-only.
//
// Usage: Call UpdateService().initialize() inside main() after the app
// is initialized, then call checkForUpdates() to trigger a manual check.

import 'dart:io';

import 'package:auto_updater/auto_updater.dart';

/// Manages Sparkle-based auto-updates on macOS.
///
/// The [_appcastUrl] points to a publicly accessible appcast.xml file that
/// lists available versions with their download URLs and EdDSA signatures.
/// Sparkle verifies the signature before downloading any update.
class UpdateService {
  static const String _appcastUrl =
      'https://raw.githubusercontent.com/YOUR_ORG/dhikratwork/main/appcast.xml';

  /// Number of seconds between automatic background update checks.
  /// Default: 86400 (24 hours).
  static const int _checkIntervalSeconds = 86400;

  /// Initialize Sparkle with the appcast feed URL and set the automatic
  /// background check interval. Call this once during app startup.
  ///
  /// No-op on non-macOS platforms.
  Future<void> initialize() async {
    if (!Platform.isMacOS) return;

    await autoUpdater.setFeedURL(_appcastUrl);
    await autoUpdater.setScheduledCheckInterval(_checkIntervalSeconds);
  }

  /// Trigger an immediate update check. Sparkle will show its built-in
  /// update dialog if a newer version is available.
  ///
  /// No-op on non-macOS platforms.
  Future<void> checkForUpdates() async {
    if (!Platform.isMacOS) return;

    await autoUpdater.checkForUpdates();
  }
}
