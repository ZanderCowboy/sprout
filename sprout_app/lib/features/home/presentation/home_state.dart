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
    this.accountMonthChangePercentById = const <String, double>{},
  });

  final List<Account> accounts;
  final PortfolioSummary portfolio;
  final List<Transaction> recentTransactions;
  final Map<String, int> accountCurrentTotalsById;
  final Map<String, int> accountScheduledTotalsById;
  final Map<String, double> accountMonthChangePercentById;

  @override
  List<Object?> get props => [
        accounts,
        portfolio,
        recentTransactions,
        accountCurrentTotalsById,
        accountScheduledTotalsById,
        accountMonthChangePercentById,
      ];
}
