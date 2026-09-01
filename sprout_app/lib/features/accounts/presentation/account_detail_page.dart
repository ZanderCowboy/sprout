import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/shell/shell.dart';
import 'package:sprout/features/transactions/export.dart';
import '../application/accounts_service.dart';
import '../domain/account.dart';
import 'account_form_sheet.dart';
import 'widgets/account_detail_view.dart';
import 'package:sprout/ui/export.dart';

class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({super.key, required this.accountId});

  final String accountId;

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  Account? _account;
  List<Transaction> _tx = [];
  Map<String, Goal> _goals = {};
  bool _loading = true;

  TransactionsService get _txService => sl<TransactionsService>();
  GoalsService get _goalsService => sl<GoalsService>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final accounts = await sl<AccountsService>().getAccounts();
    Account? account;
    for (final a in accounts) {
      if (a.id == widget.accountId) {
        account = a;
        break;
      }
    }
    if (account == null) {
      if (!mounted) return;
      setState(() {
        _account = null;
        _tx = [];
        _goals = {};
        _loading = false;
      });
      return;
    }
    final txs = await _txService.getForAccount(account.id);
    final goals = await _goalsService.getGoals();
    if (!mounted) return;
    setState(() {
      _account = account;
      _tx = txs;
      _goals = {for (final g in goals) g.id: g};
      _loading = false;
    });
  }

  Future<void> _edit() async {
    final account = _account;
    if (account == null) return;
    final updated = await showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AccountFormSheet(initial: account, defaultColor: Color(account.color)),
    );
    if (updated != null && mounted) {
      setState(() => _account = updated);
    }
  }

  Future<void> _delete() async {
    final account = _account;
    if (account == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.delete),
        content: const Text(AppStrings.removeAccountConfirm),
        actions: SproutDialogActions.cancelDelete(
          onCancel: () => Navigator.pop(ctx, false),
          onDelete: () => Navigator.pop(ctx, true),
        ),
      ),
    );
    if (ok == true && mounted) {
      await sl<AccountsService>().removeAccount(account.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _openDeposit() async {
    final account = _account;
    if (account == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DepositBottomSheet(
        initialAccountId: account.id,
        initialMode: DepositBottomSheetMode.depositToAccountThenAllocate,
        lockAccountSelection: true,
        forceQuickAccountDepositUi: true,
        showRecurringToggle: false,
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _clearScheduled() async {
    final now = DateTime.now();
    final scheduledIds = _tx
        .where((t) => TransactionDisplay.isPendingByDate(t, now))
        .map((t) => t.id)
        .toList(growable: false);
    if (scheduledIds.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.clearScheduledTransactions),
        content: Text(
          AppStrings.clearScheduledBody(count: scheduledIds.length, scope: 'account'),
        ),
        actions: SproutDialogActions.cancelDelete(
          onCancel: () => Navigator.pop(ctx, false),
          onDelete: () => Navigator.pop(ctx, true),
        ),
      ),
    );
    if (ok != true || !mounted) return;

    for (final id in scheduledIds) {
      await _txService.deleteTransaction(id);
    }
    if (mounted) await _load();
  }

  int _computeAccountDepositTotalCents(Iterable<Transaction> txs) {
    var totalDeposits = 0;
    for (final t in txs) {
      switch (t.kind) {
        case TransactionKind.deposit:
          totalDeposits += t.amountCents;
          break;
        case TransactionKind.allocation:
          break;
      }
    }
    return totalDeposits > 0 ? totalDeposits : 0;
  }

  @override
  Widget build(BuildContext context) {
    final account = _account;
    if (account == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : const Text(AppStrings.accountNotFound),
        ),
      );
    }

    final now = DateTime.now();
    final scheduledTxs = _tx.where((t) => TransactionDisplay.isPendingByDate(t, now));
    final historyTxs = _tx.where((t) => !TransactionDisplay.isPendingByDate(t, now));

    final currentTotalCents = _computeAccountDepositTotalCents(historyTxs);
    final scheduledTotalCents = _computeAccountDepositTotalCents(scheduledTxs);
    final grandTotalCents = currentTotalCents + scheduledTotalCents;

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          SproutIconButton(
            identifier: SemanticsIds.accountDetailEdit,
            label: AppStrings.edit,
            onPressed: _edit,
            icon: const Icon(Icons.edit_rounded),
          ),
          SproutIconButton(
            identifier: SemanticsIds.accountDetailDelete,
            label: AppStrings.delete,
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AccountDetailView(
              account: account,
              transactions: _tx,
              goals: _goals,
              currentTotalCents: currentTotalCents,
              scheduledTotalCents: scheduledTotalCents,
              grandTotalCents: grandTotalCents,
              onRefresh: _load,
              onDeposit: _openDeposit,
              onClearScheduled: _clearScheduled,
            ),
    );
  }
}
