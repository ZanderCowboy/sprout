import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';

import 'bloc/recurring_payments_bloc.dart';
import 'utils/transaction_frequency_label.dart';
import 'package:sprout/ui/export.dart';

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
            appBar: AppBar(title: const Text(AppStrings.recurringPayments)),
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
          AppStrings.noRecurringDepositsYet,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      itemCount: state.items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final item = state.items[i];
        final goalName = item.goalId == null
            ? AppStrings.unallocated
            : (state.goalsById[item.goalId!]?.name ?? AppStrings.unknownGoal);
        final accountName =
            state.accountsById[item.accountId]?.name ?? AppStrings.unknownAccount;

        return SproutListTile(
          identifier: SemanticsIds.recurringRow,
          label: formatZarFromCents(item.amountCents),
          leading: const Icon(Icons.autorenew_rounded),
          title: Text(formatZarFromCents(item.amountCents)),
          subtitle: Text(
            '$goalName · $accountName · ${transactionFrequencyLabel(item.frequency)}'
            '${item.recurringEnabled && item.nextScheduledDate != null ? ' · ${AppStrings.nextColon(formatDateTime(item.nextScheduledDate!))}' : ''}'
            '${!item.recurringEnabled ? ' · ${AppStrings.disabledStatus}' : ''}',
          ),
          trailing: SproutIconButton(
            identifier: SemanticsIds.recurringEdit,
            label: AppStrings.editRecurringPayment,
            tooltip: AppStrings.edit,
            onPressed: () => _openEdit(context, item),
            icon: const Icon(Icons.edit_rounded),
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
        title: const Text(AppStrings.cancelRecurringPaymentTitle),
        content: const Text(AppStrings.cancelRecurringPaymentBody),
        actions: SproutDialogActions.cancelDelete(
          onCancel: () => Navigator.pop(ctx, false),
          onDelete: () => Navigator.pop(ctx, true),
          cancelIdentifier: SemanticsIds.recurringCancel,
          deleteIdentifier: SemanticsIds.recurringDelete,
        ),
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
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottomPadding + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _enabled
                ? AppStrings.recurringDeposit
                : AppStrings.recurringDepositDisabled,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _enabled,
            onChanged: _saving ? null : (v) => setState(() => _enabled = v),
            title: Text(_enabled ? AppStrings.enabled : AppStrings.disabled),
            subtitle: _enabled
                ? null
                : const Text(AppStrings.recurringDepositWontApply),
          ),
          if (_enabled) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<TransactionFrequency>(
              value: _frequency, // ignore: deprecated_member_use
              decoration: const InputDecoration(labelText: AppStrings.frequency),
              items: const [
                DropdownMenuItem(
                  value: TransactionFrequency.daily,
                  child: Text(AppStrings.frequencyDaily),
                ),
                DropdownMenuItem(
                  value: TransactionFrequency.weekly,
                  child: Text(AppStrings.frequencyWeekly),
                ),
                DropdownMenuItem(
                  value: TransactionFrequency.monthly,
                  child: Text(AppStrings.frequencyMonthly),
                ),
                DropdownMenuItem(
                  value: TransactionFrequency.yearly,
                  child: Text(AppStrings.frequencyYearly),
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
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SproutOutlinedButton(
                  identifier: SemanticsIds.recurringDelete,
                  label: AppStrings.cancelRemove,
                  onPressed: _saving ? null : _cancelRecurring,
                  child: const Text(AppStrings.cancelRemove),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SproutFilledButton(
                  identifier: SemanticsIds.recurringSave,
                  label: AppStrings.save,
                  onPressed: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
