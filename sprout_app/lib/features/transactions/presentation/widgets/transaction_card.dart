import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';

import '../utils/transaction_frequency_label.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.transaction,
    required this.goalsById,
    required this.accountsById,
    required this.now,
  });

  final Transaction transaction;
  final Map<String, Goal> goalsById;
  final Map<String, Account> accountsById;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final accountName =
        accountsById[t.accountId]?.name ?? AppStrings.unknownAccount;
    final goalName = t.goalId == null
        ? AppStrings.unallocated
        : (goalsById[t.goalId!]?.name ?? AppStrings.unknownGoal);

    final title = formatZarFromCents(t.amountCents);
    final kindLabel = switch (t.kind) {
      TransactionKind.deposit => AppStrings.deposit,
      TransactionKind.allocation => AppStrings.allocation,
    };
    final style = mapTransactionToListStyle(t: t, now: now);

    final subtitleLines = <String>[
      AppStrings.kindSubtitle(kindLabel, accountName),
      '$goalName · ${formatDate(t.occurredAt)}'
          '${style.statusText != null ? ' · ${style.statusText!}' : ''}',
      if (t.isRecurring && t.frequency != TransactionFrequency.none)
        AppStrings.recurringDot(transactionFrequencyLabel(t.frequency)),
    ];

    return Semantics(
      identifier: SemanticsIds.transactionRow,
      button: true,
      label: title,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Opacity(
          opacity: style.opacity,
          child: InkWell(
            onTap: () {
              context.push(AppRoute.transactionDetail.location(id: t.id));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    style.leadingIcon ??
                        (t.kind == TransactionKind.deposit
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitleLines.join('\n'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
