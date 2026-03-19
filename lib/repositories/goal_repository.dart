// lib/repositories/goal_repository.dart
import 'package:dhikratwork/models/goal.dart';
import 'package:dhikratwork/services/database_service.dart';
import 'package:dhikratwork/utils/constants.dart';

/// Repository for [Goal] data. Acts as the Single Source of Truth for all
/// user-defined dhikr goals. ViewModels never touch [DatabaseService] directly.
class GoalRepository {
  GoalRepository(this._db);

  final DatabaseService _db;

  // -------------------------------------------------------------------------
  // getAll
  // -------------------------------------------------------------------------

  /// Returns all [Goal] rows, regardless of [is_active] status.
  Future<List<Goal>> getAll() async {
    final rows = await _db.query(tGoal, orderBy: '$cGoalCreatedAt ASC');
    return List.unmodifiable(rows.map(Goal.fromMap).toList());
  }

  // -------------------------------------------------------------------------
  // getById
  // -------------------------------------------------------------------------

  /// Returns the [Goal] with [id], or `null` if not found.
  Future<Goal?> getById(int id) async {
    final rows = await _db.query(
      tGoal,
      where: '$cGoalId = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Goal.fromMap(rows.first);
  }

  // -------------------------------------------------------------------------
  // add
  // -------------------------------------------------------------------------

  /// Inserts [goal] into the database and returns the auto-assigned row id.
  Future<int> add(Goal goal) async {
    return _db.insert(tGoal, goal.toMap());
  }

  // -------------------------------------------------------------------------
  // update
  // -------------------------------------------------------------------------

  /// Replaces all mutable fields for [goal.id] with the values in [goal].
  /// [goal.id] must be non-null.
  Future<void> update(Goal goal) async {
    assert(goal.id != null, 'GoalRepository.update: goal.id must not be null');
    await _db.update(
      tGoal,
      goal.toMap(),
      where: '$cGoalId = ?',
      whereArgs: [goal.id],
    );
  }

  // -------------------------------------------------------------------------
  // delete
  // -------------------------------------------------------------------------

  /// Permanently removes the [Goal] row with [id].
  Future<void> delete(int id) async {
    await _db.delete(
      tGoal,
      where: '$cGoalId = ?',
      whereArgs: [id],
    );
  }

  // -------------------------------------------------------------------------
  // deactivate
  // -------------------------------------------------------------------------

  /// Sets [is_active] = 0 for the [Goal] with [id], keeping the row for
  /// historical reference. Prefer this over [delete] for user-created goals.
  Future<void> deactivate(int id) async {
    await _db.update(
      tGoal,
      {cGoalIsActive: 0},
      where: '$cGoalId = ?',
      whereArgs: [id],
    );
  }

  // -------------------------------------------------------------------------
  // getActiveGoals
  // -------------------------------------------------------------------------

  /// Returns all [Goal] rows where [is_active] = 1.
  Future<List<Goal>> getActiveGoals() async {
    final rows = await _db.query(
      tGoal,
      where: '$cGoalIsActive = ?',
      whereArgs: [1],
      orderBy: '$cGoalCreatedAt ASC',
    );
    return List.unmodifiable(rows.map(Goal.fromMap).toList());
  }

  // -------------------------------------------------------------------------
  // getGoalsForDhikr
  // -------------------------------------------------------------------------

  /// Returns all [Goal] rows whose [dhikr_id] matches [dhikrId].
  /// Does not include "any-dhikr" goals (where dhikr_id IS NULL).
  Future<List<Goal>> getGoalsForDhikr(int dhikrId) async {
    final rows = await _db.query(
      tGoal,
      where: '$cGoalDhikrId = ?',
      whereArgs: [dhikrId],
      orderBy: '$cGoalCreatedAt ASC',
    );
    return List.unmodifiable(rows.map(Goal.fromMap).toList());
  }
}
