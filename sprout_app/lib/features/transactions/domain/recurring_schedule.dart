import 'transaction_frequency.dart';

class RecurringSchedule {
  RecurringSchedule._();

  static DateTime next(DateTime from, TransactionFrequency frequency) {
    return switch (frequency) {
      TransactionFrequency.daily => from.add(const Duration(days: 1)),
      TransactionFrequency.weekly => from.add(const Duration(days: 7)),
      TransactionFrequency.monthly => addMonthsClamped(from, 1),
      TransactionFrequency.yearly => addYearsClamped(from, 1),
      TransactionFrequency.none => from,
    };
  }

  static DateTime nextAfter({
    required DateTime anchor,
    required TransactionFrequency frequency,
    required DateTime after,
  }) {
    var next = anchor;
    var guard = 0;
    while (!next.isAfter(after) && guard < 5000) {
      next = RecurringSchedule.next(next, frequency);
      guard++;
    }
    return next;
  }

  static DateTime? resolveNextScheduledDate({
    required bool enabled,
    required DateTime now,
    required DateTime occurredAt,
    required TransactionFrequency currentFrequency,
    required TransactionFrequency effectiveFrequency,
    DateTime? previousNext,
  }) {
    if (!enabled) return null;

    if (previousNext != null &&
        previousNext.isAfter(now) &&
        currentFrequency == effectiveFrequency) {
      return previousNext;
    }

    final anchor = previousNext ?? occurredAt;
    return nextAfter(anchor: anchor, frequency: effectiveFrequency, after: now);
  }

  static DateTime addMonthsClamped(DateTime from, int monthsToAdd) {
    final targetMonthIndex = (from.year * 12 + (from.month - 1)) + monthsToAdd;
    final year = targetMonthIndex ~/ 12;
    final month = (targetMonthIndex % 12) + 1;
    final day = clampDayOfMonth(year, month, from.day);
    return DateTime(
      year,
      month,
      day,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
      from.microsecond,
    );
  }

  static DateTime addYearsClamped(DateTime from, int yearsToAdd) {
    final year = from.year + yearsToAdd;
    final month = from.month;
    final day = clampDayOfMonth(year, month, from.day);
    return DateTime(
      year,
      month,
      day,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
      from.microsecond,
    );
  }

  static int clampDayOfMonth(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return day > lastDay ? lastDay : day;
  }

  static DateTime alignNext({
    required DateTime templateOccurredAt,
    required TransactionFrequency frequency,
    DateTime? nextScheduledDate,
    required DateTime base,
  }) {
    var next =
        nextScheduledDate ??
        RecurringSchedule.next(templateOccurredAt, frequency);
    var guard = 0;
    while (!next.isAfter(base) && guard < 5000) {
      next = RecurringSchedule.next(next, frequency);
      guard++;
    }
    return next;
  }
}
