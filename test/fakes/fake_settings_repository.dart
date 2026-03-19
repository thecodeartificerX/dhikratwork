// test/fakes/fake_settings_repository.dart

import 'dart:convert';

import 'package:dhikratwork/models/user_settings.dart';
import 'package:dhikratwork/repositories/settings_repository.dart';
import 'package:dhikratwork/utils/constants.dart';

/// In-memory fake of [SettingsRepository] for use in ViewModel unit tests.
class FakeSettingsRepository implements SettingsRepository {
  UserSettings _settings = const UserSettings(
    id: kSingleRowId,
    activeDhikrId: null,
    globalHotkey: kDefaultHotkey,
    widgetVisible: true,
    widgetPositionX: null,
    widgetPositionY: null,
    widgetDhikrIds: null,
    themeVariant: 'default',
    subscriptionStatus: kSubscriptionFree,
    subscriptionEmail: null,
    lastSubscriptionPrompt: null,
    createdAt: '2026-01-01T00:00:00',
  );

  /// Override the initial settings for tests that need specific defaults.
  void seed(UserSettings settings) => _settings = settings;

  @override
  Future<UserSettings> getSettings() async => _settings;

  @override
  Future<void> updateSettings(UserSettings settings) async {
    _settings = settings;
  }

  @override
  Future<void> setActiveDhikr(int? dhikrId) async {
    // Build a new UserSettings directly to support null-clearing,
    // since copyWith cannot null out nullable fields.
    _settings = UserSettings(
      id: _settings.id,
      activeDhikrId: dhikrId,
      globalHotkey: _settings.globalHotkey,
      widgetVisible: _settings.widgetVisible,
      widgetPositionX: _settings.widgetPositionX,
      widgetPositionY: _settings.widgetPositionY,
      widgetDhikrIds: _settings.widgetDhikrIds,
      themeVariant: _settings.themeVariant,
      subscriptionStatus: _settings.subscriptionStatus,
      subscriptionEmail: _settings.subscriptionEmail,
      lastSubscriptionPrompt: _settings.lastSubscriptionPrompt,
      createdAt: _settings.createdAt,
    );
  }

  @override
  Future<void> setHotkey(String hotkey) async {
    _settings = _settings.copyWith(globalHotkey: hotkey);
  }

  @override
  Future<void> setWidgetVisible(bool visible) async {
    _settings = _settings.copyWith(widgetVisible: visible);
  }

  @override
  Future<void> setWidgetPosition(double x, double y) async {
    _settings = _settings.copyWith(widgetPositionX: x, widgetPositionY: y);
  }

  @override
  Future<void> setWidgetDhikrIds(List<int> ids) async {
    _settings = _settings.copyWith(widgetDhikrIds: jsonEncode(ids));
  }

  @override
  Future<void> setSubscriptionStatus(String status, String? email) async {
    _settings = UserSettings(
      id: _settings.id,
      activeDhikrId: _settings.activeDhikrId,
      globalHotkey: _settings.globalHotkey,
      widgetVisible: _settings.widgetVisible,
      widgetPositionX: _settings.widgetPositionX,
      widgetPositionY: _settings.widgetPositionY,
      widgetDhikrIds: _settings.widgetDhikrIds,
      themeVariant: _settings.themeVariant,
      subscriptionStatus: status,
      subscriptionEmail: email,
      lastSubscriptionPrompt: _settings.lastSubscriptionPrompt,
      createdAt: _settings.createdAt,
    );
  }
}
