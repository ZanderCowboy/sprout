import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';

import 'bloc/transactions_bloc.dart';
import 'utils/transaction_frequency_label.dart';

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
          'No transactions yet.',
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

    // Keep existing sort order, but ensure sections are internally sorted.
    scheduled.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    history.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (scheduled.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Scheduled',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          ...scheduled.expand((t) => [
                _TransactionCard(
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
              'History',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          ...history.expand((t) => [
                _TransactionCard(
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

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transaction,
    required this.goalsById,
    required this.accountsById,
    required this.now,
  });

  final Transaction transaction;
  final Map<String, Goal> goalsById;
  final Map<String, Account> accountsById;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final accountName = accountsById[t.accountId]?.name ?? 'Unknown account';
    final goalName = t.goalId == null
        ? 'Unallocated'
        : (goalsById[t.goalId!]?.name ?? 'Unknown goal');

    final title = formatZarFromCents(t.amountCents);
    final kindLabel = switch (t.kind) {
      TransactionKind.deposit => 'Deposit',
      TransactionKind.allocation => 'Allocation',
    };
    final style = mapTransactionToListStyle(t: t, now: now);

    final subtitleLines = <String>[
      '$kindLabel · $accountName',
      '$goalName · ${formatDate(t.occurredAt)}'
          '${style.statusText != null ? ' · ${style.statusText!}' : ''}',
      if (t.isRecurring && t.frequency != TransactionFrequency.none)
        'Recurring · ${transactionFrequencyLabel(t.frequency)}',
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Opacity(
        opacity: style.opacity,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TransactionDetailPage(transactionId: t.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  style.leadingIcon ??
                      (t.kind == TransactionKind.deposit
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitleLines.join('\n'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

