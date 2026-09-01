part of 'recurring_payments_bloc.dart';

sealed class RecurringPaymentsState extends Equatable {
  const RecurringPaymentsState();
  @override
  List<Object?> get props => [];
}

final class RecurringPaymentsInitial extends RecurringPaymentsState {
  const RecurringPaymentsInitial();
}

final class RecurringPaymentsReady extends RecurringPaymentsState {
  const RecurringPaymentsReady({
    required this.items,
    required this.goalsById,
    required this.accountsById,
  });

  final List<Transaction> items;
  final Map<String, Goal> goalsById;
  final Map<String, Account> accountsById;

  @override
  List<Object?> get props => [items, goalsById, accountsById];
}
