part of 'budget_bloc.dart';

sealed class BudgetState extends Equatable {
  const BudgetState();
  @override
  List<Object?> get props => [];
}

final class BudgetInitial extends BudgetState {
  const BudgetInitial();
}

final class BudgetReady extends BudgetState {
  const BudgetReady({
    required this.groups,
    required this.groupTotals,
    required this.totalIncome,
    required this.totalEssentials,
    required this.totalLifestyle,
    required this.disposableIncome,
  });

  final List<BudgetGroup> groups;

  /// Total amount per groupId.
  final Map<String, double> groupTotals;

  final double totalIncome;
  final double totalEssentials;
  final double totalLifestyle;
  final double disposableIncome;

  factory BudgetReady.fromGroups(List<BudgetGroup> groups) {
    final totals = <String, double>{};
    var income = 0.0;
    var essentials = 0.0;
    var lifestyle = 0.0;

    for (final g in groups) {
      final total = g.items.fold<double>(0.0, (sum, i) => sum + i.amount);
      totals[g.id] = total;
      switch (g.category) {
        case BudgetCategory.income:
          income += total;
          break;
        case BudgetCategory.essentials:
          essentials += total;
          break;
        case BudgetCategory.lifestyle:
          lifestyle += total;
          break;
      }
    }

    return BudgetReady(
      groups: groups,
      groupTotals: totals,
      totalIncome: income,
      totalEssentials: essentials,
      totalLifestyle: lifestyle,
      disposableIncome: income - essentials - lifestyle,
    );
  }

  @override
  List<Object?> get props => [
        groups,
        groupTotals,
        totalIncome,
        totalEssentials,
        totalLifestyle,
        disposableIncome,
      ];
}
