import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/shell/shell.dart';
import 'package:sprout/features/transactions/export.dart';
import 'package:sprout/ui/export.dart';

import '../application/goals_service.dart';
import '../domain/goal.dart';
import 'goal_detail_bloc.dart';
import 'goal_form_sheet.dart';
import 'widgets/goal_growth_chart_view.dart';

class GoalDetailPage extends StatelessWidget {
  const GoalDetailPage({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GoalDetailBloc(
        goalsService: sl<GoalsService>(),
        transactionsService: sl<TransactionsService>(),
        accountsService: sl<AccountsService>(),
      )..add(GoalDetailSubscriptionRequested(goalId: goalId)),
      child: _GoalDetailView(goalId: goalId),
    );
  }
}

class _GoalDetailView extends StatelessWidget {
  const _GoalDetailView({required this.goalId});

  final String goalId;

  Future<void> _edit(BuildContext context, Goal goal) async {
    await showModalBottomSheet<Goal>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          GoalFormSheet(initial: goal, defaultColor: Color(goal.color)),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.delete),
        content: const Text(AppStrings.removeGoalConfirm),
        actions: SproutDialogActions.cancelDelete(
          onCancel: () => Navigator.pop(ctx, false),
          onDelete: () => Navigator.pop(ctx, true),
        ),
      ),
    );
    if (ok == true && context.mounted) {
      context.read<GoalDetailBloc>().add(const GoalDetailDeleteRequested());
    }
  }

  Future<void> _openDeposit(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DepositBottomSheet(
        initialGoalId: goalId,
        initialMode: DepositBottomSheetMode.fullDepositToGoal,
        lockGoalSelection: true,
        forceQuickGoalDepositUi: true,
        maxAllocatableCents: 1,
        showRecurringToggle: true,
      ),
    );
  }

  Future<void> _clearScheduledForGoal(
    BuildContext context,
    GoalDetailReady state,
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
            scope: 'goal',
          ),
        ),
        actions: SproutDialogActions.cancelDelete(
          onCancel: () => Navigator.pop(ctx, false),
          onDelete: () => Navigator.pop(ctx, true),
        ),
      ),
    );
    if (ok != true || !context.mounted) return;

    context.read<GoalDetailBloc>().add(
      GoalDetailClearScheduledRequested(transactionIds: scheduledIds),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GoalDetailBloc, GoalDetailState>(
      listenWhen: (previous, current) => current is GoalDetailDeleted,
      listener: (context, state) {
        Navigator.of(context).pop();
      },
      builder: (context, state) {
        if (state is! GoalDetailReady) {
          return Scaffold(
            appBar: AppBar(
              actions: [
                SproutIconButton(
                  identifier: SemanticsIds.goalDetailDelete,
                  label: AppStrings.delete,
                  onPressed: () => _delete(context),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final progress = state.progress;
        final g = progress.goal;

        return Scaffold(
          appBar: AppBar(
            title: Text(g.name),
            actions: [
              SproutIconButton(
                identifier: SemanticsIds.goalDetailEdit,
                label: AppStrings.edit,
                onPressed: () => _edit(context, g),
                icon: const Icon(Icons.edit_rounded),
              ),
              SproutIconButton(
                identifier: SemanticsIds.goalDetailDelete,
                label: AppStrings.delete,
                onPressed: () => _delete(context),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<GoalDetailBloc>().add(
                const GoalDetailRefreshRequested(),
              );
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                LinearProgressIndicator(
                  value: (progress.percentComplete / 100).clamp(0.0, 1.0),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                  color: Color(g.color),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${AppStrings.progress}: ${progress.percentComplete}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      AppStrings.savedSlashTarget(
                        formatZarFromCents(progress.savedCents),
                        formatZarFromCents(g.targetAmountCents),
                      ),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.remainingColon(
                    formatZarFromCents(progress.remainingCents),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 22),
                DetailDepositCallout(
                  identifier: SemanticsIds.goalDetailDeposit,
                  accentColor: Color(g.color),
                  caption: AppStrings.addDepositCaptionGoal,
                  onPressed: () => _openDeposit(context),
                ),
                RecurringDepositsLink(
                  visible: state.transactions.any(
                    TransactionRules.isRecurringDeposit,
                  ),
                  identifier: SemanticsIds.goalDetailRecurring,
                ),
                const SizedBox(height: 16),
                GoalGrowthChartView(
                  goalColor: Color(g.color),
                  goalCreatedAt: g.createdAt,
                  goalTargetCents: g.targetAmountCents,
                  points: state.graphPoints,
                  prediction: state.prediction,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.transactions,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (state.scheduledTransactions.isNotEmpty)
                      SproutTextButton.icon(
                        identifier: SemanticsIds.goalDetailClearScheduled,
                        label: AppStrings.clearScheduled,
                        onPressed: () => _clearScheduledForGoal(context, state),
                        icon: const Icon(Icons.delete_outline_rounded),
                        labelWidget: const Text(AppStrings.clearScheduled),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.transactions.isEmpty)
                  Text(
                    AppStrings.noDepositsTowardGoal,
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else ...[
                  _GoalTransactionSection(
                    title: AppStrings.scheduled,
                    items: state.scheduledTransactions,
                    accountsById: state.accountsById,
                  ),
                  _GoalTransactionSection(
                    title: AppStrings.history,
                    items: state.historyTransactions,
                    accountsById: state.accountsById,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GoalTransactionSection extends StatelessWidget {
  const _GoalTransactionSection({
    required this.title,
    required this.items,
    required this.accountsById,
  });

  final String title;
  final List<Transaction> items;
  final Map<String, Account> accountsById;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 4),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        ...items.map((t) {
          final accName =
              accountsById[t.accountId]?.name ?? AppStrings.unknownAccount;
          final style = mapTransactionToListStyle(t: t, now: now);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            clipBehavior: Clip.antiAlias,
            child: Opacity(
              opacity: style.opacity,
              child: SproutListTile(
                identifier: SemanticsIds.goalDetailTransactionRow,
                label:
                    '${AppStrings.deposit} ${formatZarFromCents(t.amountCents)}',
                leading: style.leadingIcon == null
                    ? null
                    : Icon(style.leadingIcon),
                title: Text(formatZarFromCents(t.amountCents)),
                subtitle: Text(
                  [
                    accName,
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
                  context.push(AppRoute.transactionDetail.location(id: t.id));
                },
              ),
            ),
          );
        }),
      ],
    );
  }
}
