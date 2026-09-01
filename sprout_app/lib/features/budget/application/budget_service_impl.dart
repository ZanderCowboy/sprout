import 'package:sprout/core/constants/constants.dart';
import 'package:sprout/core/error/error.dart';

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
  Future<List<BudgetGroup>> getBudgetGroups() =>
      _repository.getBudgetGroups();

  @override
  Future<void> saveBudgetGroup(BudgetGroup group) async {
    final trimmedName = group.name.trim();
    if (trimmedName.isEmpty) {
      throw ValidationAppException(AppStrings.nameRequired);
    }
    final normalizedName = trimmedName.toLowerCase();

    for (final item in group.items) {
      if (item.amount < 0) {
        throw ValidationAppException(AppStrings.amountCannotBeNegative);
      }
    }

    final existing = await _repository.getBudgetGroups();
    final duplicate = existing.any(
      (g) => g.id != group.id && g.name.trim().toLowerCase() == normalizedName,
    );
    if (duplicate) {
      throw ValidationAppException(AppStrings.duplicateGroupName);
    }

    await _repository.upsertBudgetGroup(
      group.copyWith(name: trimmedName),
    );
  }

  @override
  Future<void> removeBudgetGroup(String id) =>
      _repository.deleteBudgetGroup(id);

  @override
  Future<void> pullRemote() => _repository.pullRemote();
}
