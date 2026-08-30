import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import '../../accounts/presentation/account_form_sheet.dart';
import '../../goals/presentation/goals_bloc.dart';
import '../../goals/presentation/create_goal_screen.dart';
import '../../shell/presentation/deposit_bottom_sheet.dart';
import '../../transactions/domain/transaction.dart';
import 'package:sprout/ui/export.dart';
import 'home_bloc.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  Future<void> _openNewAccount(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AccountFormSheet(defaultColor: AppColors.cardColorAt(0)),
    );
  }

  Future<void> _openNewGoal(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CreateGoalScreen(defaultColor: AppColors.cardColorAt(1)),
    );
  }

  Future<void> _openDeposit(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const DepositBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is! HomeReady) {
          return const Center(child: CircularProgressIndicator());
        }

        final scheme = Theme.of(context).colorScheme;
        final titleStyle = Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);

        // Check if we need to show empty state guidance
        final hasAccounts = state.accounts.isNotEmpty;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<HomeBloc>().add(const HomeSubscriptionRequested());
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.portfolioTotal,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatZarFromCents(state.portfolio.totalCents),
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${AppStrings.lastUpdated}: ${state.portfolio.lastActivityAt != null ? formatDateTime(state.portfolio.lastActivityAt!) : AppStrings.neverUpdated}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      BlocBuilder<GoalsBloc, GoalsState>(
                        builder: (context, goalsState) {
                          if (goalsState is! GoalsReady ||
                              goalsState.progressList.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final totalTargetCents = goalsState.progressList
                              .fold<int>(
                                0,
                                (sum, p) => sum + p.goal.targetAmountCents,
                              );
                          final totalSavedCents = goalsState.progressList
                              .fold<int>(0, (sum, p) => sum + p.savedCents);
                          final totalRemainingCents =
                              (totalTargetCents - totalSavedCents) < 0
                              ? 0
                              : (totalTargetCents - totalSavedCents);
                          final overallPercent = totalTargetCents <= 0
                              ? 0
                              : (totalSavedCents * 100) ~/ totalTargetCents;

                          return _OverallGoalsProgressHeader(
                            overallPercent: overallPercent,
                            totalSavedCents: totalSavedCents,
                            totalTargetCents: totalTargetCents,
                            totalRemainingCents: totalRemainingCents,
                            onTap: () => context.go(AppRoute.goals.path),
                          );
                        },
                      ),
                      if (!hasAccounts) ...[
                        const SizedBox(height: 18),
                        _EmptyStateGuidance(
                          onOpenAccount: () => _openNewAccount(context),
                          onOpenGoal: () => _openNewGoal(context),
                          onOpenDeposit: () => _openDeposit(context),
                        ),
                      ] else ...[
                        const SizedBox(height: 18),
                        Text(AppStrings.actionAdd, style: titleStyle),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: SproutFilledButton.tonalIcon(
                                identifier: SemanticsIds.overviewDeposit,
                                label: AppStrings.deposit,
                                onPressed: () => _openDeposit(context),
                                icon: const Icon(Icons.payments_outlined),
                                labelWidget: const Text(AppStrings.deposit),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SproutOutlinedButton.icon(
                                identifier: SemanticsIds.overviewNewAccount,
                                label: AppStrings.newAccount,
                                onPressed: () => _openNewAccount(context),
                                icon: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                ),
                                labelWidget: const Text(AppStrings.newAccount),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: SproutOutlinedButton.icon(
                            identifier: SemanticsIds.overviewNewGoal,
                            label: AppStrings.newGoal,
                            onPressed: () => _openNewGoal(context),
                            icon: const Icon(Icons.flag_outlined),
                            labelWidget: const Text(AppStrings.newGoal),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (state.recentTransactions.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                    child: Text(AppStrings.recentActivity, style: titleStyle),
                  ),
                ),
              if (state.recentTransactions.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  sliver: SliverList.separated(
                    itemCount: state.recentTransactions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final t = state.recentTransactions[i];
                      final kindLabel = switch (t.kind) {
                        TransactionKind.deposit => AppStrings.deposit,
                        TransactionKind.allocation => AppStrings.allocation,
                      };
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: SproutListTile(
                          identifier: SemanticsIds.overviewTransactionRow,
                          label: AppStrings.kindAmountLabel(
                            kindLabel,
                            formatZarFromCents(t.amountCents),
                          ),
                          leading: Icon(
                            t.kind == TransactionKind.deposit
                                ? Icons.payments_outlined
                                : Icons.swap_horiz_rounded,
                          ),
                          title: Text(formatZarFromCents(t.amountCents)),
                          subtitle: Text(
                            AppStrings.kindSubtitle(
                              kindLabel,
                              formatDateTime(t.occurredAt),
                            ),
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
                      );
                    },
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        );
      },
    );
  }
}

class _OverallGoalsProgressHeader extends StatelessWidget {
  const _OverallGoalsProgressHeader({
    required this.overallPercent,
    required this.totalSavedCents,
    required this.totalTargetCents,
    required this.totalRemainingCents,
    this.onTap,
  });

  final int overallPercent;
  final int totalSavedCents;
  final int totalTargetCents;
  final int totalRemainingCents;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (overallPercent / 100).clamp(0.0, 1.0);

