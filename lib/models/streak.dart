// lib/models/streak.dart
import 'package:dhikratwork/utils/constants.dart';

/// Immutable domain model for the single-row streak tracking table.
class Streak {
  final int id; // Always kSingleRowId (1)
  final int currentStreak;
  final int longestStreak;
  final String? lastActiveDate; // 'YYYY-MM-DD' or null if never active

  const Streak({
    this.id = kSingleRowId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
  });

  factory Streak.fromMap(Map<String, dynamic> map) {
    return Streak(
      id: map[cStreakId] as int,
      currentStreak: map[cStreakCurrentStreak] as int,
      longestStreak: map[cStreakLongestStreak] as int,
      lastActiveDate: map[cStreakLastActiveDate] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      cStreakId: id,
      cStreakCurrentStreak: currentStreak,
      cStreakLongestStreak: longestStreak,
      cStreakLastActiveDate: lastActiveDate,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Streak copyWith({
    int? id,
    int? currentStreak,
    int? longestStreak,
    String? lastActiveDate,
  }) {
    return Streak(
      id: id ?? this.id,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Streak && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Streak(current: $currentStreak, longest: $longestStreak, lastActive: $lastActiveDate)';
}
