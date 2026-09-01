import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';

import '../../domain/budget_group.dart';
import '../../domain/budget_item.dart';

enum BudgetSortOption {
  asIs,
  nameAToZ,
  nameZToA,
  valueHighToLow,
  valueLowToHigh,
}

String budgetSortOptionLabel(BudgetSortOption s) {
  return switch (s) {
    BudgetSortOption.asIs => AppStrings.sortAsIs,
    BudgetSortOption.nameAToZ => AppStrings.sortNameAToZ,
    BudgetSortOption.nameZToA => AppStrings.sortNameZToA,
    BudgetSortOption.valueHighToLow => AppStrings.sortValueHighToLow,
    BudgetSortOption.valueLowToHigh => AppStrings.sortValueLowToHigh,
  };
}

IconData budgetSortOptionIcon(BudgetSortOption s) {
  return switch (s) {
    BudgetSortOption.asIs => Icons.sort_rounded,
    BudgetSortOption.nameAToZ => Icons.text_fields_rounded,
    BudgetSortOption.nameZToA => Icons.text_fields_rounded,
    BudgetSortOption.valueHighToLow => Icons.trending_up_rounded,
    BudgetSortOption.valueLowToHigh => Icons.trending_down_rounded,
  };
}

int _toCents(double amount) => (amount * 100).round();

List<BudgetGroup> sortBudgetGroups(
  List<BudgetGroup> input,
  BudgetSortOption sort,
) {
  if (sort == BudgetSortOption.asIs) return input;

  final indexed = input.asMap().entries.toList();
  indexed.sort((a, b) {
    final va = a.value;
    final vb = b.value;

    int byPrimary = 0;
    switch (sort) {
      case BudgetSortOption.nameAToZ:
        byPrimary = va.name.trim().toLowerCase().compareTo(
          vb.name.trim().toLowerCase(),
        );
        break;
      case BudgetSortOption.nameZToA:
        byPrimary = vb.name.trim().toLowerCase().compareTo(
          va.name.trim().toLowerCase(),
        );
        break;
      case BudgetSortOption.valueHighToLow:
        byPrimary = _toCents(
          vb.totalAmount,
        ).compareTo(_toCents(va.totalAmount));
        break;
      case BudgetSortOption.valueLowToHigh:
        byPrimary = _toCents(
          va.totalAmount,
        ).compareTo(_toCents(vb.totalAmount));
        break;
      case BudgetSortOption.asIs:
        byPrimary = 0;
        break;
    }

    if (byPrimary != 0) return byPrimary;
    // Preserve original relative ordering deterministically.
    return a.key.compareTo(b.key);
  });

  return indexed.map((e) => e.value).toList();
}

List<BudgetItem> sortBudgetItems(
  List<BudgetItem> input,
  BudgetSortOption sort,
) {
  if (sort == BudgetSortOption.asIs) return input;

  final indexed = input.asMap().entries.toList();
  indexed.sort((a, b) {
    final va = a.value;
    final vb = b.value;

    int byPrimary = 0;
    switch (sort) {
      case BudgetSortOption.nameAToZ:
        byPrimary = va.name.trim().toLowerCase().compareTo(
          vb.name.trim().toLowerCase(),
        );
        break;
      case BudgetSortOption.nameZToA:
        byPrimary = vb.name.trim().toLowerCase().compareTo(
          va.name.trim().toLowerCase(),
        );
        break;
      case BudgetSortOption.valueHighToLow:
        byPrimary = _toCents(vb.amount).compareTo(_toCents(va.amount));
        break;
      case BudgetSortOption.valueLowToHigh:
        byPrimary = _toCents(va.amount).compareTo(_toCents(vb.amount));
        break;
      case BudgetSortOption.asIs:
        byPrimary = 0;
        break;
    }

    if (byPrimary != 0) return byPrimary;
    // Preserve original relative ordering deterministically.
    return a.key.compareTo(b.key);
  });

  return indexed.map((e) => e.value).toList();
}
