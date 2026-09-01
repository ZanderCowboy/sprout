import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';

import 'bloc/transactions_bloc.dart';
import 'widgets/transaction_card.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TransactionsBloc(
        transactionsService: sl<TransactionsService>(),
        goalsService: sl<GoalsService>(),
        accountsService: sl<AccountsService>(),
      )..add(const TransactionsSubscriptionRequested()),
      child: BlocBuilder<TransactionsBloc, TransactionsState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.transactions)),
            body: switch (state) {
              TransactionsReady s => _TransactionsBody(state: s),
              _ => const Center(child: CircularProgressIndicator()),
            },
          );
        },
      ),
    );
  }
}

class _TransactionsBody extends StatelessWidget {
  const _TransactionsBody({required this.state});

  final TransactionsReady state;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return Center(
        child: Text(
          AppStrings.noTransactionsYet,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final now = DateTime.now();
    final scheduled = <Transaction>[];
    final history = <Transaction>[];
    for (final t in state.items) {
      if (TransactionDisplay.isPendingByDate(t, now)) {
        scheduled.add(t);
      } else {
        history.add(t);
      }
    }

    scheduled.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    history.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (scheduled.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              AppStrings.scheduled,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          ...scheduled.expand((t) => [
                TransactionCard(
                  transaction: t,
                  goalsById: state.goalsById,
                  accountsById: state.accountsById,
                  now: now,
                ),
                const SizedBox(height: 10),
              ]),
          const SizedBox(height: 8),
        ],
        if (history.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              AppStrings.history,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          ...history.expand((t) => [
                TransactionCard(
                  transaction: t,
                  goalsById: state.goalsById,
                  accountsById: state.accountsById,
                  now: now,
                ),
                const SizedBox(height: 10),
              ]),
        ],
      ],
    );
  }
}
