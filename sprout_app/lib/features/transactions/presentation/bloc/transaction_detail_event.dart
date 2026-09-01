part of 'transaction_detail_bloc.dart';

sealed class TransactionDetailEvent extends Equatable {
  const TransactionDetailEvent();
  @override
  List<Object?> get props => [];
}

final class TransactionDetailSubscriptionRequested extends TransactionDetailEvent {
  const TransactionDetailSubscriptionRequested();
}
