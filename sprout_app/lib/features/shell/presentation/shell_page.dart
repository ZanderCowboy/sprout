import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/accounts/accounts.dart';
import 'package:sprout/features/connectivity/connectivity.dart';
import 'package:sprout/features/goals/goals.dart';
import 'package:sprout/features/home/home.dart';
import 'package:sprout/features/settings/presentation/settings_page.dart';
import 'deposit_bottom_sheet.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  static _ShellPageState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<_ShellPageState>();
  }

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
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
                    builder: (_) => AccountFormSheet(
                      defaultColor: AppColors.cardColorAt(0),
                    ),
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
                    builder: (_) => GoalFormSheet(
                      defaultColor: AppColors.cardColorAt(1),
                    ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
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
                    children: const [
                      OverviewPage(),
                      AccountsPage(),
                      GoalsPage(),
                      SettingsPage(),
                    ],
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
                      child: _EnticingAddButton(onPressed: _openActions),
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
class _EnticingAddButton extends StatefulWidget {
  const _EnticingAddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_EnticingAddButton> createState() => _EnticingAddButtonState();
}

class _EnticingAddButtonState extends State<_EnticingAddButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _breath;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.072).animate(
      CurvedAnimation(parent: _breath, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    const size = 58.0;
    const iconSize = 31.0;

    return Tooltip(
      message: AppStrings.actionAdd,
      child: Semantics(
        button: true,
        label: AppStrings.actionAdd,
        child: ScaleTransition(
          scale: _scale,
          child: SizedBox(
            width: size + 10,
            height: size + 10,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: size + 8,
                  height: size + 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentLime.withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: AppColors.seed.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _onTap,
                    customBorder: const CircleBorder(),
                    child: Ink(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(
                              AppColors.accentLime,
                              Colors.white,
                              0.22,
                            )!,
                            AppColors.accentLime,
                            Color.lerp(
                              AppColors.accentLime,
                              AppColors.seed,
                              0.28,
                            )!,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_rounded,
                          color: AppColors.surfaceDeep,
                          size: iconSize,
                          shadows: [
                            Shadow(
                              color: Color(0x33FFFFFF),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
