import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/features/budget/domain/budget_category.dart';
import 'package:sprout/features/budget/domain/budget_group.dart';
import 'package:sprout/features/budget/domain/budget_item.dart';
import 'package:sprout/features/budget/domain/budget_totals.dart';

void main() {
  test('BudgetTotals.fromGroups sums categories and disposable income', () {
    final groups = [
      BudgetGroup(
        id: 'income',
        userId: 'u',
        name: 'Income',
        description: null,
        colorHex: '#FF000000',
        iconCodePoint: null,
        iconFontFamily: null,
        category: BudgetCategory.income,
        items: [
          const BudgetItem(id: 'i1', name: 'Salary', amount: 10000),
        ],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
      BudgetGroup(
        id: 'ess',
        userId: 'u',
        name: 'Essentials',
        description: null,
        colorHex: '#FF000000',
        iconCodePoint: null,
        iconFontFamily: null,
        category: BudgetCategory.essentials,
        items: [
          const BudgetItem(id: 'e1', name: 'Rent', amount: 4000),
        ],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
      BudgetGroup(
        id: 'life',
        userId: 'u',
        name: 'Lifestyle',
        description: null,
        colorHex: '#FF000000',
        iconCodePoint: null,
        iconFontFamily: null,
        category: BudgetCategory.lifestyle,
        items: [
          const BudgetItem(id: 'l1', name: 'Fun', amount: 1000),
        ],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ];

    final totals = BudgetTotals.fromGroups(groups);

    expect(totals.totalIncome, 10000);
    expect(totals.totalEssentials, 4000);
    expect(totals.totalLifestyle, 1000);
    expect(totals.disposableIncome, 5000);
    expect(totals.groupTotals['income'], 10000);
  });
}
