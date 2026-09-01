import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';

class BudgetTabHeader extends StatelessWidget {
  const BudgetTabHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      child: TabBar(
        tabs: [
          Tab(
            height: 42,
            child: Semantics(
              identifier: SemanticsIds.budgetTabIncome,
              button: true,
              label: AppStrings.budgetIncome,
              child: Text(AppStrings.budgetIncome),
            ),
          ),
          Tab(
            height: 42,
            child: Semantics(
              identifier: SemanticsIds.budgetTabEssentials,
              button: true,
              label: AppStrings.budgetEssentials,
              child: Text(AppStrings.budgetEssentials),
            ),
          ),
          Tab(
            height: 42,
            child: Semantics(
              identifier: SemanticsIds.budgetTabLifestyle,
              button: true,
              label: AppStrings.budgetLifestyle,
              child: Text(AppStrings.budgetLifestyle),
            ),
          ),
        ],
      ),
    );
  }
}
