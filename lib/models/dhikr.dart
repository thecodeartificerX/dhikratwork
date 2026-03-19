// lib/models/dhikr.dart
import 'package:dhikratwork/utils/constants.dart';

/// Immutable domain model representing a single dhikr definition.
class Dhikr {
  final int? id;
  final String name;
  final String arabicText;
  final String transliteration;
  final String translation;
  final String category;
  final String? hadithReference;
  final bool isPreloaded;
  final bool isHidden;
  final int? targetCount;
  final int sortOrder;
  final String createdAt;

  const Dhikr({
    this.id,
    required this.name,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    required this.category,
    this.hadithReference,
    this.isPreloaded = false,
    this.isHidden = false,
    this.targetCount,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory Dhikr.fromMap(Map<String, dynamic> map) {
    return Dhikr(
      id: map[cDhikrId] as int?,
      name: map[cDhikrName] as String,
      arabicText: map[cDhikrArabicText] as String,
      transliteration: map[cDhikrTransliteration] as String,
      translation: map[cDhikrTranslation] as String,
      category: map[cDhikrCategory] as String,
      hadithReference: map[cDhikrHadithReference] as String?,
      isPreloaded: (map[cDhikrIsPreloaded] as int) == 1,
      isHidden: (map[cDhikrIsHidden] as int) == 1,
      targetCount: map[cDhikrTargetCount] as int?,
      sortOrder: map[cDhikrSortOrder] as int,
      createdAt: map[cDhikrCreatedAt] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) cDhikrId: id,
      cDhikrName: name,
      cDhikrArabicText: arabicText,
      cDhikrTransliteration: transliteration,
      cDhikrTranslation: translation,
      cDhikrCategory: category,
      cDhikrHadithReference: hadithReference,
      cDhikrIsPreloaded: isPreloaded ? 1 : 0,
      cDhikrIsHidden: isHidden ? 1 : 0,
      cDhikrTargetCount: targetCount,
      cDhikrSortOrder: sortOrder,
      cDhikrCreatedAt: createdAt,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Dhikr copyWith({
    int? id,
    String? name,
    String? arabicText,
    String? transliteration,
    String? translation,
    String? category,
    String? hadithReference,
    bool? isPreloaded,
    bool? isHidden,
    int? targetCount,
    int? sortOrder,
    String? createdAt,
  }) {
    return Dhikr(
      id: id ?? this.id,
      name: name ?? this.name,
      arabicText: arabicText ?? this.arabicText,
      transliteration: transliteration ?? this.transliteration,
      translation: translation ?? this.translation,
      category: category ?? this.category,
      hadithReference: hadithReference ?? this.hadithReference,
      isPreloaded: isPreloaded ?? this.isPreloaded,
      isHidden: isHidden ?? this.isHidden,
      targetCount: targetCount ?? this.targetCount,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Dhikr && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Dhikr(id: $id, name: $name, category: $category)';
}
