import '../domain/goal.dart';

/// Goal use-cases: validation and persist/delete/pull.
abstract class GoalsService {
  /// Emits goals whenever local data changes.
  Stream<List<Goal>> watchGoals();

  /// Returns the current goals from local storage.
  Future<List<Goal>> getGoals();

  /// Saves [goal] after validating target amount and unique name.
  ///
  /// Throws [ValidationAppException] if target is not positive or name is taken.
  Future<void> saveGoal(Goal goal);

  /// Deletes the goal with [id] locally and enqueues remote sync.
  Future<void> removeGoal(String id);

  /// Pulls goals from Supabase when sync is allowed.
  Future<void> pullRemote();
}
