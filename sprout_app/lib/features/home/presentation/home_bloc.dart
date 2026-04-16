import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/transactions/export.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

final class HomeSubscriptionRequested extends HomeEvent {
  const HomeSubscriptionRequested();
}

sealed class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

final class HomeInitial extends HomeState {
  const HomeInitial();
}

final class HomeReady extends HomeState {
  const HomeReady({
    required this.accounts,
    required this.portfolio,
    required this.recentTransactions,
    this.accountCurrentTotalsById = const <String, int>{},
    this.accountScheduledTotalsById = const <String, int>{},
  });

  final List<Account> accounts;
  final PortfolioSummary portfolio;
  final List<Transaction> recentTransactions;
  final Map<String, int> accountCurrentTotalsById;
  final Map<String, int> accountScheduledTotalsById;

  @override
  List<Object?> get props => [
        accounts,
        portfolio,
        recentTransactions,
        accountCurrentTotalsById,
        accountScheduledTotalsById,
      ];
}

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
