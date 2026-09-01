import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';

import '../application/accounts_service.dart';
import '../domain/account.dart';

sealed class AccountDetailEvent extends Equatable {
  const AccountDetailEvent();
  @override
  List<Object?> get props => [];
}

final class AccountDetailSubscriptionRequested extends AccountDetailEvent {
  const AccountDetailSubscriptionRequested({required this.accountId});

  final String accountId;

  @override
  List<Object?> get props => [accountId];
}

sealed class AccountDetailState extends Equatable {
  const AccountDetailState();
  @override
  List<Object?> get props => [];
}

final class AccountDetailInitial extends AccountDetailState {
  const AccountDetailInitial();
}

final class AccountDetailLoading extends AccountDetailState {
  const AccountDetailLoading();
}

final class AccountDetailNotFound extends AccountDetailState {
  const AccountDetailNotFound();
}

final class AccountDetailReady extends AccountDetailState {
  const AccountDetailReady({
    required this.account,
    required this.transactions,
    required this.scheduledTransactions,
    required this.historyTransactions,
    required this.currentTotalCents,
    required this.scheduledTotalCents,
    required this.goalsById,
  });

  final Account account;
  final List<Transaction> transactions;
  final List<Transaction> scheduledTransactions;
  final List<Transaction> historyTransactions;
  final int currentTotalCents;
  final int scheduledTotalCents;
  final Map<String, Goal> goalsById;

  int get grandTotalCents => currentTotalCents + scheduledTotalCents;

  @override
  List<Object?> get props => [
        account,
        transactions,
        scheduledTransactions,
        historyTransactions,
        currentTotalCents,
        scheduledTotalCents,
        goalsById,
      ];
}

class AccountDetailBloc extends Bloc<AccountDetailEvent, AccountDetailState> {
  AccountDetailBloc({
    required AccountsService accountsService,
    required TransactionsService transactionsService,
    required GoalsService goalsService,
  })  : _accountsService = accountsService,
        _transactionsService = transactionsService,
        _goalsService = goalsService,
        super(const AccountDetailInitial()) {
    on<AccountDetailSubscriptionRequested>(
      _onSubscribe,
      transformer: restartable(),
    );
  }

  final AccountsService _accountsService;
  final TransactionsService _transactionsService;
  final GoalsService _goalsService;

  Future<void> _onSubscribe(
    AccountDetailSubscriptionRequested event,
    Emitter<AccountDetailState> emit,
  ) {
    return emit.forEach<AccountDetailState>(
      _watch(event.accountId),
      onData: (s) => s,
    );
  }

  Stream<AccountDetailState> _watch(String accountId) {
    return Stream<AccountDetailState>.multi((controller) {
      Account? account;
      List<Transaction> txs = [];
      Map<String, Goal> goalsById = {};

      void tryEmit() {
        final currentAccount = account;
        if (currentAccount == null) {
          controller.add(const AccountDetailNotFound());
          return;
        }

        final split = _transactionsService.splitScheduledAndHistory(txs);
        controller.add(
          AccountDetailReady(
            account: currentAccount,
            transactions: txs,
            scheduledTransactions: split.scheduled,
            historyTransactions: split.history,
            currentTotalCents: FundsCalculator.accountDepositTotalCents(
              split.history,
              historyOnly: true,
            ),
            scheduledTotalCents: FundsCalculator.accountDepositTotalCents(
              split.scheduled,
              scheduledOnly: true,
            ),
            goalsById: goalsById,
          ),
        );
      }

      Future<void> reloadTransactions() async {
        txs = await _transactionsService.getForAccount(accountId);
        tryEmit();
      }

      final accountsSub = _accountsService.watchAccounts().listen(
        (accounts) {
          account = accounts.cast<Account?>().firstWhere(
                (a) => a?.id == accountId,
                orElse: () => null,
              );
          tryEmit();
        },
        onError: controller.addError,
      );

      final txSub = _transactionsService.watchTransactions().listen(
        (_) => reloadTransactions(),
        onError: controller.addError,
      );

      final goalsSub = _goalsService.watchGoals().listen(
        (goals) {
          goalsById = {for (final g in goals) g.id: g};
          tryEmit();
        },
        onError: controller.addError,
      );

      reloadTransactions();

      controller.onCancel = () {
        accountsSub.cancel();
        txSub.cancel();
        goalsSub.cancel();
      };
    });
  }
}
