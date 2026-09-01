part of 'transactions_bloc.dart';

sealed class TransactionsEvent extends Equatable {
  const TransactionsEvent();
  @override
  List<Object?> get props => [];
}

final class TransactionsSubscriptionRequested extends TransactionsEvent {
  const TransactionsSubscriptionRequested();
}
