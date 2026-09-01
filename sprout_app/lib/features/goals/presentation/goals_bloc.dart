import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/goals_service.dart';
import '../domain/goal.dart';
import '../domain/goal_progress.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/transactions/export.dart';

part 'goals_event.dart';
part 'goals_state.dart';

class GoalsBloc extends Bloc<GoalsEvent, GoalsState> {
  GoalsBloc({
    required GoalsService goalsService,
    required TransactionsService transactionsService,
    required AccountsService accountsService,
  }) : _goalsService = goalsService,
       _transactionsService = transactionsService,
       _accountsService = accountsService,
       super(const GoalsInitial()) {
    on<GoalsSubscriptionRequested>(_onSubscribe, transformer: restartable());
  }

  final GoalsService _goalsService;
  final TransactionsService _transactionsService;
  final AccountsService _accountsService;

  Future<void> _onSubscribe(
    GoalsSubscriptionRequested event,
    Emitter<GoalsState> emit,
  ) {
    return emit.forEach<GoalsReady>(_watchGoalProgress(), onData: (s) => s);
  }

  Stream<GoalsReady> _watchGoalProgress() {
    return Stream<GoalsReady>.multi((controller) {
      var goals = <Goal>[];
      var fundsSnapshot = const FundsSnapshot(
        savedCentsByGoalId: {},
        unallocatedCents: 0,
        accountCurrentDepositTotalsById: {},
        accountScheduledDepositTotalsById: {},
      );

      void emitProgress() {
        final list = goals
            .map(
              (g) => GoalProgress(
                goal: g,
                savedCents: fundsSnapshot.savedCentsByGoalId[g.id] ?? 0,
              ),
            )
            .toList();

        controller.add(
          GoalsReady(
            progressList: list,
            unallocatedBalanceCents: fundsSnapshot.unallocatedCents,
          ),
        );
      }

      final goalsSub = _goalsService.watchGoals().listen((g) {
        goals = g;
        emitProgress();
      }, onError: controller.addError);
      final fundsSub = _transactionsService
          .watchFundsSnapshot(
            accountIdsStream: _accountsService.watchAccounts().map(
              (accounts) => accounts.map((a) => a.id).toList(),
            ),
          )
          .listen((snapshot) {
            fundsSnapshot = snapshot;
            emitProgress();
          }, onError: controller.addError);

      controller.onCancel = () {
        goalsSub.cancel();
        fundsSub.cancel();
      };
    });
  }
}
