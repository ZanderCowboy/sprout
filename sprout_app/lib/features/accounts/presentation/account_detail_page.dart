import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/goals/goals.dart';
import 'package:sprout/features/shell/shell.dart';
import 'package:sprout/features/transactions/transactions.dart';
import '../application/accounts_service.dart';
import '../domain/account.dart';
import 'account_form_sheet.dart';

class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({super.key, required this.account});

  final Account account;

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  late Account _account;
  List<Transaction> _tx = [];
  Map<String, Goal> _goals = {};
  bool _loading = true;

  TransactionsService get _txService => sl<TransactionsService>();
  GoalsService get _goalsService => sl<GoalsService>();

  @override
  void initState() {
    super.initState();
    _account = widget.account;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final txs = await _txService.getForAccount(_account.id);
    final goals = await _goalsService.getGoals();
    if (!mounted) return;
    setState(() {
      _tx = txs;
      _goals = {for (final g in goals) g.id: g};
      _loading = false;
    });
  }

  Future<void> _edit() async {
    final updated = await showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AccountFormSheet(
        initial: _account,
        defaultColor: Color(_account.color),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _account = updated);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.delete),
        content: const Text(
          'Remove this account? Deposits stay in history locally; '
          'when online, the account row is removed from the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await sl<AccountsService>().removeAccount(_account.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _openDeposit() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DepositBottomSheet(
        initialAccountId: _account.id,
        initialMode: DepositBottomSheetMode.depositToAccountThenAllocate,
        lockAccountSelection: true,
        forceQuickAccountDepositUi: true,
        showRecurringToggle: false,
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_account.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: _edit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _delete,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  DetailDepositCallout(
                    accentColor: Color(_account.color),
                    caption: AppStrings.addDepositCaptionAccount,
                    onPressed: _openDeposit,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.transactions,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (_tx.isEmpty)
                    Text(
                      'No deposits yet for this account.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    ..._tx.map((t) {
                      final goalName = t.goalId == null || t.goalId!.isEmpty
                          ? 'Unallocated'
                          : (_goals[t.goalId!]?.name ?? 'Unknown goal');
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(formatZarFromCents(t.amountCents)),
                          subtitle: Text(
                            '$goalName · ${formatDateTime(t.occurredAt)}',
                          ),
                          trailing: t.pendingSync
                              ? Icon(
                                  Icons.sync_rounded,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
