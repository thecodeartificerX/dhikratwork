// lib/models/achievement.dart
import 'package:dhikratwork/utils/constants.dart';

/// Immutable domain model for a gamification achievement.
/// [unlockedAt] is null when the achievement is still locked.
class Achievement {
  final int? id;
  final String key;
  final String name;
  final String description;
  final String iconAsset;
  final String? unlockedAt;

  const Achievement({
    this.id,
    required this.key,
    required this.name,
    required this.description,
    required this.iconAsset,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map[cAchievementId] as int?,
      key: map[cAchievementKey] as String,
      name: map[cAchievementName] as String,
      description: map[cAchievementDescription] as String,
      iconAsset: map[cAchievementIconAsset] as String,
      unlockedAt: map[cAchievementUnlockedAt] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) cAchievementId: id,
      cAchievementKey: key,
      cAchievementName: name,
      cAchievementDescription: description,
      cAchievementIconAsset: iconAsset,
      cAchievementUnlockedAt: unlockedAt,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Achievement copyWith({
    int? id,
    String? key,
    String? name,
    String? description,
    String? iconAsset,
    String? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      key: key ?? this.key,
      name: name ?? this.name,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Achievement &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() =>
      'Achievement(key: $key, name: $name, isUnlocked: $isUnlocked)';
}
