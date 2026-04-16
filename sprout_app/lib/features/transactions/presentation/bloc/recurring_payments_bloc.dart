import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';

sealed class RecurringPaymentsEvent {
  const RecurringPaymentsEvent();
}

final class RecurringPaymentsSubscriptionRequested extends RecurringPaymentsEvent {
  const RecurringPaymentsSubscriptionRequested();
}

sealed class RecurringPaymentsState {
  const RecurringPaymentsState();
}

final class RecurringPaymentsInitial extends RecurringPaymentsState {
  const RecurringPaymentsInitial();
}

final class RecurringPaymentsReady extends RecurringPaymentsState {
  const RecurringPaymentsReady({
    required this.items,
    required this.goalsById,
    required this.accountsById,
  });

  final List<Transaction> items;
  final Map<String, Goal> goalsById;
  final Map<String, Account> accountsById;
}

class RecurringPaymentsBloc
    extends Bloc<RecurringPaymentsEvent, RecurringPaymentsState> {
  RecurringPaymentsBloc({
    required TransactionsService transactionsService,
    required GoalsService goalsService,
    required AccountsService accountsService,
  })  : _transactionsService = transactionsService,
        _goalsService = goalsService,
        _accountsService = accountsService,
        super(const RecurringPaymentsInitial()) {
    on<RecurringPaymentsSubscriptionRequested>(_onSubscribe);
  }

  final TransactionsService _transactionsService;
  final GoalsService _goalsService;
  final AccountsService _accountsService;

  Future<void> _onSubscribe(
    RecurringPaymentsSubscriptionRequested event,
    Emitter<RecurringPaymentsState> emit,
  ) {
    return emit.forEach<RecurringPaymentsReady>(
      _watchReady(),
      onData: (ready) => ready,
    );
  }

  Stream<RecurringPaymentsReady> _watchReady() {
    return Stream<RecurringPaymentsReady>.multi((controller) {
      List<Transaction>? txs;
      List<Goal>? goals;
      List<Account>? accounts;

      void tryEmit() {
        if (txs == null || goals == null || accounts == null) return;

        final items = txs!
            .where(
              (t) =>
                  t.isRecurring &&
                  t.frequency != TransactionFrequency.none &&
                  t.kind == TransactionKind.deposit,
            )
            .toList()
          ..sort((a, b) {
            final ad = a.recurringEnabled
                ? (a.nextScheduledDate ?? DateTime(9999))
                : DateTime(9999);
            final bd = b.recurringEnabled
                ? (b.nextScheduledDate ?? DateTime(9999))
                : DateTime(9999);
            return ad.compareTo(bd);
          });

        controller.add(
          RecurringPaymentsReady(
            items: items,
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

