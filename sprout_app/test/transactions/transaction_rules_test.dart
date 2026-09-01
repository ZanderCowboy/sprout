import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/features/transactions/domain/transaction.dart';
import 'package:sprout/features/transactions/domain/transaction_rules.dart';

Transaction _tx({required DateTime occurredAt}) => Transaction(
      id: '1',
      userId: 'u',
      accountId: 'a',
      kind: TransactionKind.deposit,
      amountCents: 100,
      occurredAt: occurredAt,
      pendingSync: false,
    );

void main() {
  group('TransactionRules.isPending', () {
    test('uses calendar day not timestamp', () {
      final now = DateTime(2026, 3, 15, 10, 0);
      final sameDayEarlier = DateTime(2026, 3, 15, 23, 59);
      final tomorrow = DateTime(2026, 3, 16, 0, 1);

      expect(TransactionRules.isPending(_tx(occurredAt: sameDayEarlier), now), isFalse);
      expect(TransactionRules.isPending(_tx(occurredAt: tomorrow), now), isTrue);
    });
  });

  group('TransactionRules.splitScheduledAndHistory', () {
    test('partitions and sorts', () {
      final now = DateTime(2026, 3, 15, 12);
      final txs = [
        _tx(occurredAt: DateTime(2026, 3, 10)),
        _tx(occurredAt: DateTime(2026, 3, 20)),
        _tx(occurredAt: DateTime(2026, 3, 14)),
      ];

      final split = TransactionRules.splitScheduledAndHistory(txs, now: now);

      expect(split.history, hasLength(2));
      expect(split.scheduled, hasLength(1));
      expect(split.history.first.occurredAt.day, 14);
      expect(split.scheduled.single.occurredAt.day, 20);
    });
  });
}
