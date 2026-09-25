import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/purchases/export.dart';
import 'settings_nav_row.dart';

class SettingsFinanceSection extends StatelessWidget {
  const SettingsFinanceSection({super.key});

  Future<void> _handleBudgetTap(BuildContext context) async {
    final premiumService = sl<PremiumService>();

    final canUse = await premiumService.canUsePremiumFeature(
      isPremiumFeature: true,
    );

    if (canUse) {
      if (context.mounted) {
        await context.push(AppRoute.budget.path);
      }
      return;
    }

    final canShow = await premiumService.canShowPaywall();
    if (!canShow) {
      return;
    }

    if (!context.mounted) return;

    final result = await PremiumPaywall.presentPremiumPaywall();
    if (!context.mounted) return;

    if (result == PaywallResult.purchased || result == PaywallResult.restored) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.premiumUnlocked)),
      );
      await context.push(AppRoute.budget.path);
    }
  }

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
          subtitle: AppStrings.viewAllDeposits,
          icon: Icons.receipt_long_rounded,
          onTap: () => context.push(AppRoute.transactions.path),
        ),
        const SizedBox(height: 8),
        SettingsNavRow(
          identifier: SemanticsIds.settingsRecurring,
          label: AppStrings.recurringPayments,
          subtitle: AppStrings.viewEditCancelRecurring,
          icon: Icons.autorenew_rounded,
          onTap: () => context.push(AppRoute.recurring.path),
        ),
        const SizedBox(height: 8),
        SettingsNavRow(
          identifier: SemanticsIds.settingsBudget,
          label: AppStrings.masterBudget,
          subtitle: AppStrings.planIncomeExpenses,
          icon: Icons.account_balance_wallet_rounded,
          onTap: () => _handleBudgetTap(context),
        ),
      ],
    );
  }
}
