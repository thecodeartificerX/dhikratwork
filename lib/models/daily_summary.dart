// lib/models/daily_summary.dart
import 'package:dhikratwork/utils/constants.dart';

/// Immutable domain model for a denormalized daily rollup row.
class DailySummary {
  final int? id;
  final int dhikrId;
  final String date; // 'YYYY-MM-DD'
  final int totalCount;
  final int sessionCount;

  const DailySummary({
    this.id,
    required this.dhikrId,
    required this.date,
    this.totalCount = 0,
    this.sessionCount = 0,
  });

  factory DailySummary.fromMap(Map<String, dynamic> map) {
    return DailySummary(
      id: map[cSummaryId] as int?,
      dhikrId: map[cSummaryDhikrId] as int,
      date: map[cSummaryDate] as String,
      totalCount: map[cSummaryTotalCount] as int,
      sessionCount: map[cSummarySessionCount] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) cSummaryId: id,
      cSummaryDhikrId: dhikrId,
      cSummaryDate: date,
      cSummaryTotalCount: totalCount,
      cSummarySessionCount: sessionCount,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  DailySummary copyWith({
    int? id,
    int? dhikrId,
    String? date,
    int? totalCount,
    int? sessionCount,
  }) {
    return DailySummary(
      id: id ?? this.id,
      dhikrId: dhikrId ?? this.dhikrId,
      date: date ?? this.date,
      totalCount: totalCount ?? this.totalCount,
      sessionCount: sessionCount ?? this.sessionCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailySummary &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DailySummary(id: $id, dhikrId: $dhikrId, date: $date, totalCount: $totalCount)';
}
