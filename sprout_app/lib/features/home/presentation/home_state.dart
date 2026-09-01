part of 'home_bloc.dart';

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
