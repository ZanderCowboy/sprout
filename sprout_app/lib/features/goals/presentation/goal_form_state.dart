part of 'goal_form_cubit.dart';

sealed class GoalFormState extends Equatable {
  const GoalFormState();
  @override
  List<Object?> get props => [];
}

final class GoalFormReady extends GoalFormState {
  const GoalFormReady({
    required this.name,
    required this.targetText,
    required this.colorArgb,
    this.nameError,
    this.targetError,
    this.submitError,
    this.loaded = false,
    this.submitting = false,
  });

  final String name;
  final String targetText;
  final int colorArgb;
  final String? nameError;
  final String? targetError;
  final String? submitError;
  final bool loaded;
  final bool submitting;

  bool get canSave =>
      loaded &&
      !submitting &&
      name.trim().isNotEmpty &&
      nameError == null &&
      classifyPositiveZarField(targetText) == PositiveZarFieldState.ok;

  GoalFormReady copyWith({
    String? name,
    String? targetText,
    int? colorArgb,
    String? nameError,
    String? targetError,
    String? submitError,
    bool? loaded,
    bool? submitting,
    bool updateNameError = false,
    bool updateTargetError = false,
    bool clearSubmitError = false,
  }) {
    return GoalFormReady(
      name: name ?? this.name,
      targetText: targetText ?? this.targetText,
      colorArgb: colorArgb ?? this.colorArgb,
      nameError: updateNameError ? nameError : this.nameError,
      targetError: updateTargetError ? targetError : this.targetError,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      loaded: loaded ?? this.loaded,
      submitting: submitting ?? this.submitting,
    );
  }

  @override
  List<Object?> get props => [
    name,
    targetText,
    colorArgb,
    nameError,
    targetError,
    submitError,
    loaded,
    submitting,
  ];
}

final class GoalFormSaved extends GoalFormState {
  const GoalFormSaved({required this.goal});

  final Goal goal;

  @override
  List<Object?> get props => [goal];
}
