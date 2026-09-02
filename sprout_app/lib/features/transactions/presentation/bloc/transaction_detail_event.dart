part of 'transaction_detail_bloc.dart';

sealed class TransactionDetailEvent extends Equatable {
  const TransactionDetailEvent();
  @override
  List<Object?> get props => [];
}

final class TransactionDetailSubscriptionRequested
    extends TransactionDetailEvent {
  const TransactionDetailSubscriptionRequested();
}

final class TransactionDetailNoteSaveRequested extends TransactionDetailEvent {
  const TransactionDetailNoteSaveRequested({required this.note});

  final String note;

  @override
  List<Object?> get props => [note];
}
