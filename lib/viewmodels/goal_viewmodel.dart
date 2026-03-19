// lib/viewmodels/goal_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../models/goal.dart';
import '../repositories/goal_repository.dart';
import '../repositories/stats_repository.dart';

class GoalViewModel extends ChangeNotifier {
  final GoalRepository _goalRepository;
  final StatsRepository _statsRepository;

  GoalViewModel({
    required GoalRepository goalRepository,
    required StatsRepository statsRepository,
  })  : _goalRepository = goalRepository,
        _statsRepository = statsRepository;

  List<Goal> goals = [];
  Map<int, double> goalProgress = {}; // goalId -> progress 0.0-1.0
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadGoals() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _goalRepository.getActiveGoals();
      goals = List.unmodifiable(loaded);

      final progressMap = <int, double>{};
      for (final goal in loaded) {
        if (goal.id != null) {
          progressMap[goal.id!] = await calculateProgress(goal);
        }
      }
      goalProgress = Map.unmodifiable(progressMap);
    } catch (e) {
      errorMessage = 'Failed to load goals: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGoal(Goal goal) async {
    try {
      await _goalRepository.add(goal);
      await loadGoals();
    } catch (e) {
      errorMessage = 'Failed to add goal: $e';
      notifyListeners();
    }
  }

  Future<void> deleteGoal(int id) async {
    try {
      await _goalRepository.delete(id);
      await loadGoals();
    } catch (e) {
      errorMessage = 'Failed to delete goal: $e';
      notifyListeners();
    }
  }

  Future<void> deactivateGoal(int id) async {
    try {
      await _goalRepository.deactivate(id);
      await loadGoals();
    } catch (e) {
      errorMessage = 'Failed to deactivate goal: $e';
      notifyListeners();
    }
  }

  /// Returns progress [0.0, 1.0] for the given [goal] based on current period counts.
  Future<double> calculateProgress(Goal goal) async {
    if (goal.targetCount <= 0) return 0.0;

    final today = DateTime.now();
    final todayStr = '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    // Use getTotalCountForDhikr for dhikr-specific goals;
    // fall back to getTotalCountForDate for any-dhikr (null dhikrId) daily goals.
    final int count;
    if (goal.dhikrId != null) {
      count = await _statsRepository.getTotalCountForDhikr(goal.dhikrId!);
    } else {
      count = await _statsRepository.getTotalCountForDate(todayStr);
    }
    return (count / goal.targetCount).clamp(0.0, 1.0);
  }
}
