import 'package:sprout/core/constants/app_strings.dart';

import '../../domain/transaction_frequency.dart';

String transactionFrequencyLabel(TransactionFrequency f) {
  return switch (f) {
    TransactionFrequency.daily => AppStrings.frequencyDaily,
    TransactionFrequency.weekly => AppStrings.frequencyWeekly,
    TransactionFrequency.monthly => AppStrings.frequencyMonthly,
    TransactionFrequency.yearly => AppStrings.frequencyYearly,
    TransactionFrequency.none => AppStrings.frequencyNone,
  };
}
