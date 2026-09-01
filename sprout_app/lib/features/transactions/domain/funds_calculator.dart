import 'portfolio_summary.dart';
import 'transaction.dart';
import 'transaction_rules.dart';

class FundsCalculator {
  FundsCalculator._();

  static PortfolioSummary portfolioSummary(
    Iterable<Transaction> transactions, {
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    var total = 0;
    DateTime? last;
    for (final t in transactions) {
      if (TransactionRules.isPending(t, effectiveNow)) continue;
      if (t.kind == TransactionKind.deposit) {
        total += t.amountCents;
      }
      if (last == null || t.occurredAt.isAfter(last)) {
        last = t.occurredAt;
      }
    }
    return PortfolioSummary(totalCents: total, lastActivityAt: last);
  }

  static Map<String, int> savedCentsByGoalId(
    Iterable<Transaction> transactions, {
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final result = <String, int>{};
    for (final t in transactions) {
      if (TransactionRules.isPending(t, effectiveNow)) continue;
      final gid = t.goalId;
      if (gid == null || gid.isEmpty) continue;
      switch (t.kind) {
        case TransactionKind.deposit:
        case TransactionKind.allocation:
          result[gid] = (result[gid] ?? 0) + t.amountCents;
      }
    }
    return result;
  }

  static int savedCentsForGoal(
    Iterable<Transaction> transactions,
    String goalId, {
    DateTime? now,
  }) =>
      savedCentsByGoalId(transactions, now: now)[goalId] ?? 0;

  static int unallocatedCentsForAccount(
    Iterable<Transaction> transactions,
    String accountId, {
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    var depositedUnallocated = 0;
    var allocated = 0;
    for (final t in transactions) {
      if (t.accountId != accountId) continue;
      if (TransactionRules.isPending(t, effectiveNow)) continue;
      switch (t.kind) {
        case TransactionKind.deposit:
          final gid = t.goalId;
          if (gid == null || gid.isEmpty) {
            depositedUnallocated += t.amountCents;
          }
        case TransactionKind.allocation:
          allocated += t.amountCents;
      }
    }
    final available = depositedUnallocated - allocated;
    return available > 0 ? available : 0;
  }

  static int totalUnallocatedCents(
    Iterable<Transaction> transactions,
    Iterable<String> accountIds, {
    DateTime? now,
  }) {
    var total = 0;
    for (final accountId in accountIds) {
      total += unallocatedCentsForAccount(transactions, accountId, now: now);
    }
    return total;
  }

  static int accountDepositTotalCents(
    Iterable<Transaction> txs, {
    bool scheduledOnly = false,
    bool historyOnly = false,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    var totalDeposits = 0;
    for (final t in txs) {
      if (t.kind != TransactionKind.deposit) continue;
      final isPending = TransactionRules.isPending(t, effectiveNow);
      if (scheduledOnly && !isPending) continue;
      if (historyOnly && isPending) continue;
      totalDeposits += t.amountCents;
    }
    return totalDeposits > 0 ? totalDeposits : 0;
  }

  static Map<String, int> accountDepositTotalsById(
    Iterable<Transaction> txs, {
    required bool scheduled,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final result = <String, int>{};
    for (final t in txs) {
      if (t.kind != TransactionKind.deposit) continue;
      final isPending = TransactionRules.isPending(t, effectiveNow);
      if (scheduled != isPending) continue;
      result[t.accountId] = (result[t.accountId] ?? 0) + t.amountCents;
    }
    return result;
  }
}
