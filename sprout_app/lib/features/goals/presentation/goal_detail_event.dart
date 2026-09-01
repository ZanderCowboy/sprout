part of 'goal_detail_bloc.dart';

sealed class GoalDetailEvent extends Equatable {
  const GoalDetailEvent();
  @override
  List<Object?> get props => [];
}

final class GoalDetailSubscriptionRequested extends GoalDetailEvent {
  const GoalDetailSubscriptionRequested({required this.goalId});

  final String goalId;

  @override
  List<Object?> get props => [goalId];
}
