import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/shell/shell.dart';
import 'package:sprout/ui/export.dart';
import 'goals_bloc.dart';
import 'enums/goals_sort.dart';
import 'utils/goals_sorting.dart';
import 'widgets/goal_icon_picker.dart';
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

  Widget _sortButton() {
    return Semantics(
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
    );
  }

  Widget _header() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SproutShellHeader(trailing: _sortButton()),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.goals, style: textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  AppStrings.goalsSubtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoalsBloc, GoalsState>(
      builder: (context, state) {
        if (state is! GoalsReady) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.progressList.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<GoalsBloc>().add(const GoalsSubscriptionRequested());
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _header()),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
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
              SliverToBoxAdapter(child: _header()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: OverallGoalsProgressHeader(
                    totals: state.overall,
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
                      const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (hasCompleted && i == firstCompletedIndex) {
                      return GoalsSectionSeparator(title: AppStrings.completed);
                    }
                    final idx = (hasCompleted && i > firstCompletedIndex)
                        ? i - 1
                        : i;
                    final p = sorted[idx];
                    final g = p.goal;
                    return ColoredEntityCard.goal(
                      identifier: SemanticsIds.goalCard,
                      semanticsLabel: AppStrings.goalCardSemantics(
                        name: g.name,
                        remaining: formatZarFromCents(p.remainingCents),
                        saved: formatZarFromCents(p.savedCents),
                        target: formatZarFromCents(g.targetAmountCents),
                        percent: p.percentComplete,
                      ),
                      title: g.name,
                      subtitle: AppStrings.amountSlashAmount(
                        formatZarFromCents(p.savedCents),
                        formatZarFromCents(g.targetAmountCents),
                      ),
                      color: Color(g.color),
                      leadingIcon: goalIconFromStored(
                        codePoint: g.iconCodePoint,
                      ),
                      progress: (p.percentComplete / 100).clamp(0.0, 1.0),
                      progressLabel: '${p.percentComplete}%',
                      onTap: () {
                        context.push(AppRoute.goalDetail.location(id: g.id));
                      },
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
