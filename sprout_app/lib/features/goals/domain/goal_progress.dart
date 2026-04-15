import 'package:equatable/equatable.dart';

import 'goal.dart';

class GoalProgress extends Equatable {
  const GoalProgress({
    required this.goal,
    required this.savedCents,
  });

  final Goal goal;
  final int savedCents;

  int get remainingCents {
    final r = goal.targetAmountCents - savedCents;
    return r < 0 ? 0 : r;
  }

  int get percentComplete {
    if (goal.targetAmountCents <= 0) return 0;
    return (savedCents * 100) ~/ goal.targetAmountCents;
  }

  @override
  List<Object?> get props => [goal, savedCents];
}
