import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/shell/shell.dart';
import 'package:sprout/features/transactions/export.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../application/goals_service.dart';
import '../domain/goal.dart';
import '../domain/goal_progress.dart';
import 'goal_detail_bloc.dart';
import 'utils/goal_growth_chart.dart';
import 'goal_form_sheet.dart';

class GoalDetailPage extends StatefulWidget {
  const GoalDetailPage({super.key, required this.progress});

  final GoalProgress progress;

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _edit() async {
    final goal = await showModalBottomSheet<Goal>(
      context: context,
      isScrollControlled: true,
      builder: (_) => GoalFormSheet(
        initial: widget.progress.goal,
        defaultColor: Color(widget.progress.goal.color),
      ),
    );
    if (goal != null && mounted) {}
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.delete),
        content: const Text(
          'Remove this goal? Past deposits stay in your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await sl<GoalsService>().removeGoal(widget.progress.goal.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _openDeposit() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DepositBottomSheet(
        initialGoalId: widget.progress.goal.id,
        initialMode: DepositBottomSheetMode.fullDepositToGoal,
        lockGoalSelection: true,
        forceQuickGoalDepositUi: true,
        // We want the goal-detail flow to allow allocating existing unallocated
        // funds, but the actual available amount is account-dependent and is
        // computed inside the sheet.
        maxAllocatableCents: 1,
        showRecurringToggle: true,
      ),
    );
    if (mounted) {}
  }

  Future<void> _clearScheduledForGoal(
    GoalDetailReady state, {
    required String goalId,
  }) async {
    final now = DateTime.now();
    final scheduledIds = state.transactions
        .where((t) => t.goalId == goalId)
        .where((t) => TransactionDisplay.isPendingByDate(t, now))
        .map((t) => t.id)
        .toList(growable: false);
    if (scheduledIds.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear scheduled transactions?'),
        content: Text(
          'This will remove ${scheduledIds.length} future-dated '
          'transaction${scheduledIds.length == 1 ? '' : 's'} from this goal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final tx = sl<TransactionsService>();
    for (final id in scheduledIds) {
      await tx.deleteTransaction(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GoalDetailBloc(
        goalsService: sl<GoalsService>(),
        transactionsService: sl<TransactionsService>(),
        accountsService: sl<AccountsService>(),
      )..add(
          GoalDetailSubscriptionRequested(goalId: widget.progress.goal.id),
        ),
      child: BlocBuilder<GoalDetailBloc, GoalDetailState>(
        builder: (context, state) {
          final progress = switch (state) {
            GoalDetailReady s => s.progress,
            _ => widget.progress,
          };
          final g = progress.goal;

          return Scaffold(
            appBar: AppBar(
              title: Text(g.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: _edit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _delete,
                ),
              ],
            ),
            body: () {
              if (state is! GoalDetailReady) {
                return const Center(child: CircularProgressIndicator());
              }
              final ready = state;
              return RefreshIndicator(
                onRefresh: () async {
                  await sl<GoalsService>().pullRemote();
                  await sl<TransactionsService>().pullRemote();
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    LinearProgressIndicator(
                          value: (progress.percentComplete / 100)
                              .clamp(0.0, 1.0),
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
                              'Saved: ${formatZarFromCents(progress.savedCents)} / '
                              '${formatZarFromCents(g.targetAmountCents)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${AppStrings.remaining}: ${formatZarFromCents(progress.remainingCents)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 22),
                        DetailDepositCallout(
                          accentColor: Color(g.color),
                          caption: AppStrings.addDepositCaptionGoal,
                          onPressed: _openDeposit,
                        ),
                        const SizedBox(height: 16),
                        _GoalGrowthChart(
                          goalColor: Color(g.color),
                          goalCreatedAt: g.createdAt,
                          goalTargetCents: g.targetAmountCents,
                          points: ready.graphPoints,
                          prediction: ready.prediction,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppStrings.transactions,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (ready.transactions.any(
                                  (t) => TransactionDisplay.isPendingByDate(
                                    t,
                                    DateTime.now(),
                                  ),
                                ))
                              TextButton.icon(
                                onPressed: () => _clearScheduledForGoal(
                                  ready,
                                  goalId: g.id,
                                ),
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('Clear scheduled'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (ready.transactions.isEmpty)
                          Text(
                            'No deposits toward this goal yet.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          )
                        else
                          ...(() {
                            final now = DateTime.now();
                            final scheduled = <Transaction>[];
                            final history = <Transaction>[];
                            for (final t in ready.transactions) {
                              if (TransactionDisplay.isPendingByDate(t, now)) {
                                scheduled.add(t);
                              } else {
                                history.add(t);
                              }
                            }
                            scheduled.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
                            history.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

                            List<Widget> section({
                              required String title,
                              required List<Transaction> items,
                            }) {
                              if (items.isEmpty) return const [];
                              return [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6, top: 4),
                                  child: Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                ...items.map((t) {
                                  final accName =
                                      ready.accountsById[t.accountId]?.name ??
                                          'Unknown account';
                                  final style = mapTransactionToListStyle(
                                    t: t,
                                    now: now,
                                  );
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Opacity(
                                      opacity: style.opacity,
                                      child: ListTile(
                                        leading: style.leadingIcon == null
                                            ? null
                                            : Icon(style.leadingIcon),
                                        title:
                                            Text(formatZarFromCents(t.amountCents)),
                                        subtitle: Text(
                                          [
                                            accName,
                                            formatDateTime(t.occurredAt),
                                            if (style.statusText != null)
                                              style.statusText!,
                                          ].join(' · '),
                                        ),
                                        trailing: t.pendingSync
                                            ? Icon(
                                                Icons.sync_rounded,
                                                size: 20,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              )
                                            : null,
                                      ),
                                    ),
                                  );
                                }),
                              ];
                            }

                            return [
                              ...section(title: 'Scheduled', items: scheduled),
                              ...section(title: 'History', items: history),
                            ];
                          })(),
                      ],
                    ),
                  );
            }(),
          );
        },
      ),
    );
  }
}

class _GoalGrowthChart extends StatelessWidget {
  const _GoalGrowthChart({
    required this.goalColor,
    required this.goalCreatedAt,
    required this.goalTargetCents,
    required this.points,
    required this.prediction,
  });

  final Color goalColor;
  final DateTime goalCreatedAt;
  final int goalTargetCents;
  final List<GoalGrowthChartPoint> points;
  final GoalGrowthPrediction? prediction;

  @override
  Widget build(BuildContext context) {
    final spots = points.map((p) => p.spot).toList();
    final minX = goalCreatedAt.millisecondsSinceEpoch.toDouble();
    final maxX = (() {
      final predicted = prediction?.predictedReachDate;
      if (predicted == null) return (spots.isNotEmpty ? spots.last.x : minX);
      final px = predicted.millisecondsSinceEpoch.toDouble();
      final lastX = (spots.isNotEmpty ? spots.last.x : minX);
      return px > lastX ? px : lastX;
    })();
    final maxY = points.isEmpty
        ? goalTargetCents.toDouble()
        : (points.last.cumulativeCents > goalTargetCents
            ? points.last.cumulativeCents.toDouble()
            : goalTargetCents.toDouble());
    final targetY = goalTargetCents.toDouble();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        goalColor.withOpacity(0.35),
        goalColor.withOpacity(0.00),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              minY: 0,
              maxY: maxY,
              gridData: const FlGridData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: targetY,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.55),
                    strokeWidth: 2,
                    dashArray: const [6, 6],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topLeft,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                      labelResolver: (_) => 'Goal: ${formatZarFromCents(goalTargetCents)}',
                    ),
                  ),
                ],
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.35),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (value, meta) {
                      final target = goalTargetCents.toDouble();
                      const eps = 0.01;
                      if (value.abs() < eps) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            '0',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      }
                      if ((value - target).abs() < eps) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            formatZarFromCents(goalTargetCents),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    interval: ((maxX - minX) / 3).clamp(
                      const Duration(days: 7).inMilliseconds.toDouble(),
                      const Duration(days: 365).inMilliseconds.toDouble(),
                    ),
                    getTitlesWidget: (value, meta) {
                      final dt =
                          DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      final fmt = DateFormat('MMM yy');
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          fmt.format(dt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) =>
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((barSpot) {
                      final idx = barSpot.spotIndex;
                      final p = (idx >= 0 && idx < points.length)
                          ? points[idx]
                          : null;
                      if (p == null) return null;
                      final date = formatDateTime(p.occurredAt);
                      final amount = formatZarFromCents(p.depositCents);
                      return LineTooltipItem(
                        '$date\n$amount',
                        Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: goalColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: spots.length <= 10,
                    getDotPainter: (spot, percent, bar, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: goalColor,
                        strokeWidth: 2,
                        strokeColor: Theme.of(context).colorScheme.surface,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(show: true, gradient: gradient),
                ),
                if (prediction != null)
                  LineChartBarData(
                    spots: prediction!.predictionLineSpots,
                    isCurved: false,
                    color: goalColor.withOpacity(0.65),
                    barWidth: 2,
                    dashArray: const [6, 6],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
