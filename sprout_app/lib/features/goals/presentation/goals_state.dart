part of 'goals_bloc.dart';

sealed class GoalsState extends Equatable {
  const GoalsState();
  @override
  List<Object?> get props => [];
}

final class GoalsInitial extends GoalsState {
  const GoalsInitial();
}

final class GoalsReady extends GoalsState {
  const GoalsReady({
    required this.progressList,
    required this.unallocatedBalanceCents,
  });

  final List<GoalProgress> progressList;
  final int unallocatedBalanceCents;

  OverallGoalsTotals get overall => OverallGoalsTotals.from(progressList);

  @override
  List<Object?> get props => [progressList, unallocatedBalanceCents];
}
