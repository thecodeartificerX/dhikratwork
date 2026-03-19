// lib/models/user_settings.dart
import 'package:dhikratwork/utils/constants.dart';

/// Immutable domain model for the single-row user settings table.
class UserSettings {
  final int id; // Always kSingleRowId (1)
  final int? activeDhikrId;
  final String globalHotkey;
  final bool widgetVisible;
  final double? widgetPositionX;
  final double? widgetPositionY;
  final String? widgetDhikrIds; // JSON array string e.g. '[1,2,3]'
  final String themeVariant;
  final String subscriptionStatus;
  final String? subscriptionEmail;
  final String? lastSubscriptionPrompt;
  final String createdAt;

  const UserSettings({
    this.id = kSingleRowId,
    this.activeDhikrId,
    this.globalHotkey = kDefaultHotkey,
    this.widgetVisible = true,
    this.widgetPositionX,
    this.widgetPositionY,
    this.widgetDhikrIds,
    this.themeVariant = 'default',
    this.subscriptionStatus = kSubscriptionFree,
    this.subscriptionEmail,
    this.lastSubscriptionPrompt,
    required this.createdAt,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      id: map[cSettingsId] as int,
      activeDhikrId: map[cSettingsActiveDhikrId] as int?,
      globalHotkey: map[cSettingsGlobalHotkey] as String? ?? kDefaultHotkey,
      widgetVisible: (map[cSettingsWidgetVisible] as int) == 1,
      widgetPositionX: map[cSettingsWidgetPositionX] as double?,
      widgetPositionY: map[cSettingsWidgetPositionY] as double?,
      widgetDhikrIds: map[cSettingsWidgetDhikrIds] as String?,
      themeVariant: map[cSettingsThemeVariant] as String? ?? 'default',
      subscriptionStatus:
          map[cSettingsSubscriptionStatus] as String? ?? kSubscriptionFree,
      subscriptionEmail: map[cSettingsSubscriptionEmail] as String?,
      lastSubscriptionPrompt:
          map[cSettingsLastSubscriptionPrompt] as String?,
      createdAt: map[cSettingsCreatedAt] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      cSettingsId: id,
      cSettingsActiveDhikrId: activeDhikrId,
      cSettingsGlobalHotkey: globalHotkey,
      cSettingsWidgetVisible: widgetVisible ? 1 : 0,
      cSettingsWidgetPositionX: widgetPositionX,
      cSettingsWidgetPositionY: widgetPositionY,
      cSettingsWidgetDhikrIds: widgetDhikrIds,
      cSettingsThemeVariant: themeVariant,
      cSettingsSubscriptionStatus: subscriptionStatus,
      cSettingsSubscriptionEmail: subscriptionEmail,
      cSettingsLastSubscriptionPrompt: lastSubscriptionPrompt,
      cSettingsCreatedAt: createdAt,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  UserSettings copyWith({
    int? id,
    int? activeDhikrId,
    String? globalHotkey,
    bool? widgetVisible,
    double? widgetPositionX,
    double? widgetPositionY,
    String? widgetDhikrIds,
    String? themeVariant,
    String? subscriptionStatus,
    String? subscriptionEmail,
    String? lastSubscriptionPrompt,
    String? createdAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      activeDhikrId: activeDhikrId ?? this.activeDhikrId,
      globalHotkey: globalHotkey ?? this.globalHotkey,
      widgetVisible: widgetVisible ?? this.widgetVisible,
      widgetPositionX: widgetPositionX ?? this.widgetPositionX,
      widgetPositionY: widgetPositionY ?? this.widgetPositionY,
      widgetDhikrIds: widgetDhikrIds ?? this.widgetDhikrIds,
      themeVariant: themeVariant ?? this.themeVariant,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionEmail: subscriptionEmail ?? this.subscriptionEmail,
      lastSubscriptionPrompt:
          lastSubscriptionPrompt ?? this.lastSubscriptionPrompt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettings &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserSettings(subscriptionStatus: $subscriptionStatus, globalHotkey: $globalHotkey)';
}
