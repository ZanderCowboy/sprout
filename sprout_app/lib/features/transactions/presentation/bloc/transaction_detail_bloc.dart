import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';

sealed class TransactionDetailEvent {
  const TransactionDetailEvent();
}

final class TransactionDetailSubscriptionRequested extends TransactionDetailEvent {
  const TransactionDetailSubscriptionRequested();
}

sealed class TransactionDetailState {
  const TransactionDetailState();
}

final class TransactionDetailInitial extends TransactionDetailState {
  const TransactionDetailInitial();
}

final class TransactionDetailMissing extends TransactionDetailState {
  const TransactionDetailMissing();
}

final class TransactionDetailReady extends TransactionDetailState {
  const TransactionDetailReady({
    required this.transaction,
    required this.groupTransactions,
    required this.goalsById,
    required this.accountsById,
  });

  final Transaction transaction;
  final List<Transaction>? groupTransactions;
  final Map<String, Goal> goalsById;
  final Map<String, Account> accountsById;
}

class TransactionDetailBloc
    extends Bloc<TransactionDetailEvent, TransactionDetailState> {
  TransactionDetailBloc({
    required String transactionId,
    required TransactionsService transactionsService,
    required GoalsService goalsService,
    required AccountsService accountsService,
  })  : _transactionId = transactionId,
        _transactionsService = transactionsService,
        _goalsService = goalsService,
        _accountsService = accountsService,
        super(const TransactionDetailInitial()) {
    on<TransactionDetailSubscriptionRequested>(_onSubscribe);
  }

  final String _transactionId;
  final TransactionsService _transactionsService;
  final GoalsService _goalsService;
  final AccountsService _accountsService;

  Future<void> _onSubscribe(
    TransactionDetailSubscriptionRequested event,
    Emitter<TransactionDetailState> emit,
  ) {
    return emit.forEach<TransactionDetailState>(
      _watch(),
      onData: (s) => s,
    );
  }

  Stream<TransactionDetailState> _watch() {
    return Stream<TransactionDetailState>.multi((controller) {
      List<Transaction>? txs;
      List<Goal>? goals;
      List<Account>? accounts;

      void tryEmit() {
        if (txs == null || goals == null || accounts == null) return;
        final t = txs!.where((x) => x.id == _transactionId).toList();
        if (t.isEmpty) {
          controller.add(const TransactionDetailMissing());
          return;
        }
        final tx = t.first;
        final gid = tx.groupId;
        List<Transaction>? group;
        if (gid != null) {
          group = txs!
              .where((x) => x.groupId == gid)
              .toList()
            ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
        }
        controller.add(
          TransactionDetailReady(
            transaction: tx,
            groupTransactions: group,
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

