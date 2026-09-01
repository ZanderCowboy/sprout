part of 'create_goal_bloc.dart';

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
