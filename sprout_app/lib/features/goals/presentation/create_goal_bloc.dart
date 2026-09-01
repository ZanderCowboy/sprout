import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/accounts/export.dart';

import '../application/goals_service.dart';
import '../domain/goal.dart';

sealed class CreateGoalEvent extends Equatable {
  const CreateGoalEvent();
  @override
  List<Object?> get props => [];
}

final class CreateGoalStarted extends CreateGoalEvent {
  const CreateGoalStarted();
}

final class CreateGoalSubmitted extends CreateGoalEvent {
  const CreateGoalSubmitted({
    required this.name,
    required this.targetAmountCents,
    required this.colorArgb,
    required this.alreadySavedAmountCents,
    required this.alreadySavedAccountId,
  });

  final String name;
  final int targetAmountCents;
  final int colorArgb;
  final int alreadySavedAmountCents;
  final String? alreadySavedAccountId;

  @override
  List<Object?> get props => [
    name,
    targetAmountCents,
    colorArgb,
    alreadySavedAmountCents,
    alreadySavedAccountId,
  ];
}

sealed class CreateGoalState extends Equatable {
  const CreateGoalState();
  @override
  List<Object?> get props => [];
}

final class CreateGoalInitial extends CreateGoalState {
  const CreateGoalInitial();
}

final class CreateGoalReady extends CreateGoalState {
  const CreateGoalReady({
    required this.accounts,
    required this.submitting,
    required this.errorMessage,
  });

  final List<Account> accounts;
  final bool submitting;
  final String? errorMessage;

  @override
  List<Object?> get props => [accounts, submitting, errorMessage];

  CreateGoalReady copyWith({
    List<Account>? accounts,
    bool? submitting,
    String? errorMessage,
  }) {
    return CreateGoalReady(
      accounts: accounts ?? this.accounts,
      submitting: submitting ?? this.submitting,
      errorMessage: errorMessage,
    );
  }
}

final class CreateGoalSuccess extends CreateGoalState {
  const CreateGoalSuccess({required this.goalId});
  final String goalId;

  @override
  List<Object?> get props => [goalId];
}

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
