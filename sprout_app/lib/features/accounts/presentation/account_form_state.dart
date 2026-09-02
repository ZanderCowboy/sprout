part of 'account_form_cubit.dart';

sealed class AccountFormState extends Equatable {
  const AccountFormState();
  @override
  List<Object?> get props => [];
}

final class AccountFormReady extends AccountFormState {
  const AccountFormReady({
    required this.name,
    required this.colorArgb,
    this.nameError,
    this.submitError,
    this.loaded = false,
    this.submitting = false,
  });

  final String name;
  final int colorArgb;
  final String? nameError;
  final String? submitError;
  final bool loaded;
  final bool submitting;

  bool get canSave =>
      loaded &&
      !submitting &&
      name.trim().isNotEmpty &&
      nameError == null;

  AccountFormReady copyWith({
    String? name,
    int? colorArgb,
    String? nameError,
    String? submitError,
    bool? loaded,
    bool? submitting,
    bool updateNameError = false,
    bool clearSubmitError = false,
  }) {
    return AccountFormReady(
      name: name ?? this.name,
      colorArgb: colorArgb ?? this.colorArgb,
      nameError: updateNameError ? nameError : this.nameError,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      loaded: loaded ?? this.loaded,
      submitting: submitting ?? this.submitting,
    );
  }

  @override
  List<Object?> get props => [
    name,
    colorArgb,
    nameError,
    submitError,
    loaded,
    submitting,
  ];
}

final class AccountFormSaved extends AccountFormState {
  const AccountFormSaved({required this.account});

  final Account account;

  @override
  List<Object?> get props => [account];
}
