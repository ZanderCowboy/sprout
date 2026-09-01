import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';

class TransactionAllocationRow extends StatelessWidget {
  const TransactionAllocationRow({
    super.key,
    required this.amount,
    required this.goalName,
    required this.occurredAt,
  });

  final String amount;
  final String goalName;
  final DateTime occurredAt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$goalName · ${formatDate(occurredAt)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          amount,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
