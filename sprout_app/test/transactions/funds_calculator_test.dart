import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/features/transactions/domain/funds_calculator.dart';
import 'package:sprout/features/transactions/domain/transaction.dart';

Transaction _deposit({
  required String accountId,
  String? goalId,
  required int cents,
  required DateTime occurredAt,
}) =>
    Transaction(
      id: '$accountId-$cents-${occurredAt.millisecondsSinceEpoch}',
      userId: 'u',
      accountId: accountId,
      kind: TransactionKind.deposit,
      goalId: goalId,
      amountCents: cents,
      occurredAt: occurredAt,
      pendingSync: false,
    );

Transaction _allocation({
  required String accountId,
  required String goalId,
  required int cents,
  required DateTime occurredAt,
}) =>
    Transaction(
      id: 'alloc-$goalId-$cents',
      userId: 'u',
      accountId: accountId,
      kind: TransactionKind.allocation,
      goalId: goalId,
      amountCents: cents,
      occurredAt: occurredAt,
      pendingSync: false,
    );

void main() {
  final now = DateTime(2026, 3, 15, 12);

  group('FundsCalculator', () {
    test('savedCentsByGoalId counts deposits and allocations', () {
      final txs = [
        _deposit(accountId: 'a', goalId: 'g1', cents: 500, occurredAt: now),
        _allocation(accountId: 'a', goalId: 'g1', cents: 200, occurredAt: now),
        _deposit(accountId: 'a', goalId: 'g2', cents: 100, occurredAt: now),
      ];

      final saved = FundsCalculator.savedCentsByGoalId(txs, now: now);

      expect(saved['g1'], 700);
      expect(saved['g2'], 100);
    });

    test('unallocatedCentsForAccount subtracts allocations from unallocated deposits', () {
      final txs = [
        _deposit(accountId: 'a', goalId: null, cents: 1000, occurredAt: now),
        _allocation(accountId: 'a', goalId: 'g1', cents: 300, occurredAt: now),
      ];

      expect(FundsCalculator.unallocatedCentsForAccount(txs, 'a', now: now), 700);
    });

    test('ignores pending transactions', () {
      final txs = [
        _deposit(
          accountId: 'a',
          goalId: null,
          cents: 1000,
          occurredAt: DateTime(2026, 3, 20),
        ),
      ];

      expect(FundsCalculator.unallocatedCentsForAccount(txs, 'a', now: now), 0);
    });

    test('portfolioSummary sums non-pending deposits', () {
      final txs = [
        _deposit(accountId: 'a', goalId: 'g', cents: 500, occurredAt: now),
        _deposit(
          accountId: 'a',
          goalId: null,
          cents: 200,
          occurredAt: DateTime(2026, 3, 20),
        ),
      ];

      final summary = FundsCalculator.portfolioSummary(txs, now: now);
      expect(summary.totalCents, 500);
    });
  });
}
