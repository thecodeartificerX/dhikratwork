// lib/repositories/settings_repository.dart

import 'dart:convert';

import 'package:dhikratwork/models/user_settings.dart';
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/utils/constants.dart';

/// SSOT for [UserSettings] domain data.
///
/// The [user_settings] table is a single-row table enforced by a CHECK
/// constraint on id = 1. On [getSettings], the repository upserts the default
/// row if it does not yet exist, guaranteeing a non-null return.
class SettingsRepository {
  final DatabaseService _db;

  SettingsRepository(this._db);

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Returns the current [UserSettings]. If no row exists (first launch),
  /// inserts and returns a default settings object.
  Future<UserSettings> getSettings() async {
    final rows = await _db.query(
      tUserSettings,
      where: '$cSettingsId = ?',
      whereArgs: [kSingleRowId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return UserSettings.fromMap(rows.first);
    }

    // First launch: create default row
    final defaults = _defaultSettingsMap();
    await _db.insert(tUserSettings, defaults);
    return UserSettings.fromMap(defaults);
  }

  // ---------------------------------------------------------------------------
  // Write — full update
  // ---------------------------------------------------------------------------

  /// Persist all fields of [settings] to the database.
  Future<void> updateSettings(UserSettings settings) async {
    await _db.update(
      tUserSettings,
      settings.toMap(),
      where: '$cSettingsId = ?',
      whereArgs: [kSingleRowId],
    );
  }

  // ---------------------------------------------------------------------------
  // Write — targeted field helpers
  // ---------------------------------------------------------------------------

  /// Set or clear the active dhikr. Pass null to unset.
  Future<void> setActiveDhikr(int? dhikrId) async {
    await _patchSettings({cSettingsActiveDhikrId: dhikrId});
  }

  /// Update the global hotkey combo string (e.g. `'ctrl+shift+d'`).
  Future<void> setHotkey(String hotkey) async {
    await _patchSettings({cSettingsGlobalHotkey: hotkey});
  }

  /// Show or hide the floating widget.
  Future<void> setWidgetVisible(bool visible) async {
    await _patchSettings({cSettingsWidgetVisible: visible ? 1 : 0});
  }

  /// Persist the floating widget's screen position.
  Future<void> setWidgetPosition(double x, double y) async {
    await _patchSettings({
      cSettingsWidgetPositionX: x,
      cSettingsWidgetPositionY: y,
    });
  }

  /// Persist the ordered list of dhikr ids shown in the floating widget.
  /// Stored as a JSON array string.
  Future<void> setWidgetDhikrIds(List<int> ids) async {
    await _patchSettings({cSettingsWidgetDhikrIds: jsonEncode(ids)});
  }

  /// Update subscription status and associated email together.
  Future<void> setSubscriptionStatus(String status, String? email) async {
    await _patchSettings({
      cSettingsSubscriptionStatus: status,
      cSettingsSubscriptionEmail: email,
    });
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Apply a partial map of column→value updates to the single settings row.
  Future<void> _patchSettings(Map<String, dynamic> patch) async {
    await _db.update(
      tUserSettings,
      patch,
      where: '$cSettingsId = ?',
      whereArgs: [kSingleRowId],
    );
  }

  /// Default column values for the initial settings row.
  Map<String, dynamic> _defaultSettingsMap() {
    return <String, dynamic>{
      cSettingsId: kSingleRowId,
      cSettingsActiveDhikrId: null,
      cSettingsGlobalHotkey: kDefaultHotkey,
      cSettingsWidgetVisible: 1,
      cSettingsWidgetPositionX: null,
      cSettingsWidgetPositionY: null,
      cSettingsWidgetDhikrIds: null,
      cSettingsThemeVariant: 'default',
      cSettingsSubscriptionStatus: kSubscriptionFree,
      cSettingsSubscriptionEmail: null,
      cSettingsLastSubscriptionPrompt: null,
      cSettingsCreatedAt: DateTime.now().toIso8601String(),
    };
  }
}
