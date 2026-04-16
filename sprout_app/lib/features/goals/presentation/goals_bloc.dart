import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/goals_service.dart';
import '../domain/goal.dart';
import '../domain/goal_progress.dart';
import 'package:sprout/features/transactions/export.dart';
import 'package:sprout/features/accounts/export.dart';

sealed class GoalsEvent extends Equatable {
  const GoalsEvent();
  @override
  List<Object?> get props => [];
}

final class GoalsSubscriptionRequested extends GoalsEvent {
  const GoalsSubscriptionRequested();
}

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

class GoalsBloc extends Bloc<GoalsEvent, GoalsState> {
  GoalsBloc({
    required GoalsService goalsService,
    required TransactionsService transactionsService,
    required AccountsService accountsService,
  })  : _goalsService = goalsService,
        _transactionsService = transactionsService,
        _accountsService = accountsService,
        super(const GoalsInitial()) {
    on<GoalsSubscriptionRequested>(
      _onSubscribe,
      transformer: restartable(),
    );
  }

  final GoalsService _goalsService;
  final TransactionsService _transactionsService;
  final AccountsService _accountsService;

  Future<void> _onSubscribe(
    GoalsSubscriptionRequested event,
    Emitter<GoalsState> emit,
  ) {
    return emit.forEach<GoalsReady>(
      _watchGoalProgress(),
      onData: (s) => s,
    );
  }

  Stream<GoalsReady> _watchGoalProgress() {
    return Stream<GoalsReady>.multi((controller) {
      var accounts = <Account>[];
      var goals = <Goal>[];
      var transactions = <Transaction>[];

      void emitProgress() {
        final now = DateTime.now();
        final allocationSavedByGoalId = <String, int>{};
        final depositUnallocatedByAccountId = <String, int>{};
        final allocationByAccountId = <String, int>{};
        for (final t in transactions) {
          if (t.occurredAt.isAfter(now)) continue; // pending by date
          switch (t.kind) {
            case TransactionKind.deposit:
              final gid = t.goalId;
              if (gid == null || gid.isEmpty) {
                depositUnallocatedByAccountId[t.accountId] =
                    (depositUnallocatedByAccountId[t.accountId] ?? 0) +
                        t.amountCents;
              } else {
                allocationSavedByGoalId[gid] =
                    (allocationSavedByGoalId[gid] ?? 0) + t.amountCents;
              }
              break;
            case TransactionKind.allocation:
              final gid = t.goalId;
              if (gid == null || gid.isEmpty) break;
              allocationSavedByGoalId[gid] =
                  (allocationSavedByGoalId[gid] ?? 0) + t.amountCents;
              allocationByAccountId[t.accountId] =
                  (allocationByAccountId[t.accountId] ?? 0) + t.amountCents;
              break;
          }
        }
        final list = goals
            .map(
              (g) => GoalProgress(
                goal: g,
                savedCents: allocationSavedByGoalId[g.id] ?? 0,
              ),
            )
            .toList();

        var unallocatedCents = 0;
        for (final a in accounts) {
          final deposited = depositUnallocatedByAccountId[a.id] ?? 0;
          final allocated = allocationByAccountId[a.id] ?? 0;
          final available = deposited - allocated;
          if (available > 0) unallocatedCents += available;
        }

        controller.add(
          GoalsReady(
            progressList: list,
            unallocatedBalance: unallocatedCents / 100.0,
          ),
        );
      }

      final accountsSub = _accountsService.watchAccounts().listen(
        (a) {
          accounts = a;
          emitProgress();
        },
        onError: controller.addError,
      );
      final goalsSub = _goalsService.watchGoals().listen(
        (g) {
          goals = g;
          emitProgress();
        },
        onError: controller.addError,
      );
      final txSub = _transactionsService.watchTransactions().listen(
        (t) {
          transactions = t;
          emitProgress();
        },
        onError: controller.addError,
      );

      controller.onCancel = () {
        accountsSub.cancel();
        goalsSub.cancel();
        txSub.cancel();
      };
    });
  }
}
