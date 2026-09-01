part of 'transactions_bloc.dart';

sealed class TransactionsState extends Equatable {
  const TransactionsState();
  @override
  List<Object?> get props => [];
}

final class TransactionsInitial extends TransactionsState {
  const TransactionsInitial();
}

final class TransactionsReady extends TransactionsState {
  const TransactionsReady({
    required this.items,
    required this.scheduledItems,
    required this.historyItems,
    required this.goalsById,
    required this.accountsById,
  });

  final List<Transaction> items;
  final List<Transaction> scheduledItems;
  final List<Transaction> historyItems;
  final Map<String, Goal> goalsById;
  final Map<String, Account> accountsById;

  @override
  List<Object?> get props =>
      [items, scheduledItems, historyItems, goalsById, accountsById];
}
