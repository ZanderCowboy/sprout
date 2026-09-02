import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/transactions/export.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required AccountsService accountsService,
    required TransactionsService transactionsService,
  })  : _accountsService = accountsService,
        _transactionsService = transactionsService,
        super(const HomeInitial()) {
    on<HomeSubscriptionRequested>(
      _onSubscribe,
      transformer: restartable(),
    );
  }

  final AccountsService _accountsService;
  final TransactionsService _transactionsService;

  Future<void> _onSubscribe(
    HomeSubscriptionRequested event,
    Emitter<HomeState> emit,
  ) {
    return emit.forEach<HomeReady>(
      _watchHomeReady(),
      onData: (ready) => ready,
    );
  }

  Stream<HomeReady> _watchHomeReady() {
    return Stream<HomeReady>.multi((controller) {
      List<Account>? accounts;
      PortfolioSummary? portfolio;
      List<Transaction>? recent;
      var currentTotals = const <String, int>{};
      var scheduledTotals = const <String, int>{};
      var monthChangePercents = const <String, double>{};

      void tryEmit() {
        if (accounts != null && portfolio != null && recent != null) {
          controller.add(
            HomeReady(
              accounts: accounts!,
              portfolio: portfolio!,
              recentTransactions: recent!,
              accountCurrentTotalsById: currentTotals,
              accountScheduledTotalsById: scheduledTotals,
              accountMonthChangePercentById: monthChangePercents,
            ),
          );
        }
      }

      final accountsSub = _accountsService.watchAccounts().listen(
        (a) {
          accounts = a;
          tryEmit();
        },
        onError: controller.addError,
      );
      final portfolioSub =
          _transactionsService.watchPortfolioSummary().listen(
        (p) {
          portfolio = p;
          tryEmit();
        },
        onError: controller.addError,
      );
      final fundsSub = _transactionsService
          .watchFundsSnapshot(
            accountIdsStream: _accountsService
                .watchAccounts()
                .map((a) => a.map((account) => account.id).toList()),
          )
          .listen(
        (snapshot) {
          currentTotals = snapshot.accountCurrentDepositTotalsById;
          scheduledTotals = snapshot.accountScheduledDepositTotalsById;
          monthChangePercents = snapshot.accountMonthChangePercentById;
          tryEmit();
        },
        onError: controller.addError,
      );
      final recentSub = _transactionsService.watchTransactions().listen(
        (all) {
          final split = _transactionsService.splitScheduledAndHistory(all);
          recent = split.history.take(5).toList(growable: false);
          tryEmit();
        },
        onError: controller.addError,
      );

      controller.onCancel = () {
        accountsSub.cancel();
        portfolioSub.cancel();
        fundsSub.cancel();
        recentSub.cancel();
      };
    });
  }
}
