import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/shell/shell.dart';
import 'package:sprout/features/transactions/export.dart';
import 'package:sprout/ui/export.dart';

import '../../domain/account.dart';
import 'account_value_row.dart';

class AccountDetailView extends StatelessWidget {
  const AccountDetailView({
    super.key,
    required this.account,
    required this.transactions,
    required this.goals,
    required this.currentTotalCents,
    required this.scheduledTotalCents,
    required this.grandTotalCents,
    required this.onRefresh,
    required this.onDeposit,
    required this.onClearScheduled,
  });

  final Account account;
  final List<Transaction> transactions;
  final Map<String, Goal> goals;
  final int currentTotalCents;
  final int scheduledTotalCents;
  final int grandTotalCents;
  final Future<void> Function() onRefresh;
  final VoidCallback onDeposit;
  final VoidCallback onClearScheduled;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          DetailDepositCallout(
            identifier: SemanticsIds.accountDetailDeposit,
            accentColor: Color(account.color),
            caption: AppStrings.addDepositCaptionAccountAmountOnly,
            onPressed: onDeposit,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.accountValue,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (scheduledTotalCents > 0)
                        SproutTextButton.icon(
                          identifier: SemanticsIds.accountDetailClearScheduled,
                          label: AppStrings.clearScheduled,
                          onPressed: onClearScheduled,
                          icon: const Icon(Icons.delete_outline_rounded),
                          labelWidget: const Text(AppStrings.clearScheduled),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AccountValueRow(
                    label: AppStrings.current,
                    value: formatZarFromCents(currentTotalCents),
                  ),
                  const SizedBox(height: 6),
                  AccountValueRow(
                    label: AppStrings.scheduled,
                    value: formatZarFromCents(scheduledTotalCents),
                  ),
                  const Divider(height: 18),
                  AccountValueRow(
                    label: AppStrings.total,
                    value: formatZarFromCents(grandTotalCents),
                    isEmphasis: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.transactions,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            Text(
              AppStrings.noDepositsForAccount,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...transactions.map((t) {
              final goalName = t.goalId == null || t.goalId!.isEmpty
                  ? AppStrings.unallocated
                  : (goals[t.goalId!]?.name ?? AppStrings.unknownGoal);
              final kindLabel = switch (t.kind) {
                TransactionKind.deposit => AppStrings.deposit,
                TransactionKind.allocation => AppStrings.allocation,
              };
              final style = mapTransactionToListStyle(t: t, now: now);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: Opacity(
                  opacity: style.opacity,
                  child: SproutListTile(
                    identifier: SemanticsIds.accountDetailTransactionRow,
                    label: AppStrings.kindAmountLabel(
                      kindLabel,
                      formatZarFromCents(t.amountCents),
                    ),
                    leading: style.leadingIcon == null
                        ? null
                        : Icon(style.leadingIcon),
                    title: Text(formatZarFromCents(t.amountCents)),
                    subtitle: Text(
                      [
                        kindLabel,
                        goalName,
                        formatDateTime(t.occurredAt),
                        if (style.statusText != null) style.statusText!,
                      ].join(' · '),
                    ),
                    trailing: t.pendingSync
                        ? Icon(
                            Icons.sync_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      context.push(
                        AppRoute.transactionDetail.location(id: t.id),
                      );
                    },
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
