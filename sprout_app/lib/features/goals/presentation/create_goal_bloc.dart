import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/accounts/export.dart';

import '../application/goals_service.dart';
import '../domain/goal.dart';

part 'create_goal_event.dart';
part 'create_goal_state.dart';

class CreateGoalBloc extends Bloc<CreateGoalEvent, CreateGoalState> {
  CreateGoalBloc({
    required GoalsService goalsService,
    required AccountsService accountsService,
    required UserContext userContext,
  }) : _goalsService = goalsService,
       _accountsService = accountsService,
       _userContext = userContext,
       super(const CreateGoalInitial()) {
    on<CreateGoalStarted>(_onStarted, transformer: restartable());
    on<CreateGoalSubmitted>(_onSubmitted, transformer: sequential());
  }

  final GoalsService _goalsService;
  final AccountsService _accountsService;
  final UserContext _userContext;
  static const _uuid = Uuid();

  Future<void> _onStarted(
    CreateGoalStarted event,
    Emitter<CreateGoalState> emit,
  ) async {
    final accounts = await _accountsService.getAccounts();
    emit(
      CreateGoalReady(
        accounts: accounts,
        submitting: false,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onSubmitted(
    CreateGoalSubmitted event,
    Emitter<CreateGoalState> emit,
  ) async {
    final current = state;
    if (current is! CreateGoalReady) return;

    emit(current.copyWith(submitting: true, errorMessage: null));

    try {
      final uid = await _userContext.resolveUserId();
      final now = DateTime.now();
      final goalId = _uuid.v4();
      final goal = Goal(
        id: goalId,
        userId: uid,
        name: event.name.trim(),
        targetAmountCents: event.targetAmountCents,
        color: event.colorArgb,
        createdAt: now,
        updatedAt: now,
        iconCodePoint: event.iconCodePoint,
      );

      final openingCents = event.alreadySavedAmountCents;
      final openingAccountId = event.alreadySavedAccountId;

      await _goalsService.createGoalWithOpeningBalance(
        goal: goal,
        openingBalanceCents: openingCents,
        openingBalanceAccountId: openingAccountId,
        groupId: _uuid.v4(),
        occurredAt: now,
      );

      emit(CreateGoalSuccess(goalId: goalId));
    } on ValidationAppException catch (e) {
      emit(current.copyWith(submitting: false, errorMessage: e.message));
    } catch (e) {
      emit(current.copyWith(submitting: false, errorMessage: e.toString()));
    }
  }
}
