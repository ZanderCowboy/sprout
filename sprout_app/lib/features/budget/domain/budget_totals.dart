import 'budget_category.dart';
import 'budget_group.dart';

class BudgetTotals {
  const BudgetTotals({
    required this.groupTotals,
    required this.totalIncome,
    required this.totalEssentials,
    required this.totalLifestyle,
    required this.disposableIncome,
  });

  final Map<String, double> groupTotals;
  final double totalIncome;
  final double totalEssentials;
  final double totalLifestyle;
  final double disposableIncome;

  factory BudgetTotals.fromGroups(List<BudgetGroup> groups) {
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
        case BudgetCategory.essentials:
          essentials += total;
        case BudgetCategory.lifestyle:
          lifestyle += total;
      }
    }

    return BudgetTotals(
      groupTotals: totals,
      totalIncome: income,
      totalEssentials: essentials,
      totalLifestyle: lifestyle,
      disposableIncome: income - essentials - lifestyle,
    );
  }
}
