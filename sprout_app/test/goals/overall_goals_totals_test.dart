import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/features/goals/domain/goal.dart';
import 'package:sprout/features/goals/domain/goal_progress.dart';
import 'package:sprout/features/goals/domain/overall_goals_totals.dart';

void main() {
  Goal goal({
    required String id,
    required int targetCents,
  }) {
    return Goal(
      id: id,
      userId: 'u',
      name: id,
      targetAmountCents: targetCents,
      color: 0xFF000000,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  test('sums targets, saved, remaining, and percent', () {
    final totals = OverallGoalsTotals.from([
      GoalProgress(goal: goal(id: 'a', targetCents: 10000), savedCents: 2500),
      GoalProgress(goal: goal(id: 'b', targetCents: 10000), savedCents: 2500),
    ]);

    expect(totals.totalTargetCents, 20000);
    expect(totals.totalSavedCents, 5000);
    expect(totals.totalRemainingCents, 15000);
    expect(totals.overallPercent, 25);
  });

  test('clamps remaining at zero and percent at zero when no target', () {
    final over = OverallGoalsTotals.from([
      GoalProgress(goal: goal(id: 'a', targetCents: 100), savedCents: 200),
    ]);
    expect(over.totalRemainingCents, 0);
    expect(over.overallPercent, 200);

    final empty = OverallGoalsTotals.from(const []);
    expect(empty.overallPercent, 0);
    expect(empty.totalRemainingCents, 0);
  });
}
