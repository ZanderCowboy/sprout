enum BudgetCategory { income, essentials, lifestyle }

extension BudgetCategoryCodec on BudgetCategory {
  static BudgetCategory fromWireName(String? name) {
    return switch (name) {
      'income' => BudgetCategory.income,
      'essentials' => BudgetCategory.essentials,
      'lifestyle' => BudgetCategory.lifestyle,
      _ => BudgetCategory.income,
    };
  }

  String get wireName => switch (this) {
        BudgetCategory.income => 'income',
        BudgetCategory.essentials => 'essentials',
        BudgetCategory.lifestyle => 'lifestyle',
      };
}

