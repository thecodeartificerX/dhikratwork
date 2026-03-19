// test/fakes/fake_achievement_repository.dart
import 'package:dhikratwork/models/achievement.dart';
import 'package:dhikratwork/repositories/achievement_repository.dart';
import 'package:dhikratwork/utils/constants.dart';

/// In-memory fake of [AchievementRepository] for use in ViewModel and View
/// tests. Pre-populated with the same achievement keys as the real seed data.
// ignore: subtype_of_sealed_class
class FakeAchievementRepository implements AchievementRepository {
  // Build the fake store from well-known achievement keys so tests
  // that call getAll() get a realistic list without touching sqflite.
  final Map<String, Achievement> _store = {
    for (final entry in _kSeedAchievements.entries)
      entry.key: Achievement(
        id: entry.value.$1,
        key: entry.key,
        name: entry.value.$2,
        description: entry.value.$3,
        iconAsset: 'assets/achievements/${entry.key}.png',
        unlockedAt: null,
      ),
  };

  @override
  Future<List<Achievement>> getAll() async =>
      List.unmodifiable(_store.values.toList());

  @override
  Future<List<Achievement>> getUnlocked() async {
    final result =
        _store.values.where((a) => a.unlockedAt != null).toList();
    return List.unmodifiable(result);
  }

  @override
  Future<List<Achievement>> getLocked() async {
    final result =
        _store.values.where((a) => a.unlockedAt == null).toList();
    return List.unmodifiable(result);
  }

  @override
  Future<void> unlock(String key) async {
    final existing = _store[key];
    if (existing == null || existing.unlockedAt != null) return;
    _store[key] = Achievement(
      id: existing.id,
      key: existing.key,
      name: existing.name,
      description: existing.description,
      iconAsset: existing.iconAsset,
      unlockedAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<bool> isUnlocked(String key) async =>
      _store[key]?.unlockedAt != null;

  /// Test helper — force a specific achievement to locked state.
  void lock(String key) {
    final existing = _store[key];
    if (existing == null) return;
    _store[key] = Achievement(
      id: existing.id,
      key: existing.key,
      name: existing.name,
      description: existing.description,
      iconAsset: existing.iconAsset,
      unlockedAt: null,
    );
  }

  /// Test helper — clear all unlocks (reset to fully locked state).
  void resetAll() {
    for (final key in _store.keys) {
      lock(key);
    }
  }
}

// Minimal seed map mirroring the achievement constants in constants.dart.
// (id, name, description)
const Map<String, (int, String, String)> _kSeedAchievements = {
  kAchFirstDhikr:   (1,  'First Dhikr',           'Complete your first dhikr count'),
  kAchCount100:     (2,  '100 Counts',             'Reach 100 total dhikr counts'),
  kAchCount1000:    (3,  '1,000 Counts',           'Reach 1,000 total dhikr counts'),
  kAchCount10000:   (4,  '10,000 Counts',          'Reach 10,000 total dhikr counts'),
  kAchCount100000:  (5,  '100,000 Counts',         'Reach 100,000 total dhikr counts'),
  kAchStreak3:      (6,  '3-Day Streak',           'Maintain a 3-day dhikr streak'),
  kAchStreak7:      (7,  '7-Day Streak',           'Maintain a 7-day dhikr streak'),
  kAchStreak30:     (8,  '30-Day Streak',          'Maintain a 30-day dhikr streak'),
  kAchStreak100:    (9,  '100-Day Streak',         'Maintain a 100-day dhikr streak'),
  kAchGoalFirst:    (10, 'First Goal',             'Create your first dhikr goal'),
  kAchGoalComplete: (11, 'Goal Completed',         'Complete a dhikr goal'),
  kAchCustomDhikr:  (12, 'Custom Dhikr',           'Add a custom dhikr to your library'),
  kAchAllCategories:(13, 'All Categories',         'Count dhikr from every category'),
};
