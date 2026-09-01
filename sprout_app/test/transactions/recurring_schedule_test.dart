import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/features/transactions/domain/recurring_schedule.dart';
import 'package:sprout/features/transactions/domain/transaction_frequency.dart';

void main() {
  group('RecurringSchedule', () {
    test('monthly clamps day 31 to shorter months', () {
      final jan31 = DateTime(2026, 1, 31);
      final next = RecurringSchedule.next(jan31, TransactionFrequency.monthly);
      expect(next.month, 2);
      expect(next.day, 28);
    });

    test('nextAfter advances past anchor', () {
      final anchor = DateTime(2026, 1, 1);
      final after = DateTime(2026, 1, 15);
      final next = RecurringSchedule.nextAfter(
        anchor: anchor,
        frequency: TransactionFrequency.monthly,
        after: after,
      );
      expect(next.isAfter(after), isTrue);
    });

    test('resolveNextScheduledDate clears next date when disabled', () {
      final resolved = RecurringSchedule.resolveNextScheduledDate(
        enabled: false,
        now: DateTime(2026, 3, 1),
        occurredAt: DateTime(2026, 1, 27),
        currentFrequency: TransactionFrequency.monthly,
        effectiveFrequency: TransactionFrequency.monthly,
        previousNext: DateTime(2026, 3, 27),
      );
      expect(resolved, isNull);
    });

    test('resolveNextScheduledDate keeps future date on re-enable', () {
      final now = DateTime(2026, 3, 1);
      final previousNext = DateTime(2026, 3, 27);
      final resolved = RecurringSchedule.resolveNextScheduledDate(
        enabled: true,
        now: now,
        occurredAt: DateTime(2026, 1, 27),
        currentFrequency: TransactionFrequency.monthly,
        effectiveFrequency: TransactionFrequency.monthly,
        previousNext: previousNext,
      );
      expect(resolved, previousNext);
    });
  });
}
