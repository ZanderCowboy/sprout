import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/transactions/export.dart';

import '../application/goals_service.dart';
import '../domain/goal.dart';
import '../domain/goal_progress.dart';
import 'utils/goal_growth_chart.dart';

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

class GoalDetailBloc extends Bloc<GoalDetailEvent, GoalDetailState> {
  GoalDetailBloc({
    required GoalsService goalsService,
    required TransactionsService transactionsService,
    required AccountsService accountsService,
  })  : _goalsService = goalsService,
        _transactionsService = transactionsService,
        _accountsService = accountsService,
        super(const GoalDetailInitial()) {
    on<GoalDetailSubscriptionRequested>(
      _onSubscribe,
      transformer: restartable(),
    );
  }

  final GoalsService _goalsService;
  final TransactionsService _transactionsService;
  final AccountsService _accountsService;

  Future<void> _onSubscribe(
    GoalDetailSubscriptionRequested event,
    Emitter<GoalDetailState> emit,
  ) {
    return emit.forEach<GoalDetailReady>(
      _watchReady(goalId: event.goalId),
      onData: (ready) => ready,
    );
  }

  Stream<GoalDetailReady> _watchReady({required String goalId}) {
    return Stream<GoalDetailReady>.multi((controller) {
      List<Goal>? goals;
      List<Transaction>? txs;
      List<Account>? accounts;

      void tryEmit() {
        if (goals == null || txs == null || accounts == null) return;

        final now = DateTime.now();
        final goal = goals!.cast<Goal?>().firstWhere(
              (g) => g?.id == goalId,
              orElse: () => null,
            );
        if (goal == null) return;

        var saved = 0;
        final forGoal = <Transaction>[];
        for (final t in txs!) {
          if (t.goalId != goalId) continue;
          forGoal.add(t);
          if (!t.occurredAt.isAfter(now)) {
            saved += t.amountCents;
          }
        }
        forGoal.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

        final progress = GoalProgress(goal: goal, savedCents: saved);
        final accountsById = {for (final a in accounts!) a.id: a};
        final graphPoints = mapTransactionsToGoalGrowthPoints(
          goalCreatedAt: goal.createdAt,
          transactions: forGoal,
        );
        final prediction = predictGoalReach(
          goalTargetCents: goal.targetAmountCents,
          currentSavedCents: saved,
          goalTransactions: forGoal,
          graphPoints: graphPoints,
        );

        controller.add(
          GoalDetailReady(
            progress: progress,
            transactions: forGoal,
            accountsById: accountsById,
            graphPoints: graphPoints,
            prediction: prediction,
          ),
        );
      }

      final goalsSub = _goalsService.watchGoals().listen(
        (g) {
          goals = g;
          tryEmit();
        },
        onError: controller.addError,
      );
      final txSub = _transactionsService.watchTransactions().listen(
        (t) {
          txs = t;
          tryEmit();
        },
        onError: controller.addError,
      );
      final accountsSub = _accountsService.watchAccounts().listen(
        (a) {
          accounts = a;
          tryEmit();
        },
        onError: controller.addError,
      );

      controller.onCancel = () {
        goalsSub.cancel();
        txSub.cancel();
        accountsSub.cancel();
      };
    });
  }
}

