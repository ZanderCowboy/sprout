part of 'recurring_payments_bloc.dart';

sealed class RecurringPaymentsEvent extends Equatable {
  const RecurringPaymentsEvent();
  @override
  List<Object?> get props => [];
}

final class RecurringPaymentsSubscriptionRequested
    extends RecurringPaymentsEvent {
  const RecurringPaymentsSubscriptionRequested();
}
