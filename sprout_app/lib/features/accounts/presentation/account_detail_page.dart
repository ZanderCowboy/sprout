import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/shell/shell.dart';
import 'package:sprout/features/transactions/export.dart';
import 'package:sprout/features/transactions/presentation/utils/transaction_display.dart';
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
        title: const Text('Clear scheduled transactions?'),
        content: Text(
          'This will remove ${scheduledIds.length} future-dated '
          'transaction${scheduledIds.length == 1 ? '' : 's'} from this account.',
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
    if (ok != true || !mounted) return;

    for (final id in scheduledIds) {
      await _txService.deleteTransaction(id);
    }
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    int computeAccountDepositTotalCents(Iterable<Transaction> txs) {
      var totalDeposits = 0;
      for (final t in txs) {
        switch (t.kind) {
          case TransactionKind.deposit:
            // Account value should include deposits whether they’re unallocated
            // or assigned directly to a goal.
            totalDeposits += t.amountCents;
            break;
          case TransactionKind.allocation:
            // Allocation is a movement of funds *within* the same account
            // (unallocated -> goal), so it should not change the account total.
            break;
        }
      }
      return totalDeposits > 0 ? totalDeposits : 0;
    }

    final scheduledTxs =
        _tx.where((t) => TransactionDisplay.isPendingByDate(t, now));
    final historyTxs =
        _tx.where((t) => !TransactionDisplay.isPendingByDate(t, now));

    final currentTotalCents = computeAccountDepositTotalCents(historyTxs);
    final scheduledTotalCents = computeAccountDepositTotalCents(scheduledTxs);
    final grandTotalCents = currentTotalCents + scheduledTotalCents;

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
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Account value',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                              if (scheduledTotalCents > 0)
                                TextButton.icon(
                                  onPressed: _clearScheduled,
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  label: const Text('Clear scheduled'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _ValueRow(
                            label: 'Current',
                            value: formatZarFromCents(currentTotalCents),
                          ),
                          const SizedBox(height: 6),
                          _ValueRow(
                            label: 'Scheduled',
                            value: formatZarFromCents(scheduledTotalCents),
                          ),
                          const Divider(height: 18),
                          _ValueRow(
                            label: 'Total',
                            value: formatZarFromCents(grandTotalCents),
                            isEmphasis: true,
                          ),
                        ],
                      ),
                    ),
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
                      final kindLabel = switch (t.kind) {
                        TransactionKind.deposit => 'Deposit',
                        TransactionKind.allocation => 'Allocation',
                      };
                      final style = mapTransactionToListStyle(t: t, now: now);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Opacity(
                          opacity: style.opacity,
                          child: ListTile(
                            leading: style.leadingIcon == null
                                ? null
                                : Icon(style.leadingIcon),
                            title: Text(formatZarFromCents(t.amountCents)),
                            subtitle: Text(
                              [
                                kindLabel,
                                goalName,
                                formatDateTime(t.occurredAt),
                                if (style.statusText != null) style.statusText!,
                              ].join(' · '),
                            ),
                            trailing: t.pendingSync
                                ? Icon(
                                    Icons.sync_rounded,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.primary,
                                  )
                                : null,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  final String label;
  final String value;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final valueStyle = (isEmphasis ? Theme.of(context).textTheme.titleMedium : style)
        ?.copyWith(fontWeight: isEmphasis ? FontWeight.w900 : FontWeight.w700);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: style?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(value, style: valueStyle),
      ],
    );
  }
}
