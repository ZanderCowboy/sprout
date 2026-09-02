part of 'budget_group_form_cubit.dart';

sealed class BudgetGroupFormState extends Equatable {
  const BudgetGroupFormState();
  @override
  List<Object?> get props => [];
}

final class BudgetGroupFormReady extends BudgetGroupFormState {
  const BudgetGroupFormReady({
    required this.name,
    required this.description,
    required this.category,
    this.nameError,
    this.submitError,
    this.loaded = false,
    this.submitting = false,
  });

  final String name;
  final String description;
  final BudgetCategory category;
  final String? nameError;
  final String? submitError;
  final bool loaded;
  final bool submitting;

  bool get canSave =>
      loaded &&
      !submitting &&
      name.trim().isNotEmpty &&
      nameError == null;

  BudgetGroupFormReady copyWith({
    String? name,
    String? description,
    BudgetCategory? category,
    String? nameError,
    String? submitError,
    bool? loaded,
    bool? submitting,
    bool updateNameError = false,
    bool clearSubmitError = false,
  }) {
    return BudgetGroupFormReady(
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      nameError: updateNameError ? nameError : this.nameError,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      loaded: loaded ?? this.loaded,
      submitting: submitting ?? this.submitting,
    );
  }

  @override
  List<Object?> get props => [
    name,
    description,
    category,
    nameError,
    submitError,
    loaded,
    submitting,
  ];
}

final class BudgetGroupFormSaved extends BudgetGroupFormState {
  const BudgetGroupFormSaved({required this.group});

  final BudgetGroup group;

  @override
  List<Object?> get props => [group];
}
