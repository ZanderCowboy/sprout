import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';

import 'bloc/recurring_payments_bloc.dart';
import 'utils/transaction_frequency_label.dart';
import 'widgets/edit_recurring_sheet.dart';
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
      builder: (_) => EditRecurringSheet(transaction: tx),
    );
  }
}
