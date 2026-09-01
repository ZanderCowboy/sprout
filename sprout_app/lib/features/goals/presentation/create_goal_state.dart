part of 'create_goal_bloc.dart';

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
