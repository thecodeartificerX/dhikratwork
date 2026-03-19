// lib/viewmodels/gamification_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../models/achievement.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/streak_repository.dart';

class GamificationViewModel extends ChangeNotifier {
  final AchievementRepository _achievementRepository;
  final StreakRepository _streakRepository;

  GamificationViewModel({
    required AchievementRepository achievementRepository,
    required StreakRepository streakRepository,
  })  : _achievementRepository = achievementRepository,
        _streakRepository = streakRepository;

  static const List<int> _levelThresholds = [
    100, 250, 500, 1000, 2000, 4000, 8000, 16000, 32000,
  ];

  static const List<String> _levelNames = [
    'Beginner',
    'Consistent',
    'Devoted',
    'Steadfast',
    'Persevering',
    'Dedicated',
    'Resolute',
    'Unwavering',
    'Muhsin',
  ];

  int totalXp = 0;
  int currentLevel = 0;
  int currentStreak = 0;
  int longestStreak = 0;
  List<Achievement> achievements = [];
  bool isLoading = false;
  String? errorMessage;

  String get levelName => _levelNames[currentLevel.clamp(0, _levelNames.length - 1)];

  int get xpForNextLevel {
    if (currentLevel >= _levelThresholds.length) return _levelThresholds.last;
    return _levelThresholds[currentLevel];
  }

  double get xpProgress => computeXpProgress(totalXp: totalXp, level: currentLevel);

  Future<void> loadGamification() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final streak = await _streakRepository.getStreak();
      final allAchievements = await _achievementRepository.getAll();

      // XP is retained from last checkAndUnlockAchievements call.
      currentLevel = calculateLevel(totalXp);
      currentStreak = streak.currentStreak;
      longestStreak = streak.longestStreak;
      achievements = List.unmodifiable(allAchievements);
    } catch (e) {
      errorMessage = 'Failed to load gamification data: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Checks ALL achievement conditions in a single pass and unlocks any that
  /// are newly satisfied. Called after every count increment.
  Future<void> checkAndUnlockAchievements({
    required int totalCount,
    required int streakDays,
  }) async {
    // getUnlocked() returns List<Achievement>; extract keys for lookup.
    final unlockedAchievements = await _achievementRepository.getUnlocked();
    final unlockedKeys = unlockedAchievements.map((a) => a.key).toSet();

    Future<void> check(String key, bool condition) async {
      if (condition && !unlockedKeys.contains(key)) {
        await _achievementRepository.unlock(key);
        unlockedKeys.add(key);
      }
    }

    // Count-based achievements
    await check('first_dhikr', totalCount >= 1);
    await check('count_100', totalCount >= 100);
    await check('count_1000', totalCount >= 1000);
    await check('count_10000', totalCount >= 10000);
    await check('count_100000', totalCount >= 100000);

    // Streak-based achievements
    await check('streak_3', streakDays >= 3);
    await check('streak_7', streakDays >= 7);
    await check('streak_30', streakDays >= 30);
    await check('streak_100', streakDays >= 100);

    // XP = totalCount (1 XP per press)
    totalXp = totalCount;
    currentLevel = calculateLevel(totalXp);
    achievements = List.unmodifiable(await _achievementRepository.getAll());
    notifyListeners();
  }

  /// Returns the level index (0–8) for the given [xp].
  /// There are 9 levels (0 = Beginner, 8 = Muhsin). Each level is entered
  /// when XP reaches the corresponding threshold in [_levelThresholds].
  int calculateLevel(int xp) {
    int level = 0;
    for (final threshold in _levelThresholds) {
      if (xp >= threshold) {
        level++;
      } else {
        break;
      }
    }
    // Max level is _levelNames.length - 1 (= 8 = Muhsin).
    return level.clamp(0, _levelNames.length - 1);
  }

  /// Computes XP progress (0.0–1.0) within the current level band.
  /// At max level (Muhsin = level 8), progress is always 1.0.
  double computeXpProgress({required int totalXp, required int level}) {
    // Max level index is _levelNames.length - 1 (= 8 = Muhsin).
    final int maxLevel = _levelNames.length - 1;
    if (level >= maxLevel) return 1.0;

    final int levelStart = level == 0 ? 0 : _levelThresholds[level - 1];
    final int levelEnd = _levelThresholds[level];
    final int band = levelEnd - levelStart;
    if (band <= 0) return 1.0;

    return ((totalXp - levelStart) / band).clamp(0.0, 1.0);
  }
}
