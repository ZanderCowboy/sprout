part of 'goals_bloc.dart';

sealed class GoalsEvent extends Equatable {
  const GoalsEvent();
  @override
  List<Object?> get props => [];
}

final class GoalsSubscriptionRequested extends GoalsEvent {
  const GoalsSubscriptionRequested();
}
