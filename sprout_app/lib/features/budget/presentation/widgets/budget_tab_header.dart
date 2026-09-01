import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';

class BudgetTabHeader extends StatelessWidget {
  const BudgetTabHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        tabs: [
          Tab(
            height: 42,
            child: Semantics(
              identifier: SemanticsIds.budgetTabIncome,
              button: true,
              label: AppStrings.budgetIncome,
              child: const Text(AppStrings.budgetIncome),
            ),
          ),
          Tab(
            height: 42,
            child: Semantics(
              identifier: SemanticsIds.budgetTabEssentials,
              button: true,
              label: AppStrings.budgetEssentials,
              child: const Text(AppStrings.budgetEssentials),
            ),
          ),
          Tab(
            height: 42,
            child: Semantics(
              identifier: SemanticsIds.budgetTabLifestyle,
              button: true,
              label: AppStrings.budgetLifestyle,
              child: const Text(AppStrings.budgetLifestyle),
            ),
          ),
        ],
      ),
    );
  }
}
