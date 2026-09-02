import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import 'settings_nav_row.dart';

class SettingsFinanceSection extends StatelessWidget {
  const SettingsFinanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.finance.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        SettingsNavRow(
          identifier: SemanticsIds.settingsTransactions,
          label: AppStrings.transactions,
          icon: Icons.receipt_long_rounded,
          onTap: () => context.push(AppRoute.transactions.path),
        ),
        const SizedBox(height: 8),
        SettingsNavRow(
          identifier: SemanticsIds.settingsRecurring,
          label: AppStrings.recurringPayments,
          icon: Icons.autorenew_rounded,
          onTap: () => context.push(AppRoute.recurring.path),
        ),
        const SizedBox(height: 8),
        SettingsNavRow(
          identifier: SemanticsIds.settingsBudget,
          label: AppStrings.masterBudget,
          icon: Icons.account_balance_wallet_rounded,
          onTap: () => context.push(AppRoute.budget.path),
        ),
      ],
    );
  }
}
