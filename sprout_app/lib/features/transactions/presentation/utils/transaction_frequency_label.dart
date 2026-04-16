import '../../domain/transaction_frequency.dart';

String transactionFrequencyLabel(TransactionFrequency f) {
  return switch (f) {
    TransactionFrequency.daily => 'Daily',
    TransactionFrequency.weekly => 'Weekly',
    TransactionFrequency.monthly => 'Monthly',
    TransactionFrequency.yearly => 'Yearly',
    TransactionFrequency.none => 'None',
  };
}

