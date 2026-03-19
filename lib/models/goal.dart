// lib/models/goal.dart
import 'package:dhikratwork/utils/constants.dart';

/// Immutable domain model for a user-defined dhikr goal.
class Goal {
  final int? id;
  final int? dhikrId; // null means "any dhikr"
  final int targetCount;
  final String period; // kPeriodDaily | kPeriodWeekly | kPeriodMonthly
  final bool isActive;
  final String createdAt;

  const Goal({
    this.id,
    this.dhikrId,
    required this.targetCount,
    required this.period,
    this.isActive = true,
    required this.createdAt,
  });

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map[cGoalId] as int?,
      dhikrId: map[cGoalDhikrId] as int?,
      targetCount: map[cGoalTargetCount] as int,
      period: map[cGoalPeriod] as String,
      isActive: (map[cGoalIsActive] as int) == 1,
      createdAt: map[cGoalCreatedAt] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) cGoalId: id,
      cGoalDhikrId: dhikrId,
      cGoalTargetCount: targetCount,
      cGoalPeriod: period,
      cGoalIsActive: isActive ? 1 : 0,
      cGoalCreatedAt: createdAt,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Goal copyWith({
    int? id,
    int? dhikrId,
    int? targetCount,
    String? period,
    bool? isActive,
    String? createdAt,
  }) {
    return Goal(
      id: id ?? this.id,
      dhikrId: dhikrId ?? this.dhikrId,
      targetCount: targetCount ?? this.targetCount,
      period: period ?? this.period,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Goal && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Goal(id: $id, dhikrId: $dhikrId, targetCount: $targetCount, period: $period)';
}
