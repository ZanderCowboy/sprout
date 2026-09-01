import 'transaction.dart';

class TransactionRules {
  TransactionRules._();

  /// Pending when the transaction's local calendar day is after today.
  static bool isPending(Transaction t, DateTime now) {
    final occurredLocal = t.occurredAt.toLocal();
    final nowLocal = now.toLocal();
    final occurredDay = DateTime(
      occurredLocal.year,
      occurredLocal.month,
      occurredLocal.day,
    );
    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    return occurredDay.isAfter(today);
  }

  static ({List<Transaction> scheduled, List<Transaction> history})
      splitScheduledAndHistory(
    List<Transaction> txs, {
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final scheduled = <Transaction>[];
    final history = <Transaction>[];
    for (final t in txs) {
      if (isPending(t, effectiveNow)) {
        scheduled.add(t);
      } else {
        history.add(t);
      }
    }
    scheduled.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    history.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return (scheduled: scheduled, history: history);
  }

  static void requireGoalIdForAllocation(String? goalId) {
    if (goalId == null || goalId.isEmpty) {
      throw ArgumentError.value(goalId, 'goalId', 'Required for allocations');
    }
  }
}
