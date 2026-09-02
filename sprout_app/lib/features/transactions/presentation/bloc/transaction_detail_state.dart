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
    this.savingNote = false,
    this.noteFeedback,
    this.noteSaveFailed = false,
  });

  final Transaction transaction;
  final List<Transaction>? groupTransactions;
  final Map<String, Goal> goalsById;
  final Map<String, Account> accountsById;
  final bool savingNote;
  final String? noteFeedback;
  final bool noteSaveFailed;

  TransactionDetailReady copyWith({
    Transaction? transaction,
    List<Transaction>? groupTransactions,
    Map<String, Goal>? goalsById,
    Map<String, Account>? accountsById,
    bool? savingNote,
    String? noteFeedback,
    bool? noteSaveFailed,
    bool clearNoteFeedback = false,
  }) {
    return TransactionDetailReady(
      transaction: transaction ?? this.transaction,
      groupTransactions: groupTransactions ?? this.groupTransactions,
      goalsById: goalsById ?? this.goalsById,
      accountsById: accountsById ?? this.accountsById,
      savingNote: savingNote ?? this.savingNote,
      noteFeedback: clearNoteFeedback
          ? null
          : (noteFeedback ?? this.noteFeedback),
      noteSaveFailed: noteSaveFailed ?? this.noteSaveFailed,
    );
  }

  @override
  List<Object?> get props => [
    transaction,
    groupTransactions,
    goalsById,
    accountsById,
    savingNote,
    noteFeedback,
    noteSaveFailed,
  ];
}
