import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import '../../accounts/presentation/account_form_sheet.dart';
import '../../goals/export.dart';
import '../../shell/presentation/deposit_bottom_sheet.dart';
import '../../transactions/domain/transaction.dart';
import 'package:sprout/ui/export.dart';
import 'home_bloc.dart';
import 'widgets/empty_state_guidance.dart';

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

                          return OverallGoalsProgressHeader(
                            overallPercent: overallPercent,
                            totalSavedCents: totalSavedCents,
                            totalTargetCents: totalTargetCents,
                            totalRemainingCents: totalRemainingCents,
                            title: AppStrings.overallGoalsProgress,
                            onTap: () => context.go(AppRoute.goals.path),
                            semanticsIdentifier:
                                SemanticsIds.overviewProgressHeader,
                          );
                        },
                      ),
                      if (!hasAccounts) ...[
                        const SizedBox(height: 18),
                        EmptyStateGuidance(
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
