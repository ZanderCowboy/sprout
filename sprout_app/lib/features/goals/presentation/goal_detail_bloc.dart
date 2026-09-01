import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/transactions/export.dart';

import '../application/goals_service.dart';
import '../domain/goal.dart';
import '../domain/goal_progress.dart';
import 'utils/goal_growth_chart.dart';

part 'goal_detail_event.dart';
part 'goal_detail_state.dart';

class GoalDetailBloc extends Bloc<GoalDetailEvent, GoalDetailState> {
  GoalDetailBloc({
    required GoalsService goalsService,
    required TransactionsService transactionsService,
    required AccountsService accountsService,
  }) : _goalsService = goalsService,
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

        final goal = goals!.cast<Goal?>().firstWhere(
          (g) => g?.id == goalId,
          orElse: () => null,
        );
        if (goal == null) return;

        final forGoal = txs!.where((t) => t.goalId == goalId).toList();
        final split = _transactionsService.splitScheduledAndHistory(forGoal);
        final saved = FundsCalculator.savedCentsForGoal(forGoal, goalId);

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
            scheduledTransactions: split.scheduled,
            historyTransactions: split.history,
            accountsById: accountsById,
            graphPoints: graphPoints,
            prediction: prediction,
          ),
        );
      }

      final goalsSub = _goalsService.watchGoals().listen((g) {
        goals = g;
        tryEmit();
      }, onError: controller.addError);
      final txSub = _transactionsService.watchTransactions().listen((t) {
        txs = t;
        tryEmit();
      }, onError: controller.addError);
      final accountsSub = _accountsService.watchAccounts().listen((a) {
        accounts = a;
        tryEmit();
      }, onError: controller.addError);

      controller.onCancel = () {
        goalsSub.cancel();
        txSub.cancel();
        accountsSub.cancel();
      };
    });
  }
}
