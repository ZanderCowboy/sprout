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
      Map<String, int> currentTotals = const <String, int>{};
      Map<String, int> scheduledTotals = const <String, int>{};

      void tryEmit() {
        if (accounts != null && portfolio != null && recent != null) {
          controller.add(
            HomeReady(
              accounts: accounts!,
              portfolio: portfolio!,
              recentTransactions: recent!,
              accountCurrentTotalsById: currentTotals,
              accountScheduledTotalsById: scheduledTotals,
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
      final recentSub = _transactionsService.watchTransactions().listen(
        (all) {
          final now = DateTime.now();

          final recentCandidates = all
              .where((t) => !TransactionDisplay.isPendingByDate(t, now))
              .toList()
            ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
          recent = recentCandidates.take(5).toList(growable: false);

          final current = <String, int>{};
          final scheduled = <String, int>{};
          for (final t in all) {
            if (t.kind != TransactionKind.deposit) continue;
            final isScheduled = TransactionDisplay.isPendingByDate(t, now);
            final target = isScheduled ? scheduled : current;
            target[t.accountId] = (target[t.accountId] ?? 0) + t.amountCents;
          }
          currentTotals = current;
          scheduledTotals = scheduled;
          tryEmit();
        },
        onError: controller.addError,
      );

      controller.onCancel = () {
        accountsSub.cancel();
        portfolioSub.cancel();
        recentSub.cancel();
      };
    });
  }
}
