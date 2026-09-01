import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sprout/core/core.dart';
import '../utils/goal_growth_chart.dart';

class GoalGrowthChartView extends StatelessWidget {
  const GoalGrowthChartView({
    super.key,
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
      colors: [goalColor.withValues(alpha: 0.35), goalColor.withValues(alpha: 0.00)],
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                    strokeWidth: 2,
                    dashArray: const [6, 6],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topLeft,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      labelResolver: (_) => AppStrings.goalChartLabel(formatZarFromCents(goalTargetCents)),
                    ),
                  ),
                ],
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.35)),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                          child: Text('0', style: Theme.of(context).textTheme.bodySmall),
                        );
                      }
                      if ((value - target).abs() < eps) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            formatZarFromCents(goalTargetCents),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
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
                      final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      final fmt = DateFormat('MMM yy');
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(fmt.format(dt), style: Theme.of(context).textTheme.bodySmall),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.surfaceContainerHighest,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((barSpot) {
                      final idx = barSpot.spotIndex;
                      final p = (idx >= 0 && idx < points.length) ? points[idx] : null;
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
                    color: goalColor.withValues(alpha: 0.65),
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
