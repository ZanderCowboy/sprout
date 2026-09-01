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
    final totals = BudgetTotals.fromGroups(groups);
    return BudgetReady(
      groups: groups,
      groupTotals: totals.groupTotals,
      totalIncome: totals.totalIncome,
      totalEssentials: totals.totalEssentials,
      totalLifestyle: totals.totalLifestyle,
      disposableIncome: totals.disposableIncome,
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
