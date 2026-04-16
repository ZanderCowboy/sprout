import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/transactions/presentation/recurring_payments_page.dart';
import 'package:sprout/features/transactions/presentation/transactions_page.dart';
import 'package:sprout/features/budget/presentation/budget_planner_screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
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

