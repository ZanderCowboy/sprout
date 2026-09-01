import 'package:sprout/core/constants/constants.dart';
import 'package:sprout/core/error/error.dart';
import 'package:sprout/core/utils/unique_name.dart';

import '../domain/budget_group.dart';
import '../domain/budget_repository.dart';
import 'budget_service.dart';

class BudgetServiceImpl implements BudgetService {
  BudgetServiceImpl(this._repository);

  final BudgetRepository _repository;

  @override
  Stream<List<BudgetGroup>> watchBudgetGroups() =>
      _repository.watchBudgetGroups();

  @override
  Future<List<BudgetGroup>> getBudgetGroups() => _repository.getBudgetGroups();

  @override
  Future<void> saveBudgetGroup(BudgetGroup group) async {
    final trimmedName = group.name.trim();
    if (trimmedName.isEmpty) {
      throw ValidationAppException(AppStrings.nameRequired);
    }

    for (final item in group.items) {
      if (item.amount < 0) {
        throw ValidationAppException(AppStrings.amountCannotBeNegative);
      }
    }

    final existing = await _repository.getBudgetGroups();
    final duplicate = UniqueName.isTaken(
      existing: existing.map((g) => (id: g.id, name: g.name)),
      candidateName: trimmedName,
      excludeId: group.id,
    );
    if (duplicate) {
      throw ValidationAppException(AppStrings.duplicateGroupName);
    }

    await _repository.upsertBudgetGroup(group.copyWith(name: trimmedName));
  }

  @override
  Future<void> removeBudgetGroup(String id) =>
      _repository.deleteBudgetGroup(id);

  @override
  Future<void> pullRemote() => _repository.pullRemote();
}
