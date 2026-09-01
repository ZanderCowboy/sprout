import 'package:sprout/core/constants/constants.dart';
import 'package:sprout/core/error/error.dart';
import 'package:sprout/core/utils/unique_name.dart';
import 'package:sprout/features/transactions/application/transactions_service.dart';
import 'package:sprout/features/transactions/domain/transaction_frequency.dart';

import '../domain/goal.dart';
import '../domain/goals_repository.dart';
import 'goals_service.dart';

class GoalsServiceImpl implements GoalsService {
  GoalsServiceImpl(this._repository, this._transactionsService);

  final GoalsRepository _repository;
  final TransactionsService _transactionsService;

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
    final duplicate = UniqueName.isTaken(
      existing: existing.map((g) => (id: g.id, name: g.name)),
      candidateName: goal.name,
      excludeId: goal.id,
    );
    if (duplicate) {
      throw ValidationAppException(AppStrings.duplicateGoalName);
    }
    await _repository.upsertGoal(goal);
  }

  @override
  Future<void> removeGoal(String id) => _repository.deleteGoal(id);

  @override
  Future<Goal> createGoalWithOpeningBalance({
    required Goal goal,
    required int openingBalanceCents,
    String? openingBalanceAccountId,
    required String groupId,
    DateTime? occurredAt,
  }) async {
    await saveGoal(goal);

    if (openingBalanceCents <= 0) return goal;

    if (openingBalanceAccountId == null || openingBalanceAccountId.isEmpty) {
      throw ValidationAppException(AppStrings.pickAccountForOpeningBalance);
    }

    final when = occurredAt ?? DateTime.now();
    const note = AppStrings.openingBalance;

    await _transactionsService.recordAccountDeposit(
      accountId: openingBalanceAccountId,
      groupId: groupId,
      amountCents: openingBalanceCents,
      occurredAt: when,
      note: note,
      isRecurring: false,
      frequency: TransactionFrequency.none,
    );
    await _transactionsService.recordAllocation(
      accountId: openingBalanceAccountId,
      goalId: goal.id,
      groupId: groupId,
      amountCents: openingBalanceCents,
      occurredAt: when,
      note: note,
    );

    return goal;
  }

  @override
  Future<void> pullRemote() => _repository.pullRemote();
}
