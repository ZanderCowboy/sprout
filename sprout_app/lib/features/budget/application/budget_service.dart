import 'package:sprout/core/constants/constants.dart';
import 'package:sprout/core/error/error.dart';

import '../domain/budget_group.dart';
import '../domain/budget_repository.dart';

class BudgetService {
  BudgetService(this._repository);

  final BudgetRepository _repository;

  Stream<List<BudgetGroup>> watchBudgetGroups() => _repository.watchBudgetGroups();

  Future<List<BudgetGroup>> getBudgetGroups() => _repository.getBudgetGroups();

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
      // Reuse existing copy since Sprout already has a message.
      throw ValidationAppException(AppStrings.duplicateAccountName);
    }

    await _repository.upsertBudgetGroup(
      group.copyWith(name: trimmedName),
    );
  }

  Future<void> removeBudgetGroup(String id) => _repository.deleteBudgetGroup(id);

  Future<void> pullRemote() => _repository.pullRemote();
}

