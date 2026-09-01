import 'package:equatable/equatable.dart';

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
