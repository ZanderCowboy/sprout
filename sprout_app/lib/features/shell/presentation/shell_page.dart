import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/connectivity/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/ui/export.dart';
import 'deposit_bottom_sheet.dart';
import 'widgets/shell_tab_item.dart';

class ShellPage extends StatelessWidget {
  const ShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _openActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.sheetTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SproutListTile(
                  identifier: SemanticsIds.shellActionNewAccount,
                  label: AppStrings.newAccount,
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text(AppStrings.newAccount),
                  onTap: () {
                    Navigator.pop(ctx);
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => AccountFormSheet(
                        defaultColor: AppColors.cardColorAt(0),
                      ),
                    );
                  },
                ),
                SproutListTile(
                  identifier: SemanticsIds.shellActionNewGoal,
                  label: AppStrings.newGoal,
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text(AppStrings.newGoal),
                  onTap: () {
                    Navigator.pop(ctx);
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => CreateGoalScreen(
                        defaultColor: AppColors.cardColorAt(1),
                      ),
                    );
                  },
                ),
                SproutListTile(
                  identifier: SemanticsIds.shellActionDeposit,
                  label: AppStrings.deposit,
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text(AppStrings.deposit),
                  onTap: () {
                    Navigator.pop(ctx);
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => const DepositBottomSheet(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageIndex = navigationShell.currentIndex;

    return BlocBuilder<ConnectivityCubit, bool>(
      builder: (context, online) {
        return Scaffold(
          body: Column(
            children: [
              if (!online)
                Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 20,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppStrings.offline,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(child: SafeArea(bottom: false, child: navigationShell)),
            ],
          ),
          bottomNavigationBar: Material(
            elevation: 8,
            shadowColor: Colors.black54,
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ShellTabItem(
                        identifier: SemanticsIds.shellTabOverview,
                        selected: pageIndex == 0,
                        icon: Icons.grid_view_outlined,
                        selectedIcon: Icons.grid_view_rounded,
                        label: AppStrings.tabOverview,
                        onTap: () => navigationShell.goBranch(0),
                      ),
                    ),
                    Expanded(
                      child: ShellTabItem(
                        identifier: SemanticsIds.shellTabAccounts,
                        selected: pageIndex == 1,
                        icon: Icons.account_balance_wallet_outlined,
                        selectedIcon: Icons.account_balance_wallet_rounded,
                        label: AppStrings.tabAccounts,
                        onTap: () => navigationShell.goBranch(1),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: EnticingAddButton(
                        onPressed: () => _openActions(context),
                      ),
                    ),
                    Expanded(
                      child: ShellTabItem(
                        identifier: SemanticsIds.shellTabGoals,
                        selected: pageIndex == 2,
                        icon: Icons.flag_outlined,
                        selectedIcon: Icons.flag_rounded,
                        label: AppStrings.tabGoals,
                        onTap: () => navigationShell.goBranch(2),
                      ),
                    ),
                    Expanded(
                      child: ShellTabItem(
                        identifier: SemanticsIds.shellTabSettings,
                        selected: pageIndex == 3,
                        icon: Icons.settings_outlined,
                        selectedIcon: Icons.settings_rounded,
                        label: AppStrings.tabSettings,
                        onTap: () => navigationShell.goBranch(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
