part of 'account_detail_bloc.dart';

sealed class AccountDetailEvent extends Equatable {
  const AccountDetailEvent();
  @override
  List<Object?> get props => [];
}

final class AccountDetailSubscriptionRequested extends AccountDetailEvent {
  const AccountDetailSubscriptionRequested({required this.accountId});

  final String accountId;

  @override
  List<Object?> get props => [accountId];
}

final class AccountDetailDeleteRequested extends AccountDetailEvent {
  const AccountDetailDeleteRequested();
}

final class AccountDetailClearScheduledRequested extends AccountDetailEvent {
  const AccountDetailClearScheduledRequested({required this.transactionIds});

  final List<String> transactionIds;

  @override
  List<Object?> get props => [transactionIds];
}

final class AccountDetailRefreshRequested extends AccountDetailEvent {
  const AccountDetailRefreshRequested();
}
