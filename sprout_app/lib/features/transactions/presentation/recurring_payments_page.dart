import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';

import 'bloc/recurring_payments_bloc.dart';
import 'utils/transaction_frequency_label.dart';

class RecurringPaymentsPage extends StatelessWidget {
  const RecurringPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecurringPaymentsBloc(
        transactionsService: sl<TransactionsService>(),
        goalsService: sl<GoalsService>(),
        accountsService: sl<AccountsService>(),
      )..add(const RecurringPaymentsSubscriptionRequested()),
      child: BlocBuilder<RecurringPaymentsBloc, RecurringPaymentsState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Recurring payments')),
            body: switch (state) {
              RecurringPaymentsReady s => _RecurringPaymentsBody(state: s),
              _ => const Center(child: CircularProgressIndicator()),
            },
          );
        },
      ),
    );
  }
}

class _RecurringPaymentsBody extends StatelessWidget {
  const _RecurringPaymentsBody({required this.state});

  final RecurringPaymentsReady state;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return Center(
        child: Text(
          'No recurring deposits yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final item = state.items[i];
        final goalName = item.goalId == null
            ? 'Unallocated'
            : (state.goalsById[item.goalId!]?.name ?? 'Unknown goal');
        final accountName =
            state.accountsById[item.accountId]?.name ?? 'Unknown account';

        return ListTile(
          leading: const Icon(Icons.autorenew_rounded),
          title: Text(formatZarFromCents(item.amountCents)),
          subtitle: Text(
            '$goalName · $accountName · ${transactionFrequencyLabel(item.frequency)}'
            '${item.recurringEnabled && item.nextScheduledDate != null ? ' · next ${formatDateTime(item.nextScheduledDate!)}' : ''}'
            '${!item.recurringEnabled ? ' · disabled' : ''}',
          ),
          trailing: IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _openEdit(context, item),
          ),
          onTap: () => _openEdit(context, item),
        );
      },
    );
  }

  Future<void> _openEdit(BuildContext context, Transaction tx) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditRecurringSheet(transaction: tx),
    );
  }
}

class _EditRecurringSheet extends StatefulWidget {
  const _EditRecurringSheet({required this.transaction});

  final Transaction transaction;

  @override
  State<_EditRecurringSheet> createState() => _EditRecurringSheetState();
}

class _EditRecurringSheetState extends State<_EditRecurringSheet> {
  late bool _enabled;
  late TransactionFrequency _frequency;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.transaction.recurringEnabled;
    _frequency = widget.transaction.frequency == TransactionFrequency.none
        ? TransactionFrequency.monthly
        : widget.transaction.frequency;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await sl<TransactionsService>().updateRecurringDeposit(
        transactionId: widget.transaction.id,
        isRecurring: _enabled,
        frequency: _enabled ? _frequency : TransactionFrequency.none,
      );
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancelRecurring() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel recurring payment?'),
        content: const Text(
          'This will remove the recurring payment. Existing transactions '
          'already in your history will remain.',
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
    if (ok != true) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await sl<TransactionsService>().deleteTransaction(widget.transaction.id);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPadding = mq.viewInsets.bottom + mq.padding.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomPadding + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _enabled ? 'Recurring deposit' : 'Recurring deposit (Disabled)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _enabled,
            onChanged: _saving ? null : (v) => setState(() => _enabled = v),
            title: Text(_enabled ? 'Enabled' : 'Disabled'),
            subtitle: _enabled
                ? null
                : const Text('This recurring deposit won’t be applied.'),
          ),
          if (_enabled) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<TransactionFrequency>(
              value: _frequency, // ignore: deprecated_member_use
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: const [
                DropdownMenuItem(
                  value: TransactionFrequency.daily,
                  child: Text('Daily'),
                ),
                DropdownMenuItem(
                  value: TransactionFrequency.weekly,
                  child: Text('Weekly'),
                ),
                DropdownMenuItem(
                  value: TransactionFrequency.monthly,
                  child: Text('Monthly'),
                ),
                DropdownMenuItem(
                  value: TransactionFrequency.yearly,
                  child: Text('Yearly'),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() => _frequency = v);
                    },
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _cancelRecurring,
                  child: const Text('Cancel (remove)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text(AppStrings.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
