import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sprout/features/accounts/presentation/bloc/account_detail_event.dart';
import 'package:sprout/features/accounts/presentation/bloc/account_detail_state.dart';

import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';

import '../../application/accounts_service.dart';
import '../../domain/account.dart';

class AccountDetailBloc extends Bloc<AccountDetailEvent, AccountDetailState> {
  AccountDetailBloc({
    required AccountsService accountsService,
    required TransactionsService transactionsService,
    required GoalsService goalsService,
  }) : _accountsService = accountsService,
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
      var accountsResolved = false;
      List<Transaction> txs = [];
      Map<String, Goal> goalsById = {};

      void tryEmit() {
        if (!accountsResolved) {
          controller.add(const AccountDetailLoading());
          return;
        }

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

      final accountsSub = _accountsService.watchAccounts().listen((accounts) {
        accountsResolved = true;
        account = accounts.cast<Account?>().firstWhere(
          (a) => a?.id == accountId,
          orElse: () => null,
        );
        tryEmit();
      }, onError: controller.addError);

      final txSub = _transactionsService.watchTransactions().listen(
        (_) => reloadTransactions(),
        onError: controller.addError,
      );

      final goalsSub = _goalsService.watchGoals().listen((goals) {
        goalsById = {for (final g in goals) g.id: g};
        tryEmit();
      }, onError: controller.addError);

      reloadTransactions();

      controller.onCancel = () {
        accountsSub.cancel();
        txSub.cancel();
        goalsSub.cancel();
      };
    });
  }
}
