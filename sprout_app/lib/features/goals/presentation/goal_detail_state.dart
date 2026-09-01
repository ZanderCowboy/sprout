part of 'goal_detail_bloc.dart';

sealed class GoalDetailState extends Equatable {
  const GoalDetailState();
  @override
  List<Object?> get props => [];
}

final class GoalDetailInitial extends GoalDetailState {
  const GoalDetailInitial();
}

final class GoalDetailReady extends GoalDetailState {
  const GoalDetailReady({
    required this.progress,
    required this.transactions,
    required this.accountsById,
    required this.graphPoints,
    required this.prediction,
  });

  final GoalProgress progress;
  final List<Transaction> transactions;
  final Map<String, Account> accountsById;
  final List<GoalGrowthChartPoint> graphPoints;
  final GoalGrowthPrediction? prediction;

  @override
  List<Object?> get props =>
      [progress, transactions, accountsById, graphPoints, prediction];
}
