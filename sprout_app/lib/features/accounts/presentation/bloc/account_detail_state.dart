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
    this.actionError,
  });

  final Account account;
  final List<Transaction> transactions;
  final List<Transaction> scheduledTransactions;
  final List<Transaction> historyTransactions;
  final int currentTotalCents;
  final int scheduledTotalCents;
  final Map<String, Goal> goalsById;
  final String? actionError;

  int get grandTotalCents => currentTotalCents + scheduledTotalCents;

  bool get hasRecurringDeposits =>
      transactions.any(TransactionRules.isRecurringDeposit);

  AccountDetailReady copyWith({
    Account? account,
    List<Transaction>? transactions,
    List<Transaction>? scheduledTransactions,
    List<Transaction>? historyTransactions,
    int? currentTotalCents,
    int? scheduledTotalCents,
    Map<String, Goal>? goalsById,
    String? actionError,
    bool clearActionError = false,
  }) {
    return AccountDetailReady(
      account: account ?? this.account,
      transactions: transactions ?? this.transactions,
      scheduledTransactions: scheduledTransactions ?? this.scheduledTransactions,
      historyTransactions: historyTransactions ?? this.historyTransactions,
      currentTotalCents: currentTotalCents ?? this.currentTotalCents,
      scheduledTotalCents: scheduledTotalCents ?? this.scheduledTotalCents,
      goalsById: goalsById ?? this.goalsById,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
    account,
    transactions,
    scheduledTransactions,
    historyTransactions,
    currentTotalCents,
    scheduledTotalCents,
    goalsById,
    actionError,
  ];
}
