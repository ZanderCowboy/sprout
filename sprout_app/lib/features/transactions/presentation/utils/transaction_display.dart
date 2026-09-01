import 'package:flutter/material.dart';

import 'package:sprout/core/constants/app_strings.dart';

import '../../domain/transaction.dart';
import '../../domain/transaction_rules.dart';

class TransactionDisplay {
  static bool isPendingByDate(Transaction t, DateTime now) =>
      TransactionRules.isPending(t, now);
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
    statusText: AppStrings.pending,
  );
}