    return Semantics(
      identifier: SemanticsIds.overviewProgressHeader,
      button: onTap != null,
      label: AppStrings.overallGoalsProgressSemantics(
        percent: overallPercent,
        saved: formatZarFromCents(totalSavedCents),
        target: formatZarFromCents(totalTargetCents),
      ),
      child: Card(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_graph_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.overallGoalsProgress,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '$overallPercent%',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(8),
                  color: scheme.primary,
                  backgroundColor: scheme.onSurfaceVariant.withValues(
                    alpha: 0.18,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.savedAmount(
                          formatZarFromCents(totalSavedCents),
                        ),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      AppStrings.targetAmountLabel(
                        formatZarFromCents(totalTargetCents),
                      ),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.toGoCompleteAllGoals(
                          formatZarFromCents(totalRemainingCents),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStateGuidance extends StatelessWidget {
  const _EmptyStateGuidance({
    required this.onOpenAccount,
    required this.onOpenGoal,
    required this.onOpenDeposit,
  });

  final VoidCallback onOpenAccount;
  final VoidCallback onOpenGoal;
  final VoidCallback onOpenDeposit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800);
    final stepStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    final detailStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);

    return BlocBuilder<GoalsBloc, GoalsState>(
      builder: (context, goalsState) {
        final hasGoals =
            goalsState is GoalsReady && goalsState.progressList.isNotEmpty;

        return Card(
          elevation: 0,
          color: scheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  identifier: SemanticsIds.overviewEmptyTitle,
                  header: true,
                  child: Text(
                    AppStrings.overviewEmptyTitle,
                    key: const Key('overview_empty_title'),
                    style: titleStyle,
                  ),
                ),
                const SizedBox(height: 20),
                _GuidanceStep(
                  stepText: AppStrings.overviewEmptyStep1,
                  detailText: AppStrings.overviewEmptyStep1Detail,
                  icon: Icons.account_balance_wallet_outlined,
                  stepStyle: stepStyle,
                  detailStyle: detailStyle,
                  scheme: scheme,
                  actionLabel: AppStrings.newAccount,
                  onAction: onOpenAccount,
                  actionKey: const Key('overview_empty_new_account'),
                  actionIdentifier: SemanticsIds.overviewEmptyNewAccount,
                ),
                const SizedBox(height: 16),
                _GuidanceStep(
                  stepText: AppStrings.overviewEmptyStep2,
                  detailText: AppStrings.overviewEmptyStep2Detail,
                  icon: Icons.flag_outlined,
                  stepStyle: stepStyle,
                  detailStyle: detailStyle,
                  scheme: scheme,
                  actionLabel: AppStrings.newGoal,
                  onAction: onOpenGoal,
                  enabled: true,
                  actionKey: const Key('overview_empty_new_goal'),
                  actionIdentifier: SemanticsIds.overviewEmptyNewGoal,
                ),
                const SizedBox(height: 16),
                _GuidanceStep(
                  stepText: AppStrings.overviewEmptyStep3,
                  detailText: AppStrings.overviewEmptyStep3Detail,
                  icon: Icons.payments_outlined,
                  stepStyle: stepStyle,
                  detailStyle: detailStyle,
                  scheme: scheme,
                  actionLabel: AppStrings.deposit,
                  onAction: onOpenDeposit,
                  enabled: hasGoals,
                  actionKey: const Key('overview_empty_deposit'),
                  actionIdentifier: SemanticsIds.overviewEmptyDeposit,
                  disabledCaption: hasGoals
                      ? null
                      : AppStrings.overviewEmptyDepositDisabled,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GuidanceStep extends StatelessWidget {
  const _GuidanceStep({
    required this.stepText,
    required this.detailText,
    required this.icon,
    required this.stepStyle,
    required this.detailStyle,
    required this.scheme,
    required this.actionLabel,
    required this.onAction,
    this.enabled = true,
    this.actionKey,
    this.actionIdentifier,
    this.disabledCaption,
  });

  final String stepText;
  final String detailText;
  final IconData icon;
  final TextStyle? stepStyle;
  final TextStyle? detailStyle;
  final ColorScheme scheme;
  final String actionLabel;
  final VoidCallback onAction;
  final bool enabled;
  final Key? actionKey;
  final String? actionIdentifier;
  final String? disabledCaption;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stepText, style: stepStyle),
              const SizedBox(height: 4),
              Text(detailText, style: detailStyle),
              const SizedBox(height: 8),
              if (actionIdentifier != null)
                SproutTextButton.icon(
                  key: actionKey,
                  identifier: actionIdentifier!,
                  label: actionLabel,
                  onPressed: enabled ? onAction : null,
                  icon: Icon(Icons.add_rounded, size: 18),
                  labelWidget: Text(actionLabel),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                )
              else
                TextButton.icon(
                  key: actionKey,
                  onPressed: enabled ? onAction : null,
                  icon: Icon(Icons.add_rounded, size: 18),
                  label: Text(actionLabel),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              if (!enabled && disabledCaption != null) ...[
                const SizedBox(height: 4),
                Text(
                  disabledCaption!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
