enum TransactionFrequency {
  none,
  daily,
  weekly,
  monthly,
  yearly;
}

extension TransactionFrequencyCodec on TransactionFrequency {
  String get wireName => switch (this) {
        TransactionFrequency.none => 'none',
        TransactionFrequency.daily => 'daily',
        TransactionFrequency.weekly => 'weekly',
        TransactionFrequency.monthly => 'monthly',
        TransactionFrequency.yearly => 'yearly',
      };

  static TransactionFrequency fromWireName(String? value) {
    return switch ((value ?? 'none').toLowerCase()) {
      'daily' => TransactionFrequency.daily,
      'weekly' => TransactionFrequency.weekly,
      'monthly' => TransactionFrequency.monthly,
      'yearly' => TransactionFrequency.yearly,
      _ => TransactionFrequency.none,
    };
  }
}

