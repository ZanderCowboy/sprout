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

final class GoalDetailDeleteRequested extends GoalDetailEvent {
  const GoalDetailDeleteRequested();
}

final class GoalDetailClearScheduledRequested extends GoalDetailEvent {
  const GoalDetailClearScheduledRequested({required this.transactionIds});

  final List<String> transactionIds;

  @override
  List<Object?> get props => [transactionIds];
}

final class GoalDetailRefreshRequested extends GoalDetailEvent {
  const GoalDetailRefreshRequested();
}
