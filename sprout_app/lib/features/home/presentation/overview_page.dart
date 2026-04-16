import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/money_format.dart';
import '../../accounts/presentation/account_form_sheet.dart';
import '../../goals/presentation/goals_bloc.dart';
import '../../goals/presentation/create_goal_screen.dart';
import '../../shell/presentation/shell_page.dart';
import '../../shell/presentation/deposit_bottom_sheet.dart';
import '../../transactions/domain/transaction.dart';
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
        final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            );

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
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
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

                          final totalTargetCents =
                              goalsState.progressList.fold<int>(
                            0,
                            (sum, p) => sum + p.goal.targetAmountCents,
                          );
                          final totalSavedCents =
                              goalsState.progressList.fold<int>(
                            0,
                            (sum, p) => sum + p.savedCents,
                          );
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
                            onTap: () {
                              ShellPage.maybeOf(context)?.setTabIndex(2);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Text(AppStrings.actionAdd, style: titleStyle),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: () => _openDeposit(context),
                              icon: const Icon(Icons.payments_outlined),
                              label: const Text(AppStrings.deposit),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openNewAccount(context),
                              icon: const Icon(
                                Icons.account_balance_wallet_outlined,
                              ),
                              label: const Text(AppStrings.newAccount),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openNewGoal(context),
                          icon: const Icon(Icons.flag_outlined),
                          label: const Text(AppStrings.newGoal),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (state.recentTransactions.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                    child: Text('Recent activity', style: titleStyle),
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
                        TransactionKind.deposit => 'Deposit',
                        TransactionKind.allocation => 'Allocation',
                      };
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: Icon(
                            t.kind == TransactionKind.deposit
                                ? Icons.payments_outlined
                                : Icons.swap_horiz_rounded,
                          ),
                          title: Text(formatZarFromCents(t.amountCents)),
                          subtitle: Text('$kindLabel · ${formatDateTime(t.occurredAt)}'),
                          trailing: t.pendingSync
                              ? Icon(
                                  Icons.sync_rounded,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
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
      button: onTap != null,
      label:
          'Overall goals progress. $overallPercent percent. Saved ${formatZarFromCents(totalSavedCents)} of ${formatZarFromCents(totalTargetCents)}.',
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
                        'Overall goals progress',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Text(
                      '$overallPercent%',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(8),
                  color: scheme.primary,
                  backgroundColor:
                      scheme.onSurfaceVariant.withValues(alpha: 0.18),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Saved ${formatZarFromCents(totalSavedCents)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Text(
                      'Target ${formatZarFromCents(totalTargetCents)}',
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
                        '${formatZarFromCents(totalRemainingCents)} to go to complete all goals.',
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

