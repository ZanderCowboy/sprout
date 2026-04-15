import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/accounts/accounts.dart';
import 'package:sprout/features/goals/goals.dart';
import 'package:sprout/features/transactions/transactions.dart';

import 'transaction_detail_page.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _TransactionsBloc(
        transactionsService: sl<TransactionsService>(),
        goalsService: sl<GoalsService>(),
        accountsService: sl<AccountsService>(),
      )..add(const _TransactionsSubscriptionRequested()),
      child: BlocBuilder<_TransactionsBloc, _TransactionsState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.transactions)),
            body: switch (state) {
              _TransactionsReady s => _TransactionsBody(state: s),
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

  final _TransactionsReady state;

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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final t = state.items[i];
        final accountName =
            state.accountsById[t.accountId]?.name ?? 'Unknown account';
        final goalName = t.goalId == null
            ? 'Unallocated'
            : (state.goalsById[t.goalId!]?.name ?? 'Unknown goal');

        final title = formatZarFromCents(t.amountCents);
        final kindLabel = switch (t.kind) {
          TransactionKind.deposit => 'Deposit',
          TransactionKind.allocation => 'Allocation',
        };

        final subtitleLines = <String>[
          '$kindLabel · $accountName',
          '$goalName · ${formatDate(t.occurredAt)}',
          if (t.isRecurring && t.frequency != TransactionFrequency.none)
            'Recurring · ${_labelForFrequency(t.frequency)}',
        ];

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TransactionDetailPage(
                    transactionId: t.id,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    t.kind == TransactionKind.deposit
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
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
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        );
      },
    );
  }

  String _labelForFrequency(TransactionFrequency f) {
    return switch (f) {
      TransactionFrequency.daily => 'Daily',
      TransactionFrequency.weekly => 'Weekly',
      TransactionFrequency.monthly => 'Monthly',
      TransactionFrequency.yearly => 'Yearly',
      TransactionFrequency.none => 'None',
    };
  }
}

sealed class _TransactionsEvent {
  const _TransactionsEvent();
}

final class _TransactionsSubscriptionRequested extends _TransactionsEvent {
  const _TransactionsSubscriptionRequested();
}

sealed class _TransactionsState {
  const _TransactionsState();
}

final class _TransactionsInitial extends _TransactionsState {
  const _TransactionsInitial();
}

final class _TransactionsReady extends _TransactionsState {
  const _TransactionsReady({
    required this.items,
    required this.goalsById,
    required this.accountsById,
  });

  final List<Transaction> items;
  final Map<String, Goal> goalsById;
  final Map<String, Account> accountsById;
}

class _TransactionsBloc extends Bloc<_TransactionsEvent, _TransactionsState> {
  _TransactionsBloc({
    required TransactionsService transactionsService,
    required GoalsService goalsService,
    required AccountsService accountsService,
  })  : _transactionsService = transactionsService,
        _goalsService = goalsService,
        _accountsService = accountsService,
        super(const _TransactionsInitial()) {
    on<_TransactionsSubscriptionRequested>(_onSubscribe);
  }

  final TransactionsService _transactionsService;
  final GoalsService _goalsService;
  final AccountsService _accountsService;

  Future<void> _onSubscribe(
    _TransactionsSubscriptionRequested event,
    Emitter<_TransactionsState> emit,
  ) {
    return emit.forEach<_TransactionsReady>(
      _watchReady(),
      onData: (ready) => ready,
    );
  }

  Stream<_TransactionsReady> _watchReady() {
    return Stream<_TransactionsReady>.multi((controller) {
      List<Transaction>? txs;
      List<Goal>? goals;
      List<Account>? accounts;

      void tryEmit() {
        if (txs == null || goals == null || accounts == null) return;
        controller.add(
          _TransactionsReady(
            items: txs!,
            goalsById: {for (final g in goals!) g.id: g},
            accountsById: {for (final a in accounts!) a.id: a},
          ),
        );
      }

      final txSub = _transactionsService.watchTransactions().listen(
        (t) {
          txs = t;
          tryEmit();
        },
        onError: controller.addError,
      );
      final goalsSub = _goalsService.watchGoals().listen(
        (g) {
          goals = g;
          tryEmit();
        },
        onError: controller.addError,
      );
      final accountsSub = _accountsService.watchAccounts().listen(
        (a) {
          accounts = a;
          tryEmit();
        },
        onError: controller.addError,
      );

      controller.onCancel = () {
        txSub.cancel();
        goalsSub.cancel();
        accountsSub.cancel();
      };
    });
  }
}

