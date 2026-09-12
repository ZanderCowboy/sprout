part of 'wizard_cubit.dart';

sealed class WizardState extends Equatable {
  const WizardState();

  @override
  List<Object?> get props => [];
}

final class WizardReady extends WizardState {
  const WizardReady({
    required this.step,
    required this.goalName,
    required this.goalTargetText,
    required this.goalColorArgb,
    required this.accountName,
    required this.accountColorArgb,
    required this.depositAmountText,
    required this.depositNote,
    this.goalNameError,
    this.goalTargetError,
    this.accountNameError,
    this.depositAmountError,
    this.errorMessage,
    this.loaded = false,
    this.submitting = false,
  });

  final int step;
  final String goalName;
  final String goalTargetText;
  final int goalColorArgb;
  final String? goalNameError;
  final String? goalTargetError;
  final String accountName;
  final int accountColorArgb;
  final String? accountNameError;
  final String depositAmountText;
  final String depositNote;
  final String? depositAmountError;
  final String? errorMessage;
  final bool loaded;
  final bool submitting;

  WizardReady copyWith({
    int? step,
    String? goalName,
    String? goalTargetText,
    int? goalColorArgb,
    String? goalNameError,
    String? goalTargetError,
    String? accountName,
    int? accountColorArgb,
    String? accountNameError,
    String? depositAmountText,
    String? depositNote,
    String? depositAmountError,
    String? errorMessage,
    bool? loaded,
    bool? submitting,
    bool clearError = false,
  }) {
    return WizardReady(
      step: step ?? this.step,
      goalName: goalName ?? this.goalName,
      goalTargetText: goalTargetText ?? this.goalTargetText,
      goalColorArgb: goalColorArgb ?? this.goalColorArgb,
      goalNameError: goalNameError ?? this.goalNameError,
      goalTargetError: goalTargetError ?? this.goalTargetError,
      accountName: accountName ?? this.accountName,
      accountColorArgb: accountColorArgb ?? this.accountColorArgb,
      accountNameError: accountNameError ?? this.accountNameError,
      depositAmountText: depositAmountText ?? this.depositAmountText,
      depositNote: depositNote ?? this.depositNote,
      depositAmountError: depositAmountError ?? this.depositAmountError,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      loaded: loaded ?? this.loaded,
      submitting: submitting ?? this.submitting,
    );
  }

  @override
  List<Object?> get props => [
        step,
        goalName,
        goalTargetText,
        goalColorArgb,
        goalNameError,
        goalTargetError,
        accountName,
        accountColorArgb,
        accountNameError,
        depositAmountText,
        depositNote,
        depositAmountError,
        errorMessage,
        loaded,
        submitting,
      ];
}

final class WizardSkipped extends WizardState {
  const WizardSkipped();
}

final class WizardCompleted extends WizardState {
  const WizardCompleted();
}
