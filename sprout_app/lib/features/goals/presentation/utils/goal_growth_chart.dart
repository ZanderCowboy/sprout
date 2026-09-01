import 'package:fl_chart/fl_chart.dart';

import 'package:sprout/features/transactions/domain/recurring_schedule.dart';
import 'package:sprout/features/transactions/domain/transaction.dart';
import 'package:sprout/features/transactions/domain/transaction_frequency.dart';
import 'package:sprout/features/transactions/domain/transaction_rules.dart';

class GoalGrowthChartPoint {
  const GoalGrowthChartPoint({
    required this.spot,
    required this.occurredAt,
    required this.depositCents,
    required this.cumulativeCents,
  });

  final FlSpot spot;
  final DateTime occurredAt;
  final int depositCents;
  final int cumulativeCents;
}

class GoalGrowthPrediction {
  const GoalGrowthPrediction({
    required this.predictedReachDate,
    required this.predictionLineSpots,
  });

  final DateTime predictedReachDate;
  final List<FlSpot> predictionLineSpots;
}

List<GoalGrowthChartPoint> mapTransactionsToGoalGrowthPoints({
  required DateTime goalCreatedAt,
  required List<Transaction> transactions,
}) {
  final now = DateTime.now();
  final tx =
      transactions.where((t) => !TransactionRules.isPending(t, now)).toList()
        ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

  final points = <GoalGrowthChartPoint>[];

  void addPoint({
    required DateTime occurredAt,
    required int depositCents,
    required int cumulativeCents,
  }) {
    points.add(
      GoalGrowthChartPoint(
        occurredAt: occurredAt,
        depositCents: depositCents,
        cumulativeCents: cumulativeCents,
        spot: FlSpot(
          occurredAt.millisecondsSinceEpoch.toDouble(),
          cumulativeCents.toDouble(),
        ),
      ),
    );
  }

  // Ensure the line always starts at goal creation date with Y=0.
  addPoint(occurredAt: goalCreatedAt, depositCents: 0, cumulativeCents: 0);

  var running = 0;
  for (final t in tx) {
    running += t.amountCents;
    addPoint(
      occurredAt: t.occurredAt,
      depositCents: t.amountCents,
      cumulativeCents: running,
    );
  }

  return points;
}

GoalGrowthPrediction? predictGoalReach({
  required int goalTargetCents,
  required int currentSavedCents,
  required List<Transaction> goalTransactions,
  required List<GoalGrowthChartPoint> graphPoints,
}) {
  if (goalTargetCents <= 0) return null;
  if (currentSavedCents >= goalTargetCents) return null;
  if (graphPoints.isEmpty) return null;

  final remaining = goalTargetCents - currentSavedCents;
  if (remaining <= 0) return null;

  final lastActual = graphPoints.last;
  final lastActualDate = lastActual.occurredAt;
  final lastActualSpot = lastActual.spot;

  final recurring = goalTransactions
      .where(
        (t) =>
            t.isRecurring &&
            t.recurringEnabled &&
            t.frequency != TransactionFrequency.none,
      )
      .toList();

  double dailyRateCentsPerDay = 0;

  if (recurring.isNotEmpty) {
    DateTime alignNext({
      required Transaction template,
      required DateTime base,
    }) {
      return RecurringSchedule.alignNext(
        templateOccurredAt: template.occurredAt,
        frequency: template.frequency,
        nextScheduledDate: template.nextScheduledDate,
        base: base,
      );
    }

    final base = (DateTime.now().isAfter(lastActualDate))
        ? DateTime.now()
        : lastActualDate;

    final nextDates = <String, DateTime>{
      for (final t in recurring) t.id: alignNext(template: t, base: base),
    };

    final spots = <FlSpot>[lastActualSpot];
    var cumulative = currentSavedCents;
    const maxSteps = 1200;
    var steps = 0;

    while (cumulative < goalTargetCents && steps < maxSteps) {
      // Pick the next soonest recurring occurrence.
      Transaction? nextTx;
      DateTime? nextAt;
      for (final t in recurring) {
        final dt = nextDates[t.id];
        if (dt == null) continue;
        if (nextAt == null || dt.isBefore(nextAt)) {
          nextAt = dt;
          nextTx = t;
        }
      }
      if (nextTx == null || nextAt == null) break;

      cumulative += nextTx.amountCents;
      final y = (cumulative > goalTargetCents ? goalTargetCents : cumulative)
          .toDouble();
      spots.add(FlSpot(nextAt.millisecondsSinceEpoch.toDouble(), y));

      nextDates[nextTx.id] = RecurringSchedule.next(nextAt, nextTx.frequency);
      steps++;
    }

    if (spots.length <= 1) return null;
    final predictedReachDate = DateTime.fromMillisecondsSinceEpoch(
      spots.last.x.toInt(),
    );
    return GoalGrowthPrediction(
      predictedReachDate: predictedReachDate,
      predictionLineSpots: spots,
    );
  } else {
    final deposits = goalTransactions.toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    if (deposits.length >= 2) {
      final first = deposits.first;
      final last = deposits.last;
      final days =
          (last.occurredAt.difference(first.occurredAt).inMilliseconds /
                  const Duration(days: 1).inMilliseconds)
              .abs();
      if (days > 0) {
        dailyRateCentsPerDay = currentSavedCents / days;
      }
    }
  }

  if (dailyRateCentsPerDay <= 0) return null;

  final daysToReach = (remaining / dailyRateCentsPerDay).ceil();
  if (daysToReach <= 0) return null;

  final predicted = lastActualDate.add(Duration(days: daysToReach));
  final targetSpot = FlSpot(
    predicted.millisecondsSinceEpoch.toDouble(),
    goalTargetCents.toDouble(),
  );

  return GoalGrowthPrediction(
    predictedReachDate: predicted,
    predictionLineSpots: [lastActualSpot, targetSpot],
  );
}
