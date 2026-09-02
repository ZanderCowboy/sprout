import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/theme/app_radii.dart';
import 'package:sprout/features/transactions/export.dart';
import 'package:sprout/ui/export.dart';

class OverviewActivityRow extends StatelessWidget {
  const OverviewActivityRow({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final t = transaction;
    final kindLabel = switch (t.kind) {
      TransactionKind.deposit => AppStrings.deposit,
      TransactionKind.allocation => AppStrings.allocation,
    };
    final amount = formatZarFromCents(t.amountCents);

    return Semantics(
      identifier: SemanticsIds.overviewTransactionRow,
      button: true,
      label: AppStrings.kindAmountLabel(kindLabel, amount),
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: InkWell(
          onTap: () {
            context.push(AppRoute.transactionDetail.location(id: t.id));
          },
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SproutGlowIcon(
                  icon: t.kind == TransactionKind.deposit
                      ? Icons.arrow_downward_rounded
                      : Icons.sync_alt_rounded,
                  color: t.kind == TransactionKind.deposit
                      ? AppColors.seed
                      : scheme.onSurfaceVariant,
                  iconSize: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kindLabel, style: textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        formatDate(t.occurredAt),
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(amount, style: textTheme.titleSmall),
                if (t.pendingSync) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: AppStrings.pendingSync,
                    child: Icon(
                      Icons.sync_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
