// lib/models/dhikr_session.dart
import 'package:dhikratwork/utils/constants.dart';

/// Immutable domain model representing a single counting session.
class DhikrSession {
  final int? id;
  final int dhikrId;
  final int count;
  final String startedAt;
  final String? endedAt;
  final String source;

  const DhikrSession({
    this.id,
    required this.dhikrId,
    this.count = 0,
    required this.startedAt,
    this.endedAt,
    this.source = kSourceMainApp,
  });

  factory DhikrSession.fromMap(Map<String, dynamic> map) {
    return DhikrSession(
      id: map[cSessionId] as int?,
      dhikrId: map[cSessionDhikrId] as int,
      count: map[cSessionCount] as int,
      startedAt: map[cSessionStartedAt] as String,
      endedAt: map[cSessionEndedAt] as String?,
      source: map[cSessionSource] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) cSessionId: id,
      cSessionDhikrId: dhikrId,
      cSessionCount: count,
      cSessionStartedAt: startedAt,
      cSessionEndedAt: endedAt,
      cSessionSource: source,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  DhikrSession copyWith({
    int? id,
    int? dhikrId,
    int? count,
    String? startedAt,
    String? endedAt,
    String? source,
  }) {
    return DhikrSession(
      id: id ?? this.id,
      dhikrId: dhikrId ?? this.dhikrId,
      count: count ?? this.count,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DhikrSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DhikrSession(id: $id, dhikrId: $dhikrId, count: $count, source: $source)';
}
