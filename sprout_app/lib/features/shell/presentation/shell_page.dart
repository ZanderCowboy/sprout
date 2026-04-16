import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/connectivity/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/home/export.dart';
import 'package:sprout/features/settings/presentation/settings_page.dart';
import 'package:sprout/ui/export.dart';
import 'deposit_bottom_sheet.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  static ShellPageState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<ShellPageState>();
  }

  @override
  State<ShellPage> createState() => ShellPageState();
}

class ShellPageState extends State<ShellPage> {
  int _pageIndex = 0;

  void setTabIndex(int index) {
    if (!mounted) return;
    if (index == _pageIndex) return;
    setState(() => _pageIndex = index);
  }

  void _openActions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text(AppStrings.newAccount),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => AccountFormSheet(defaultColor: AppColors.cardColorAt(0)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text(AppStrings.newGoal),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => CreateGoalScreen(defaultColor: AppColors.cardColorAt(1)),
                  );
                },
              ),
              ListTile(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppStrings.offline,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: IndexedStack(
                    index: _pageIndex,
                    children: const [OverviewPage(), AccountsPage(), GoalsPage(), SettingsPage()],
                  ),
                ),
              ),
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
                      child: _ShellTabItem(
                        selected: _pageIndex == 0,
                        icon: Icons.grid_view_outlined,
                        selectedIcon: Icons.grid_view_rounded,
                        label: AppStrings.tabOverview,
                        onTap: () => setState(() => _pageIndex = 0),
                      ),
                    ),
                    Expanded(
                      child: _ShellTabItem(
                        selected: _pageIndex == 1,
                        icon: Icons.account_balance_wallet_outlined,
                        selectedIcon: Icons.account_balance_wallet_rounded,
                        label: AppStrings.tabAccounts,
                        onTap: () => setState(() => _pageIndex = 1),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: EnticingAddButton(onPressed: _openActions),
                    ),
                    Expanded(
                      child: _ShellTabItem(
                        selected: _pageIndex == 2,
                        icon: Icons.flag_outlined,
                        selectedIcon: Icons.flag_rounded,
                        label: AppStrings.tabGoals,
                        onTap: () => setState(() => _pageIndex = 2),
                      ),
                    ),
                    Expanded(
                      child: _ShellTabItem(
                        selected: _pageIndex == 3,
                        icon: Icons.settings_outlined,
                        selectedIcon: Icons.settings_rounded,
                        label: AppStrings.tabSettings,
                        onTap: () => setState(() => _pageIndex = 3),
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

/// Center nav action: gradient disc, soft glow, gentle breathing scale, haptic tap.

class _ShellTabItem extends StatelessWidget {
  const _ShellTabItem({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
