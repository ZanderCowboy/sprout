import '../domain/budget_group.dart';

/// Budget group use-cases: validation and persist/delete/pull.
abstract class BudgetService {
  /// Emits budget groups whenever local data changes.
  Stream<List<BudgetGroup>> watchBudgetGroups();

  /// Returns the current budget groups from local storage.
  Future<List<BudgetGroup>> getBudgetGroups();

  /// Saves [group] after validating name and item amounts.
  ///
  /// Throws [ValidationAppException] on empty name, negative amounts, or
  /// duplicate group name.
  Future<void> saveBudgetGroup(BudgetGroup group);

  /// Deletes the budget group with [id] locally and enqueues remote sync.
  Future<void> removeBudgetGroup(String id);

  /// Pulls budget groups from Supabase when sync is allowed.
  Future<void> pullRemote();
}
