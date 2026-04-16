import '../../domain/goal_progress.dart';
import '../enums/goals_sort.dart';

String goalsSortLabel(GoalsSort s) {
  return switch (s) {
    GoalsSort.remainingLowToHigh => 'Remaining (low → high)',
    GoalsSort.progressHighToLow => 'Progress (high → low)',
    GoalsSort.nameAToZ => 'Name (A → Z)',
  };
}

List<GoalProgress> sortGoals(List<GoalProgress> input, GoalsSort sort) {
  final list = [...input];

  // Always push completed goals to the bottom (>= 100%), regardless of sort.
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
    final primary = switch (sort) {
      GoalsSort.remainingLowToHigh => byRemaining(),
      GoalsSort.progressHighToLow => byProgressDesc(),
      GoalsSort.nameAToZ => byName(),
    };
    if (primary != 0) return primary;

    final secondary = switch (sort) {
      GoalsSort.remainingLowToHigh => byName(),
      GoalsSort.progressHighToLow => byRemaining(),
      GoalsSort.nameAToZ => byRemaining(),
    };
    if (secondary != 0) return secondary;

    return a.goal.id.compareTo(b.goal.id);
  });

  return list;
}

