import 'package:sprout/core/constants/constants.dart';
import 'package:sprout/core/error/error.dart';

import '../domain/goal.dart';
import '../domain/goals_repository.dart';
import 'goals_service.dart';

class GoalsServiceImpl implements GoalsService {
  GoalsServiceImpl(this._repository);

  final GoalsRepository _repository;

  @override
  Stream<List<Goal>> watchGoals() => _repository.watchGoals();

  @override
  Future<List<Goal>> getGoals() => _repository.getGoals();

  @override
  Future<void> saveGoal(Goal goal) async {
    if (goal.targetAmountCents <= 0) {
      throw ValidationAppException(AppStrings.goalTargetMustBePositive);
    }
    final existing = await _repository.getGoals();
    final normalized = goal.name.trim().toLowerCase();
    final duplicate = existing.any(
      (g) => g.id != goal.id && g.name.trim().toLowerCase() == normalized,
    );
    if (duplicate) {
      throw ValidationAppException(AppStrings.duplicateGoalName);
    }
    await _repository.upsertGoal(goal);
  }

  @override
  Future<void> removeGoal(String id) => _repository.deleteGoal(id);

  @override
  Future<void> pullRemote() => _repository.pullRemote();
}
