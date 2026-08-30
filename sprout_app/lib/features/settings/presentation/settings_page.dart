import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/auth/export.dart';
import 'package:sprout/features/purchases/presentation/premium_paywall_helper.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:sprout/ui/export.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _purchasesReady = false;
  bool _loadingPremiumStatus = true;
  bool _hasPremium = false;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    try {
      final ready = await PremiumPaywall.isPurchasesReady();
      if (!mounted) return;
      if (!ready) {
        setState(() {
          _purchasesReady = false;
          _loadingPremiumStatus = false;
          _hasPremium = false;
        });
        return;
      }

      final hasPremium = await PremiumPaywall.hasPremium();
      if (!mounted) return;
      setState(() {
        _purchasesReady = true;
        _loadingPremiumStatus = false;
        _hasPremium = hasPremium;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _purchasesReady = false;
        _loadingPremiumStatus = false;
        _hasPremium = false;
      });
    }
  }

  Future<void> _presentPaywall() async {
    final result = await PremiumPaywall.presentPremiumPaywall();
    if (!mounted) return;

    // Refresh entitlement state after the paywall flow completes.
    final hasPremium = await PremiumPaywall.hasPremium();
    if (!mounted) return;
    setState(() => _hasPremium = hasPremium);

    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case PaywallResult.purchased:
      case PaywallResult.restored:
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.premiumUnlocked)),
        );
        break;
      case PaywallResult.cancelled:
      case PaywallResult.notPresented:
        // Silence on cancel
        break;
      case PaywallResult.error:
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.subscriptionUpdateFailed)),
        );
        break;
    }
  }

  void _openAccount() {
    context.push(AppRoute.account.path);
  }

  @override
  Widget build(BuildContext context) {
    final premiumSubtitle = _loadingPremiumStatus
        ? AppStrings.checkingSubscription
        : _hasPremium
        ? AppStrings.premiumActive
        : AppStrings.unlockPremium;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tabSettings)),
      body: ListView(
        children: [
          BlocBuilder<AuthCubit, AuthViewState>(
            builder: (context, state) {
              final user = state is AuthViewSignedIn ? state.user : null;
              return SproutListTile(
                identifier: SemanticsIds.settingsAccount,
                label: user == null ? AppStrings.account : accountTileTitle(user),
                leading: user == null
                    ? const Icon(Icons.manage_accounts_rounded)
                    : CircleAvatar(child: Text(accountAvatarInitial(user))),
                title: Text(
                  user == null ? AppStrings.account : accountTileTitle(user),
                ),
                subtitle: user == null ? null : Text(accountTileSubtitle(user)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _openAccount,
              );
            },
          ),
          const Divider(height: 1),
          if (_purchasesReady)
            Column(
              children: [
                SproutListTile(
                  identifier: SemanticsIds.settingsPremium,
                  label: AppStrings.sproutPremium,
                  leading: const Icon(Icons.workspace_premium_rounded),
                  title: const Text(AppStrings.sproutPremium),
                  subtitle: Text(premiumSubtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _presentPaywall(),
                ),
                const Divider(height: 1),
              ],
            ),
          SproutListTile(
            identifier: SemanticsIds.settingsTransactions,
            label: AppStrings.transactions,
            leading: const Icon(Icons.receipt_long_rounded),
            title: const Text(AppStrings.transactions),
            subtitle: const Text(AppStrings.viewAllDeposits),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoute.transactions.path),
          ),
          const Divider(height: 1),
          SproutListTile(
            identifier: SemanticsIds.settingsRecurring,
            label: AppStrings.recurringPayments,
            leading: const Icon(Icons.autorenew_rounded),
            title: const Text(AppStrings.recurringPayments),
            subtitle: const Text(AppStrings.viewEditCancelRecurring),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoute.recurring.path),
          ),
          const Divider(height: 1),
          SproutListTile(
            identifier: SemanticsIds.settingsBudget,
            label: AppStrings.masterBudget,
            leading: const Icon(Icons.account_tree_rounded),
            title: const Text(AppStrings.masterBudget),
            subtitle: const Text(AppStrings.planIncomeExpenses),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoute.budget.path),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text(AppStrings.appTitle),
            subtitle: const Text(AppStrings.savingsApp),
          ),
        ],
      ),
    );
  }
}
