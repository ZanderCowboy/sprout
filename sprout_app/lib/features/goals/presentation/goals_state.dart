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
    required this.unallocatedBalance,
  });

  final List<GoalProgress> progressList;
  final double unallocatedBalance;

  @override
  List<Object?> get props => [progressList, unallocatedBalance];
}
