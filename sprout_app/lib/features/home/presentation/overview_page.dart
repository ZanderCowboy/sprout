import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/shell/shell.dart';
import 'package:sprout/ui/export.dart';
import 'home_bloc.dart';
import 'widgets/empty_state_guidance.dart';
import 'widgets/overview_activity_row.dart';
import 'widgets/overview_hero.dart';
import 'widgets/overview_quick_actions.dart';

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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SproutShellHeader(),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OverviewHero(
                          totalCents: state.portfolio.totalCents,
                          lastActivityAt: state.portfolio.lastActivityAt,
                        ),
                      ),
                      BlocBuilder<GoalsBloc, GoalsState>(
                        builder: (context, goalsState) {
                          if (goalsState is! GoalsReady ||
                              goalsState.progressList.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: OverallGoalsProgressHeader(
                              totals: goalsState.overall,
                              title: AppStrings.overallProgress,
                              onTap: () => context.go(AppRoute.goals.path),
                              semanticsIdentifier:
                                  SemanticsIds.overviewProgressHeader,
                            ),
                          );
                        },
                      ),
                      if (!hasAccounts) ...[
                        const SizedBox(height: 16),
                        EmptyStateGuidance(
                          onOpenAccount: () => _openNewAccount(context),
                          onOpenGoal: () => _openNewGoal(context),
                          onOpenDeposit: () => _openDeposit(context),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        OverviewQuickActions(
                          depositIdentifier: SemanticsIds.overviewDeposit,
                          accountIdentifier: SemanticsIds.overviewNewAccount,
                          goalIdentifier: SemanticsIds.overviewNewGoal,
                          onDeposit: () => _openDeposit(context),
                          onNewAccount: () => _openNewAccount(context),
                          onNewGoal: () => _openNewGoal(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (state.recentTransactions.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.recentActivity.toUpperCase(),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  letterSpacing: 1.4,
                                ),
                          ),
                        ),
                        SproutTextButton(
                          identifier: SemanticsIds.overviewSeeAllTransactions,
                          label: AppStrings.seeAll,
                          onPressed: () =>
                              context.push(AppRoute.transactions.path),
                        ),
                      ],
                    ),
                  ),
                ),
              if (state.recentTransactions.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  sliver: SliverList.separated(
                    itemCount: state.recentTransactions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      return OverviewActivityRow(
                        transaction: state.recentTransactions[i],
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
