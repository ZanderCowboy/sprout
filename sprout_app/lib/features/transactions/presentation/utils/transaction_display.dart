import 'package:flutter/material.dart';

import '../../domain/transaction.dart';

class TransactionDisplay {
  static bool isPendingByDate(Transaction t, DateTime now) {
    // Compare by local calendar day, not raw timestamp, to avoid timezone skew
    // (e.g. UTC stored dates appearing “in the future” vs local now).
    final occurredLocal = t.occurredAt.toLocal();
    final nowLocal = now.toLocal();
    final occurredDay =
        DateTime(occurredLocal.year, occurredLocal.month, occurredLocal.day);
    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    return occurredDay.isAfter(today);
  }
}

class TransactionListStyle {
  const TransactionListStyle({
    required this.opacity,
    required this.leadingIcon,
    required this.statusText,
  });

  final double opacity;
  final IconData? leadingIcon;
  final String? statusText;
}

TransactionListStyle mapTransactionToListStyle({
  required Transaction t,
  required DateTime now,
}) {
  final pending = TransactionDisplay.isPendingByDate(t, now);
  if (!pending) {
    return const TransactionListStyle(
      opacity: 1,
      leadingIcon: null,
      statusText: null,
    );
  }
  return const TransactionListStyle(
    opacity: 0.65,
    leadingIcon: Icons.hourglass_bottom_rounded,
    statusText: 'Pending',
  );
}

