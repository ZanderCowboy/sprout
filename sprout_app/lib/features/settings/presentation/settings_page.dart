import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/purchases/presentation/premium_paywall_helper.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:sprout/features/transactions/presentation/recurring_payments_page.dart';
import 'package:sprout/features/transactions/presentation/transactions_page.dart';
import 'package:sprout/features/budget/presentation/budget_planner_screen.dart';

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
        messenger.showSnackBar(
          const SnackBar(content: Text('No purchase completed.')),
        );
        break;
      case PaywallResult.error:
        messenger.showSnackBar(
          const SnackBar(content: Text('Subscription update failed.')),
        );
        break;
    }
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
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TransactionsPage(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.autorenew_rounded),
            title: const Text('Recurring payments'),
            subtitle: const Text('View, edit, or cancel recurring deposits'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RecurringPaymentsPage(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.account_tree_rounded),
            title: const Text('Master Budget'),
            subtitle: const Text('Plan income and expenses (static template)'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BudgetPlannerScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text(AppStrings.appTitle),
            subtitle: const Text('Savings app prototype'),
          ),
        ],
      ),
    );
  }
}

