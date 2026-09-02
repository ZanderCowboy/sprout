part of 'goal_detail_bloc.dart';

sealed class GoalDetailState extends Equatable {
  const GoalDetailState();
  @override
  List<Object?> get props => [];
}

final class GoalDetailInitial extends GoalDetailState {
  const GoalDetailInitial();
}

final class GoalDetailDeleted extends GoalDetailState {
  const GoalDetailDeleted();
}

final class GoalDetailReady extends GoalDetailState {
  const GoalDetailReady({
    required this.progress,
    required this.transactions,
    required this.scheduledTransactions,
    required this.historyTransactions,
    required this.accountsById,
    required this.graphPoints,
    required this.prediction,
    this.actionError,
  });

  final GoalProgress progress;
  final List<Transaction> transactions;
  final List<Transaction> scheduledTransactions;
  final List<Transaction> historyTransactions;
  final Map<String, Account> accountsById;
  final List<GoalGrowthChartPoint> graphPoints;
  final GoalGrowthPrediction? prediction;
  final String? actionError;

  GoalDetailReady copyWith({
    GoalProgress? progress,
    List<Transaction>? transactions,
    List<Transaction>? scheduledTransactions,
    List<Transaction>? historyTransactions,
    Map<String, Account>? accountsById,
    List<GoalGrowthChartPoint>? graphPoints,
    GoalGrowthPrediction? prediction,
    String? actionError,
    bool clearActionError = false,
  }) {
    return GoalDetailReady(
      progress: progress ?? this.progress,
      transactions: transactions ?? this.transactions,
      scheduledTransactions: scheduledTransactions ?? this.scheduledTransactions,
      historyTransactions: historyTransactions ?? this.historyTransactions,
      accountsById: accountsById ?? this.accountsById,
      graphPoints: graphPoints ?? this.graphPoints,
      prediction: prediction ?? this.prediction,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
    progress,
    transactions,
    scheduledTransactions,
    historyTransactions,
    accountsById,
    graphPoints,
    prediction,
    actionError,
  ];
}
