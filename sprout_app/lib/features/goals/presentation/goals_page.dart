import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/shell/shell.dart';
import 'package:sprout/ui/export.dart';
import 'goals_bloc.dart';
import 'enums/goals_sort.dart';
import 'utils/goals_sorting.dart';
import 'widgets/overall_goals_progress_header.dart';
import 'widgets/goals_section_separator.dart';
import 'widgets/unallocated_funds_card.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  GoalsSort _sort = GoalsSort.remainingLowToHigh;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoalsBloc, GoalsState>(
      builder: (context, state) {
        if (state is! GoalsReady) {
          return const Center(child: CircularProgressIndicator());
        }
        final scheme = Theme.of(context).colorScheme;
        final titleStyle = Theme.of(context).textTheme.titleLarge;
        if (state.progressList.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<GoalsBloc>().add(const GoalsSubscriptionRequested());
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Text(AppStrings.goals, style: titleStyle),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        AppStrings.goalsEmptyGuidance,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final totalTargetCents = state.progressList.fold<int>(
          0,
          (sum, p) => sum + p.goal.targetAmountCents,
        );
        final totalSavedCents = state.progressList.fold<int>(
          0,
          (sum, p) => sum + p.savedCents,
        );
        final totalRemainingCents = (totalTargetCents - totalSavedCents) < 0
            ? 0
            : (totalTargetCents - totalSavedCents);
        final overallPercent = totalTargetCents <= 0
            ? 0
            : (totalSavedCents * 100) ~/ totalTargetCents;
        final sorted = sortGoals(state.progressList, _sort);
        final firstCompletedIndex = sorted.indexWhere(
          (p) => p.percentComplete >= 100,
        );
        final hasCompleted = firstCompletedIndex != -1;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<GoalsBloc>().add(const GoalsSubscriptionRequested());
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(AppStrings.goals, style: titleStyle),
                      ),
                      Semantics(
                        identifier: SemanticsIds.goalSortMenu,
                        button: true,
                        label: AppStrings.sortGoals,
                        child: PopupMenuButton<GoalsSort>(
                          tooltip: AppStrings.sortGoals,
                          initialValue: _sort,
                          onSelected: (s) => setState(() => _sort = s),
                          itemBuilder: (context) {
                            return GoalsSort.values
                                .map(
                                  (s) => PopupMenuItem<GoalsSort>(
                                    value: s,
                                    child: Text(goalsSortLabel(s)),
                                  ),
                                )
                                .toList();
                          },
                          icon: const Icon(Icons.sort_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: OverallGoalsProgressHeader(
                    overallPercent: overallPercent,
                    totalSavedCents: totalSavedCents,
                    totalTargetCents: totalTargetCents,
                    totalRemainingCents: totalRemainingCents,
                    title: AppStrings.overallProgress,
                  ),
                ),
              ),
              if (state.unallocatedBalanceCents > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: UnallocatedFundsCard(
                      unallocatedCents: state.unallocatedBalanceCents,
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (_) => DepositBottomSheet(
                            maxAllocatableCents: state.unallocatedBalanceCents,
                            initialMode: DepositBottomSheetMode
                                .allocateExistingUnallocated,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                sliver: SliverList.separated(
                  itemCount: sorted.length + (hasCompleted ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    if (hasCompleted && i == firstCompletedIndex) {
                      return GoalsSectionSeparator(title: AppStrings.completed);
                    }
                    final idx = (hasCompleted && i > firstCompletedIndex)
                        ? i - 1
                        : i;
                    final p = sorted[idx];
                    final g = p.goal;
                    return ColoredEntityCard(
                      identifier: SemanticsIds.goalCard,
                      semanticsLabel: AppStrings.goalCardSemantics(
                        name: g.name,
                        remaining: formatZarFromCents(p.remainingCents),
                        saved: formatZarFromCents(p.savedCents),
                        target: formatZarFromCents(g.targetAmountCents),
                        percent: p.percentComplete,
                      ),
                      title: AppStrings.remainingColon(
                        formatZarFromCents(p.remainingCents),
                      ),
                      subtitle:
                          '${g.name}\n${AppStrings.savedSlashTarget(formatZarFromCents(p.savedCents), formatZarFromCents(g.targetAmountCents))}',
                      color: Color(g.color),
                      onTap: () {
                        context.push(AppRoute.goalDetail.location(id: g.id));
                      },
                      trailing: SizedBox(
                        width: 56,
                        height: 56,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: (p.percentComplete / 100).clamp(0.0, 1.0),
                              strokeWidth: 5,
                              backgroundColor: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.8),
                              color: Color(g.color),
                            ),
                            Text(
                              '${p.percentComplete}%',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
