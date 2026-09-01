import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/accounts/presentation/bloc/account_detail_event.dart';
import 'package:sprout/features/accounts/presentation/bloc/account_detail_state.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/shell/shell.dart';
import 'package:sprout/features/transactions/export.dart';
import 'package:sprout/ui/export.dart';

import '../application/accounts_service.dart';
import '../domain/account.dart';
import 'bloc/account_detail_bloc.dart';
import 'account_form_sheet.dart';

class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AccountDetailBloc(
        accountsService: sl<AccountsService>(),
        transactionsService: sl<TransactionsService>(),
        goalsService: sl<GoalsService>(),
      )..add(AccountDetailSubscriptionRequested(accountId: accountId)),
      child: _AccountDetailView(accountId: accountId),
    );
  }
}

class _AccountDetailView extends StatelessWidget {
  const _AccountDetailView({required this.accountId});

  final String accountId;

  Future<void> _edit(BuildContext context, Account account) async {
    final updated = await showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AccountFormSheet(
        initial: account,
        defaultColor: Color(account.color),
      ),
    );
    if (updated != null && context.mounted) {
      await sl<AccountsService>().saveAccount(updated);
    }
  }

  Future<void> _delete(BuildContext context, Account account) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.delete),
        content: const Text(AppStrings.removeAccountConfirm),
        actions: SproutDialogActions.cancelDelete(
          onCancel: () => Navigator.pop(ctx, false),
          onDelete: () => Navigator.pop(ctx, true),
        ),
      ),
    );
    if (ok == true && context.mounted) {
      await sl<AccountsService>().removeAccount(account.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _openDeposit(BuildContext context, Account account) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DepositBottomSheet(
        initialAccountId: account.id,
        initialMode: DepositBottomSheetMode.depositToAccountThenAllocate,
        lockAccountSelection: true,
        forceQuickAccountDepositUi: true,
        showRecurringToggle: false,
      ),
    );
  }

  Future<void> _clearScheduled(
    BuildContext context,
    AccountDetailReady state,
  ) async {
    final scheduledIds = state.scheduledTransactions.map((t) => t.id).toList();
    if (scheduledIds.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.clearScheduledTransactions),
        content: Text(
          AppStrings.clearScheduledBody(
            count: scheduledIds.length,
            scope: 'account',
          ),
        ),
        actions: SproutDialogActions.cancelDelete(
          onCancel: () => Navigator.pop(ctx, false),
          onDelete: () => Navigator.pop(ctx, true),
        ),
      ),
    );
    if (ok != true || !context.mounted) return;

    final tx = sl<TransactionsService>();
    for (final id in scheduledIds) {
      await tx.deleteTransaction(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountDetailBloc, AccountDetailState>(
      builder: (context, state) {
        if (state is AccountDetailLoading || state is AccountDetailInitial) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AccountDetailNotFound) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text(AppStrings.accountNotFound)),
          );
        }

        if (state is! AccountDetailReady) {
          return Scaffold(appBar: AppBar());
        }

        final account = state.account;
        final now = DateTime.now();

        return Scaffold(
          appBar: AppBar(
            title: Text(account.name),
            actions: [
              SproutIconButton(
                identifier: SemanticsIds.accountDetailEdit,
                label: AppStrings.edit,
                onPressed: () => _edit(context, account),
                icon: const Icon(Icons.edit_rounded),
              ),
              SproutIconButton(
                identifier: SemanticsIds.accountDetailDelete,
                label: AppStrings.delete,
                onPressed: () => _delete(context, account),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await sl<AccountsService>().pullRemote();
              await sl<TransactionsService>().pullRemote();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                DetailDepositCallout(
                  identifier: SemanticsIds.accountDetailDeposit,
                  accentColor: Color(account.color),
                  caption: AppStrings.addDepositCaptionAccountAmountOnly,
                  onPressed: () => _openDeposit(context, account),
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
                            if (state.scheduledTotalCents > 0)
                              SproutTextButton.icon(
                                identifier:
                                    SemanticsIds.accountDetailClearScheduled,
                                label: AppStrings.clearScheduled,
                                onPressed: () =>
                                    _clearScheduled(context, state),
                                icon: const Icon(Icons.delete_outline_rounded),
                                labelWidget: const Text(
                                  AppStrings.clearScheduled,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _ValueRow(
                          label: AppStrings.current,
                          value: formatZarFromCents(state.currentTotalCents),
                        ),
                        const SizedBox(height: 6),
                        _ValueRow(
                          label: AppStrings.scheduled,
                          value: formatZarFromCents(state.scheduledTotalCents),
                        ),
                        const Divider(height: 18),
                        _ValueRow(
                          label: AppStrings.total,
                          value: formatZarFromCents(state.grandTotalCents),
                          isEmphasis: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.transactions,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (state.transactions.isEmpty)
                  Text(
                    AppStrings.noDepositsForAccount,
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  ...state.transactions.map((t) {
                    final goalName = t.goalId == null || t.goalId!.isEmpty
                        ? AppStrings.unallocated
                        : (state.goalsById[t.goalId!]?.name ??
                              AppStrings.unknownGoal);
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
          ),
        );
      },
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  final String label;
  final String value;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final valueStyle =
        (isEmphasis ? Theme.of(context).textTheme.titleMedium : style)
            ?.copyWith(
              fontWeight: isEmphasis ? FontWeight.w900 : FontWeight.w700,
            );
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: style?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(value, style: valueStyle),
      ],
    );
  }
}
