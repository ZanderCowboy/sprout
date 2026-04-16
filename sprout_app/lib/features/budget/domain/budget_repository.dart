import 'budget_group.dart';

abstract class BudgetRepository {
  Stream<List<BudgetGroup>> watchBudgetGroups();

  Future<List<BudgetGroup>> getBudgetGroups();

  Future<void> upsertBudgetGroup(BudgetGroup group);

  Future<void> deleteBudgetGroup(String id);

  Future<void> pullRemote();
}

