// test/fakes/fake_goal_repository.dart
import 'package:dhikratwork/models/goal.dart';
import 'package:dhikratwork/repositories/goal_repository.dart';

/// In-memory fake of [GoalRepository] for use in ViewModel and View tests.
// ignore: subtype_of_sealed_class
class FakeGoalRepository implements GoalRepository {
  final Map<int, Goal> _store = {};
  int _nextId = 1;

  @override
  Future<List<Goal>> getAll() async =>
      List.unmodifiable(_store.values.toList());

  @override
  Future<Goal?> getById(int id) async => _store[id];

  @override
  Future<int> add(Goal goal) async {
    final id = _nextId++;
    _store[id] = Goal(
      id: id,
      dhikrId: goal.dhikrId,
      targetCount: goal.targetCount,
      period: goal.period,
      isActive: goal.isActive,
      createdAt: goal.createdAt,
    );
    return id;
  }

  @override
  Future<void> update(Goal goal) async {
    assert(goal.id != null);
    _store[goal.id!] = goal;
  }

  @override
  Future<void> delete(int id) async => _store.remove(id);

  @override
  Future<void> deactivate(int id) async {
    final existing = _store[id];
    if (existing == null) return;
    _store[id] = Goal(
      id: existing.id,
      dhikrId: existing.dhikrId,
      targetCount: existing.targetCount,
      period: existing.period,
      isActive: false,
      createdAt: existing.createdAt,
    );
  }

  @override
  Future<List<Goal>> getActiveGoals() async {
    final result = _store.values.where((g) => g.isActive).toList();
    return List.unmodifiable(result);
  }

  @override
  Future<List<Goal>> getGoalsForDhikr(int dhikrId) async {
    final result =
        _store.values.where((g) => g.dhikrId == dhikrId).toList();
    return List.unmodifiable(result);
  }

  /// Test helper — seed a pre-built goal directly.
  void seed(Goal goal) {
    assert(goal.id != null, 'FakeGoalRepository.seed: goal.id must not be null');
    _store[goal.id!] = goal;
  }

  /// Test helper — clear all data.
  void clear() => _store.clear();
}
