import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/auth/export.dart';
import 'package:sprout/features/purchases/presentation/premium_paywall_helper.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

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
          const SnackBar(content: Text('Premium unlocked.')),
        );
        break;
      case PaywallResult.cancelled:
      case PaywallResult.notPresented:
        // Silence on cancel
        break;
      case PaywallResult.error:
        messenger.showSnackBar(
          const SnackBar(content: Text('Subscription update failed.')),
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
        ? 'Checking subscription...'
        : _hasPremium
        ? 'Premium active'
        : 'Unlock premium with Monthly or Annual';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          BlocBuilder<AuthCubit, AuthViewState>(
            builder: (context, state) {
              final user = state is AuthViewSignedIn ? state.user : null;
              return ListTile(
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
                ListTile(
                  leading: const Icon(Icons.workspace_premium_rounded),
                  title: const Text('Sprout Premium'),
                  subtitle: Text(premiumSubtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _presentPaywall(),
                ),
                const Divider(height: 1),
              ],
            ),
          ListTile(
            leading: const Icon(Icons.receipt_long_rounded),
            title: const Text(AppStrings.transactions),
            subtitle: const Text('View all deposits and allocations'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoute.transactions.path),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.autorenew_rounded),
            title: const Text('Recurring payments'),
            subtitle: const Text('View, edit, or cancel recurring deposits'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoute.recurring.path),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.account_tree_rounded),
            title: const Text('Master Budget'),
            subtitle: const Text('Plan income and expenses (static template)'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoute.budget.path),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text(AppStrings.appTitle),
            subtitle: const Text('Savings app'),
          ),
        ],
      ),
    );
  }
}
