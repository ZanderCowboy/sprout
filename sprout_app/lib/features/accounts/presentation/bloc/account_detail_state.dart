part of 'account_detail_bloc.dart';

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

final class AccountDetailDeleted extends AccountDetailState {
  const AccountDetailDeleted();
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

  bool get hasRecurringDeposits =>
      transactions.any(TransactionRules.isRecurringDeposit);

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
