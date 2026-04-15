import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/settings/presentation/settings_page.dart';
import 'package:sprout/features/shell/shell.dart';
import '../domain/goal_progress.dart';
import 'goal_detail_page.dart';
import 'goals_bloc.dart';
import 'widgets/unallocated_funds_card.dart';

enum GoalsSort {
  remainingLowToHigh,
  progressHighToLow,
  nameAToZ,
}

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  GoalsSort _sort = GoalsSort.remainingLowToHigh;

  String _sortLabel(GoalsSort s) {
    return switch (s) {
      GoalsSort.remainingLowToHigh => 'Remaining (low → high)',
      GoalsSort.progressHighToLow => 'Progress (high → low)',
      GoalsSort.nameAToZ => 'Name (A → Z)',
    };
  }

  List<GoalProgress> _sorted(List<GoalProgress> input) {
    final list = [...input];

    // Always push completed goals to the bottom by default (>= 100%),
    // regardless of the selected sort.
    list.sort((a, b) {
      final aDone = a.percentComplete >= 100;
      final bDone = b.percentComplete >= 100;
      if (aDone != bDone) return aDone ? 1 : -1;

      int byName() {
        return a.goal.name.trim().toLowerCase().compareTo(
              b.goal.name.trim().toLowerCase(),
            );
      }

      int byRemaining() => a.remainingCents.compareTo(b.remainingCents);
      int byProgressDesc() => b.percentComplete.compareTo(a.percentComplete);

      // Primary comparator chosen by user; secondary tie-breakers ensure we
      // still get a deterministic visible re-order even when many values match.
      final primary = switch (_sort) {
        GoalsSort.remainingLowToHigh => byRemaining(),
        GoalsSort.progressHighToLow => byProgressDesc(),
        GoalsSort.nameAToZ => byName(),
      };
      if (primary != 0) return primary;

      final secondary = switch (_sort) {
        GoalsSort.remainingLowToHigh => byName(),
        GoalsSort.progressHighToLow => byRemaining(),
        GoalsSort.nameAToZ => byRemaining(),
      };
      if (secondary != 0) return secondary;

      return a.goal.id.compareTo(b.goal.id);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoalsBloc, GoalsState>(
      builder: (context, state) {
        if (state is! GoalsReady) {
          return const Center(child: CircularProgressIndicator());
        }
        final scheme = Theme.of(context).colorScheme;
        final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            );
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
                    child: Text(
                      'Tap + to add a goal.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
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
        final sorted = _sorted(state.progressList);
        final firstCompletedIndex =
            sorted.indexWhere((p) => p.percentComplete >= 100);
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
                      Expanded(child: Text(AppStrings.goals, style: titleStyle)),
                      PopupMenuButton<GoalsSort>(
                        tooltip: 'Sort goals',
                        initialValue: _sort,
                        onSelected: (s) => setState(() => _sort = s),
                        itemBuilder: (context) {
                          return GoalsSort.values
                              .map(
                                (s) => PopupMenuItem<GoalsSort>(
                                  value: s,
                                  child: Text(_sortLabel(s)),
                                ),
                              )
                              .toList();
                        },
                        icon: const Icon(Icons.sort_rounded),
                      ),
                      IconButton(
                        tooltip: 'Settings',
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SettingsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _OverallGoalsProgressHeader(
                    overallPercent: overallPercent,
                    totalSavedCents: totalSavedCents,
                    totalTargetCents: totalTargetCents,
                    totalRemainingCents: totalRemainingCents,
                  ),
                ),
              ),
              if (state.unallocatedBalance > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: UnallocatedFundsCard(
                      unallocatedCents: (state.unallocatedBalance * 100).round(),
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (_) => DepositBottomSheet(
                            maxAllocatableCents:
                                (state.unallocatedBalance * 100).round(),
                            initialMode:
                                DepositBottomSheetMode.allocateExistingUnallocated,
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
                      return _GoalsSectionSeparator(
                        title: 'Completed',
                      );
                    }
                    final idx = (hasCompleted && i > firstCompletedIndex)
                        ? i - 1
                        : i;
                    final p = sorted[idx];
                    final g = p.goal;
                    return Semantics(
                      button: true,
                      label:
                          '${g.name}. ${AppStrings.remaining} ${formatZarFromCents(p.remainingCents)}. '
                          'Saved ${formatZarFromCents(p.savedCents)} of ${formatZarFromCents(g.targetAmountCents)}. '
                          '${AppStrings.progress} ${p.percentComplete} percent.',
                      child: ColoredEntityCard(
                        title:
                            '${AppStrings.remaining}: ${formatZarFromCents(p.remainingCents)}',
                        subtitle:
                            '${g.name}\nSaved: ${formatZarFromCents(p.savedCents)} / ${formatZarFromCents(g.targetAmountCents)}',
                        color: Color(g.color),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => GoalDetailPage(progress: p),
                            ),
                          );
                        },
                        trailing: SizedBox(
                          width: 56,
                          height: 56,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value:
                                    (p.percentComplete / 100).clamp(0.0, 1.0),
                                strokeWidth: 5,
                                backgroundColor: scheme.surfaceContainerHighest
                                    .withValues(alpha: 0.8),
                                color: Color(g.color),
                              ),
                              Text(
                                '${p.percentComplete}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
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

class _GoalsSectionSeparator extends StatelessWidget {
  const _GoalsSectionSeparator({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallGoalsProgressHeader extends StatelessWidget {
  const _OverallGoalsProgressHeader({
    required this.overallPercent,
    required this.totalSavedCents,
    required this.totalTargetCents,
    required this.totalRemainingCents,
  });

  final int overallPercent;
  final int totalSavedCents;
  final int totalTargetCents;
  final int totalRemainingCents;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (overallPercent / 100).clamp(0.0, 1.0);

    return Semantics(
      label:
          'Overall goals progress. $overallPercent percent. Saved ${formatZarFromCents(totalSavedCents)} of ${formatZarFromCents(totalTargetCents)}.',
      child: Card(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
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
                      'Overall progress',
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
                backgroundColor: scheme.onSurfaceVariant.withValues(alpha: 0.18),
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
              Text(
                '${formatZarFromCents(totalRemainingCents)} to go to complete all goals.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
