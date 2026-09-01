part of 'transaction_detail_bloc.dart';

sealed class TransactionDetailState extends Equatable {
  const TransactionDetailState();
  @override
  List<Object?> get props => [];
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

  @override
  List<Object?> get props =>
      [transaction, groupTransactions, goalsById, accountsById];
}
