// lib/viewmodels/settings_viewmodel.dart

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/dhikr.dart';
import '../models/user_settings.dart';
import '../repositories/dhikr_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/hotkey_service.dart';
import '../services/subscription_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _settingsRepository;
  final DhikrRepository _dhikrRepository;
  final SubscriptionService _subscriptionService;

  SettingsViewModel({
    required SettingsRepository settingsRepository,
    required DhikrRepository dhikrRepository,
    required SubscriptionService subscriptionService,
  })  : _settingsRepository = settingsRepository,
        _dhikrRepository = dhikrRepository,
        _subscriptionService = subscriptionService;

  // ── State ──────────────────────────────────────────────────────────────────

  UserSettings _settings = UserSettings(
    id: 1,
    activeDhikrId: null,
    globalHotkey: 'ctrl+shift+d',
    widgetVisible: true,
    widgetPositionX: null,
    widgetPositionY: null,
    widgetDhikrIds: null,
    themeVariant: 'system',
    subscriptionStatus: 'free',
    subscriptionEmail: null,
    lastSubscriptionPrompt: null,
    createdAt: DateTime.now().toIso8601String(),
  );

  List<Dhikr> _allDhikrs = [];
  bool _isLoading = false;
  bool _isVerifyingSubscription = false;
  String? _subscriptionError;
  String? _exportError;
  bool _isExporting = false;

  // ── Getters ────────────────────────────────────────────────────────────────

  UserSettings get settings => _settings;
  List<Dhikr> get allDhikrs => List.unmodifiable(_allDhikrs);
  bool get isLoading => _isLoading;
  bool get isVerifyingSubscription => _isVerifyingSubscription;
  bool get isExporting => _isExporting;
  String? get subscriptionError => _subscriptionError;
  String? get exportError => _exportError;

  String get hotkeyString => _settings.globalHotkey;
  bool get isSubscribed => _settings.subscriptionStatus == 'subscribed';
  String? get subscriptionEmail => _settings.subscriptionEmail;

  // ── Hotkey registration state (Phase 4) ────────────────────────────────────

  bool _hotkeyRegistered = false;
  String? _hotkeyError;
  VoidCallback? _hotkeyTriggerCallback;

  bool get hotkeyRegistered => _hotkeyRegistered;
  String? get hotkeyError => _hotkeyError;

  /// Late-inject the hotkey trigger callback to avoid circular dependencies.
  /// Typically wired to CounterViewModel.incrementActiveDhikr.
  void setHotkeyTriggerCallback(VoidCallback callback) {
    _hotkeyTriggerCallback = callback;
  }

  /// Parses [settings.widgetDhikrIds] (a JSON array string) into a [List<int>].
  /// Returns an empty list if the field is null or malformed.
  List<int> get widgetDhikrIdsList {
    final raw = _settings.widgetDhikrIds;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return List<int>.from(decoded.whereType<int>());
      }
    } catch (_) {
      // Malformed JSON — return empty list rather than crash.
    }
    return const [];
  }

  // ── Commands ───────────────────────────────────────────────────────────────

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = await _settingsRepository.getSettings();
      _allDhikrs = await _dhikrRepository.getAll();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateHotkey(String newHotkey) async {
    _settings = _settings.copyWith(globalHotkey: newHotkey);
    await _settingsRepository.updateSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleWidgetVisible() async {
    _settings = _settings.copyWith(widgetVisible: !_settings.widgetVisible);
    await _settingsRepository.updateSettings(_settings);
    notifyListeners();
  }

  /// Clears the widget position by reconstructing [UserSettings] with null
  /// position fields. [copyWith] cannot null out nullable fields, so we
  /// reconstruct the object directly.
  Future<void> resetWidgetPosition() async {
    _settings = UserSettings(
      id: _settings.id,
      activeDhikrId: _settings.activeDhikrId,
      globalHotkey: _settings.globalHotkey,
      widgetVisible: _settings.widgetVisible,
      widgetPositionX: null,
      widgetPositionY: null,
      widgetDhikrIds: _settings.widgetDhikrIds,
      themeVariant: _settings.themeVariant,
      subscriptionStatus: _settings.subscriptionStatus,
      subscriptionEmail: _settings.subscriptionEmail,
      lastSubscriptionPrompt: _settings.lastSubscriptionPrompt,
      createdAt: _settings.createdAt,
    );
    await _settingsRepository.updateSettings(_settings);
    notifyListeners();
  }

  /// Saves a new dhikr id selection for the floating widget.
  /// Converts [dhikrIds] to a JSON array string for storage.
  Future<void> updateWidgetDhikrSelection(List<int> dhikrIds) async {
    _settings = _settings.copyWith(widgetDhikrIds: jsonEncode(dhikrIds));
    await _settingsRepository.updateSettings(_settings);
    notifyListeners();
  }

  /// Queries Firestore for [email] subscription status.
  /// On success, persists subscription status locally.
  /// On [SubscriptionOfflineException], sets [subscriptionError] and trusts
  /// local state per spec §10.
  Future<void> verifySubscription(String email) async {
    _subscriptionError = null;
    _isVerifyingSubscription = true;
    notifyListeners();

    try {
      final active = await _subscriptionService.checkSubscription(email);
      if (active) {
        _settings = UserSettings(
          id: _settings.id,
          activeDhikrId: _settings.activeDhikrId,
          globalHotkey: _settings.globalHotkey,
          widgetVisible: _settings.widgetVisible,
          widgetPositionX: _settings.widgetPositionX,
          widgetPositionY: _settings.widgetPositionY,
          widgetDhikrIds: _settings.widgetDhikrIds,
          themeVariant: _settings.themeVariant,
          subscriptionStatus: 'subscribed',
          subscriptionEmail: email,
          lastSubscriptionPrompt: _settings.lastSubscriptionPrompt,
          createdAt: _settings.createdAt,
        );
        await _settingsRepository.updateSettings(_settings);
      } else {
        _settings = _settings.copyWith(subscriptionStatus: 'free');
        await _settingsRepository.updateSettings(_settings);
      }
    } on SubscriptionOfflineException {
      // Trust local state; surface error to UI.
      _subscriptionError =
          'You appear to be offline. Your current subscription status is trusted from local storage.';
    } catch (e) {
      _subscriptionError = 'Verification failed: $e';
    } finally {
      _isVerifyingSubscription = false;
      notifyListeners();
    }
  }

  /// Exports all dhikrs as [format] ('json' or 'csv').
  /// Uses [Isolate.run] for serialisation per spec §11.
  /// On platforms where [getApplicationDocumentsDirectory] is unavailable
  /// (e.g. test environments), the error is captured in [exportError].
  Future<void> exportData(String format) async {
    _exportError = null;
    _isExporting = true;
    notifyListeners();

    try {
      final dhikrs = await _dhikrRepository.getAll();

      // Build raw data payload on main isolate (cheap list fetch).
      // Serialisation itself is CPU-bound, so offload to a worker isolate.
      final dhikrMaps = dhikrs.map((d) => d.toJson()).toList();

      final String content;
      if (format == 'json') {
        content = await Isolate.run(() => _serializeJson(dhikrMaps));
      } else if (format == 'csv') {
        content = await Isolate.run(() => _serializeCsv(dhikrMaps));
      } else {
        throw ArgumentError('Unknown export format: $format');
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = format == 'json' ? 'json' : 'csv';
      final file = File('${dir.path}/dhikratwork_export_$timestamp.$ext');
      await file.writeAsString(content, flush: true);
    } catch (e) {
      _exportError = 'Export failed: $e';
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  // ── Hotkey commands (Phase 4) ──────────────────────────────────────────────

  /// Called from main.dart after settings are loaded to register the stored
  /// global hotkey string (e.g. 'ctrl+shift+d').
  Future<void> applyHotkeyFromString(String hotkeyString) async {
    _hotkeyError = null;
    notifyListeners();

    final success = await HotkeyService.instance.register(
      hotkeyString: hotkeyString,
      onTriggered: _onHotkeyTriggered,
      onRegistrationFailed: _onHotkeyRegistrationFailed,
    );

    _hotkeyRegistered = success;
    notifyListeners();
  }

  /// Called from the Settings screen when the user records a new hotkey.
  Future<void> changeHotkey(String newHotkeyString) async {
    final success = await HotkeyService.instance.register(
      hotkeyString: newHotkeyString,
      onTriggered: _onHotkeyTriggered,
      onRegistrationFailed: _onHotkeyRegistrationFailed,
    );

    if (success) {
      _settings = _settings.copyWith(globalHotkey: newHotkeyString);
      _hotkeyError = null;
      _hotkeyRegistered = true;
      await _settingsRepository.updateSettings(_settings);
    } else {
      _hotkeyError =
          'Could not register "$newHotkeyString" — it may be in use by another app.';
      _hotkeyRegistered = false;
    }

    notifyListeners();
  }

  void _onHotkeyTriggered() {
    _hotkeyTriggerCallback?.call();
  }

  void _onHotkeyRegistrationFailed() {
    _hotkeyError =
        'Failed to register global hotkey. Another application may own this shortcut.';
    _hotkeyRegistered = false;
    notifyListeners();
  }

  // ── Private isolate-safe serializers ──────────────────────────────────────

  // These are static methods so they can be sent across isolate boundaries
  // without closing over non-sendable state.

  static String _serializeJson(List<Map<String, dynamic>> rows) {
    return const JsonEncoder.withIndent('  ').convert(rows);
  }

  static String _serializeCsv(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return '';
    final headers = rows.first.keys.join(',');
    final lines = rows.map((row) {
      return row.values.map((v) {
        final s = v?.toString() ?? '';
        // Escape double-quotes and wrap fields containing commas/newlines.
        if (s.contains(',') || s.contains('"') || s.contains('\n')) {
          return '"${s.replaceAll('"', '""')}"';
        }
        return s;
      }).join(',');
    });
    return '$headers\n${lines.join('\n')}';
  }
}
