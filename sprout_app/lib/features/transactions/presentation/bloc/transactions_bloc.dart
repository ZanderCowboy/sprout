import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';

sealed class TransactionsEvent {
  const TransactionsEvent();
}

final class TransactionsSubscriptionRequested extends TransactionsEvent {
  const TransactionsSubscriptionRequested();
}

sealed class TransactionsState {
  const TransactionsState();
}

final class TransactionsInitial extends TransactionsState {
  const TransactionsInitial();
}

final class TransactionsReady extends TransactionsState {
  const TransactionsReady({
    required this.items,
    required this.goalsById,
    required this.accountsById,
  });

  final List<Transaction> items;
  final Map<String, Goal> goalsById;
  final Map<String, Account> accountsById;
}

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  TransactionsBloc({
    required TransactionsService transactionsService,
    required GoalsService goalsService,
    required AccountsService accountsService,
  })  : _transactionsService = transactionsService,
        _goalsService = goalsService,
        _accountsService = accountsService,
        super(const TransactionsInitial()) {
    on<TransactionsSubscriptionRequested>(_onSubscribe);
  }

  final TransactionsService _transactionsService;
  final GoalsService _goalsService;
  final AccountsService _accountsService;

  Future<void> _onSubscribe(
    TransactionsSubscriptionRequested event,
    Emitter<TransactionsState> emit,
  ) {
    return emit.forEach<TransactionsReady>(
      _watchReady(),
      onData: (ready) => ready,
    );
  }

  Stream<TransactionsReady> _watchReady() {
    return Stream<TransactionsReady>.multi((controller) {
      List<Transaction>? txs;
      List<Goal>? goals;
      List<Account>? accounts;

      void tryEmit() {
        if (txs == null || goals == null || accounts == null) return;
        controller.add(
          TransactionsReady(
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

