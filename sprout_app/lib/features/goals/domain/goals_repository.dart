import 'goal.dart';

abstract class GoalsRepository {
  Stream<List<Goal>> watchGoals();
  Future<List<Goal>> getGoals();
  Future<void> upsertGoal(Goal goal);
  Future<void> deleteGoal(String id);
  Future<void> pullRemote();
}
