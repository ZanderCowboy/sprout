import 'goal_progress.dart';

class OverallGoalsTotals {
  const OverallGoalsTotals({
    required this.totalTargetCents,
    required this.totalSavedCents,
    required this.totalRemainingCents,
    required this.overallPercent,
  });

  factory OverallGoalsTotals.from(List<GoalProgress> progressList) {
    final totalTargetCents = progressList.fold<int>(
      0,
      (sum, p) => sum + p.goal.targetAmountCents,
    );
    final totalSavedCents = progressList.fold<int>(
      0,
      (sum, p) => sum + p.savedCents,
    );
    final remaining = totalTargetCents - totalSavedCents;
    return OverallGoalsTotals(
      totalTargetCents: totalTargetCents,
      totalSavedCents: totalSavedCents,
      totalRemainingCents: remaining < 0 ? 0 : remaining,
      overallPercent: totalTargetCents <= 0
          ? 0
          : (totalSavedCents * 100) ~/ totalTargetCents,
    );
  }

  final int totalTargetCents;
  final int totalSavedCents;
  final int totalRemainingCents;
  final int overallPercent;
}
