import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/ui/export.dart';

class OverviewQuickActions extends StatelessWidget {
  const OverviewQuickActions({
    super.key,
    required this.depositIdentifier,
    required this.accountIdentifier,
    required this.goalIdentifier,
    required this.onDeposit,
    required this.onNewAccount,
    required this.onNewGoal,
    this.depositEnabled = true,
    this.depositKey,
    this.accountKey,
    this.goalKey,
  });

  final String depositIdentifier;
  final String accountIdentifier;
  final String goalIdentifier;
  final VoidCallback onDeposit;
  final VoidCallback onNewAccount;
  final VoidCallback onNewGoal;
  final bool depositEnabled;
  final Key? depositKey;
  final Key? accountKey;
  final Key? goalKey;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SproutQuickActionTile(
              key: depositKey,
              identifier: depositIdentifier,
              label: AppStrings.deposit,
              icon: Icons.arrow_downward_rounded,
              iconColor: AppColors.seed,
              onTap: onDeposit,
              enabled: depositEnabled,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SproutQuickActionTile(
              key: accountKey,
              identifier: accountIdentifier,
              label: AppStrings.newAccount,
              icon: Icons.account_balance_wallet_outlined,
              iconColor: AppColors.accentViolet,
              onTap: onNewAccount,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SproutQuickActionTile(
              key: goalKey,
              identifier: goalIdentifier,
              label: AppStrings.newGoal,
              icon: Icons.flag_outlined,
              iconColor: AppColors.accentCoral,
              onTap: onNewGoal,
            ),
          ),
        ],
      ),
    );
  }
}
