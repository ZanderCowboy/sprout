import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';

part 'wizard_state.dart';

class WizardCubit extends Cubit<WizardState> {
  WizardCubit({
    required AccountsService accountsService,
    required GoalsService goalsService,
    required TransactionsService transactionsService,
    required UserContext userContext,
    required int defaultGoalColorArgb,
    required int defaultAccountColorArgb,
    required int defaultGoalIconCodePoint,
  })  : _accountsService = accountsService,
        _goalsService = goalsService,
        _transactionsService = transactionsService,
        _userContext = userContext,
        _defaultGoalIconCodePoint = defaultGoalIconCodePoint,
        super(
          WizardReady(
            step: 1,
            goalName: '',
            goalTargetText: '',
            goalColorArgb: defaultGoalColorArgb,
            accountName: '',
            accountColorArgb: defaultAccountColorArgb,
            depositAmountText: '',
            depositNote: '',
          ),
        );

  final AccountsService _accountsService;
  final GoalsService _goalsService;
  final TransactionsService _transactionsService;
  final UserContext _userContext;
  final int _defaultGoalIconCodePoint;
  static const _uuid = Uuid();

  /// Smallest first deposit unless the goal target is lower.
  static const minDepositCents = 1000;

  List<({String id, String name})> _existingGoals = const [];
  List<({String id, String name})> _existingAccounts = const [];

  Future<void> load() async {
    final goals = await _goalsService.getGoals();
    _existingGoals = goals.map((g) => (id: g.id, name: g.name)).toList();
    final accounts = await _accountsService.getAccounts();
    _existingAccounts = accounts.map((a) => (id: a.id, name: a.name)).toList();
    final current = state;
    if (current is WizardReady) {
      emit(
        current.copyWith(
          loaded: true,
          updateGoalNameError: true,
          updateGoalTargetError: true,
          updateAccountNameError: true,
          updateDepositAmountError: true,
          goalNameError: _goalNameError(current.goalName),
          goalTargetError: _goalTargetError(current.goalTargetText),
          accountNameError: _accountNameError(current.accountName),
          depositAmountError: _depositAmountError(
            current.depositAmountText,
            goalTargetText: current.goalTargetText,
          ),
        ),
      );
    }
  }

  void setGoalName(String name) {
    final current = state;
    if (current is! WizardReady) return;
    emit(
      current.copyWith(
        goalName: name,
        updateGoalNameError: true,
        goalNameError: _goalNameError(name),
      ),
    );
  }

  void setGoalTarget(String targetText) {
    final current = state;
    if (current is! WizardReady) return;
    emit(
      current.copyWith(
        goalTargetText: targetText,
        updateGoalTargetError: true,
        goalTargetError: _goalTargetError(targetText),
        updateDepositAmountError: true,
        depositAmountError: _depositAmountError(
          current.depositAmountText,
          goalTargetText: targetText,
        ),
      ),
    );
  }

  void setGoalColor(int colorArgb) {
    final current = state;
    if (current is! WizardReady) return;
    emit(current.copyWith(goalColorArgb: colorArgb));
  }

  void setAccountName(String name) {
    final current = state;
    if (current is! WizardReady) return;
    emit(
      current.copyWith(
        accountName: name,
        updateAccountNameError: true,
        accountNameError: _accountNameError(name),
      ),
    );
  }

  void setAccountColor(int colorArgb) {
    final current = state;
    if (current is! WizardReady) return;
    emit(current.copyWith(accountColorArgb: colorArgb));
  }

  void setDepositAmount(String amountText) {
    final current = state;
    if (current is! WizardReady) return;
    emit(
      current.copyWith(
        depositAmountText: amountText,
        updateDepositAmountError: true,
        depositAmountError: _depositAmountError(
          amountText,
          goalTargetText: current.goalTargetText,
        ),
      ),
    );
  }

  void setDepositNote(String note) {
    final current = state;
    if (current is! WizardReady) return;
    emit(current.copyWith(depositNote: note));
  }

  void setAllocateLater(bool allocateLater) {
    final current = state;
    if (current is! WizardReady) return;
    emit(current.copyWith(allocateLater: allocateLater));
  }

  String? _goalNameError(String name) {
    if (name.trim().isEmpty) return null;
    if (!EntityName.isValid(name)) return AppStrings.invalidEntityName;
    final taken =
        UniqueName.isTaken(existing: _existingGoals, candidateName: name);
    return taken ? AppStrings.duplicateGoalName : null;
  }

  String? _goalTargetError(String targetText) {
    return switch (classifyPositiveZarField(targetText)) {
      PositiveZarFieldState.empty => null,
      PositiveZarFieldState.incomplete => null,
      PositiveZarFieldState.invalid => AppStrings.invalidAmount,
      PositiveZarFieldState.negative => AppStrings.amountCannotBeNegative,
      PositiveZarFieldState.notPositive => AppStrings.goalTargetMustBePositive,
      PositiveZarFieldState.ok => null,
    };
  }

  String? _accountNameError(String name) {
    if (name.trim().isEmpty) return null;
    if (!EntityName.isValid(name)) return AppStrings.invalidEntityName;
    final taken =
        UniqueName.isTaken(existing: _existingAccounts, candidateName: name);
    return taken ? AppStrings.duplicateAccountName : null;
  }

  String? _depositAmountError(
    String amountText, {
    required String goalTargetText,
  }) {
    return switch (classifyPositiveZarField(amountText)) {
      PositiveZarFieldState.empty => null,
      PositiveZarFieldState.incomplete => null,
      PositiveZarFieldState.invalid => AppStrings.invalidAmount,
      PositiveZarFieldState.negative => AppStrings.amountCannotBeNegative,
      PositiveZarFieldState.notPositive => AppStrings.goalTargetMustBePositive,
      PositiveZarFieldState.ok => _depositRangeError(
          amountText,
          goalTargetText: goalTargetText,
        ),
    };
  }

  String? _depositRangeError(
    String amountText, {
    required String goalTargetText,
  }) {
    final cents = parseZarToCents(amountText);
    if (cents == null) return null;
    final targetCents = parseZarToCents(goalTargetText) ?? 0;
    final minCents = targetCents > 0 && targetCents < minDepositCents
        ? targetCents
        : minDepositCents;
    if (cents < minCents) return AppStrings.wizardDepositBelowMinimum;
    if (targetCents > 0 && cents > targetCents) {
      return AppStrings.wizardDepositAboveMaximum;
    }
    return null;
  }

  bool get canGoToStep2 {
    final current = state;
    if (current is! WizardReady) return false;
    return EntityName.isValid(current.goalName) &&
        current.goalNameError == null &&
        current.goalTargetError == null &&
        parseZarToCents(current.goalTargetText) != null &&
        parseZarToCents(current.goalTargetText)! > 0;
  }

  bool get canGoToStep3 {
    final current = state;
    if (current is! WizardReady) return false;
    return EntityName.isValid(current.accountName) &&
        current.accountNameError == null;
  }

  bool get canFinish {
    final current = state;
    if (current is! WizardReady) return false;
    if (current.allocateLater) return true;
    final cents = parseZarToCents(current.depositAmountText);
    return cents != null &&
        cents > 0 &&
        current.depositAmountError == null;
  }

  void goToStep2() {
    if (!canGoToStep2) return;
    final current = state;
    if (current is! WizardReady) return;
    emit(current.copyWith(step: 2));
  }

  void goToStep3() {
    if (!canGoToStep3) return;
    final current = state;
    if (current is! WizardReady) return;
    emit(
      current.copyWith(
        step: 3,
        updateDepositAmountError: true,
        depositAmountError: _depositAmountError(
          current.depositAmountText,
          goalTargetText: current.goalTargetText,
        ),
      ),
    );
  }

  void goBack() {
    final current = state;
    if (current is! WizardReady || current.step <= 1) return;
    emit(current.copyWith(step: current.step - 1));
  }

  Future<void> skip() async {
    final uid = await _userContext.resolveUserId();
    await _userContext.markFirstRunCompleted(uid);
    emit(const WizardSkipped());
  }

  Future<void> finish() async {
    if (!canFinish) return;
    final current = state;
    if (current is! WizardReady) return;
    await _complete(plantSeed: !current.allocateLater);
  }

  Future<void> _complete({required bool plantSeed}) async {
    final current = state;
    if (current is! WizardReady) return;

    emit(current.copyWith(submitting: true, clearError: true));

    try {
      final now = DateTime.now();
      final uid = await _userContext.resolveUserId();

      final goalCents = parseZarToCents(current.goalTargetText);
      if (goalCents == null || goalCents <= 0) {
        throw ValidationAppException(AppStrings.goalTargetMustBePositive);
      }

      final goal = Goal(
        id: _uuid.v4(),
        userId: uid,
        name: current.goalName.trim(),
        targetAmountCents: goalCents,
        color: current.goalColorArgb,
        createdAt: now,
        updatedAt: now,
        iconCodePoint: _defaultGoalIconCodePoint,
      );
      await _goalsService.saveGoal(goal);

      final account = Account(
        id: _uuid.v4(),
        userId: uid,
        name: current.accountName.trim(),
        color: current.accountColorArgb,
        createdAt: now,
        updatedAt: now,
      );
      await _accountsService.saveAccount(account);

      if (plantSeed) {
        final depositCents = parseZarToCents(current.depositAmountText);
        if (depositCents == null || depositCents <= 0) {
          throw ValidationAppException(AppStrings.invalidAmount);
        }
        final note = current.depositNote.trim();
        await _transactionsService.recordDeposit(
          accountId: account.id,
          goalId: goal.id,
          amountCents: depositCents,
          occurredAt: now,
          groupId: _uuid.v4(),
          note: note.isEmpty ? null : note,
        );
      }

      await _userContext.markFirstRunCompleted(uid);
      await _userContext.setPendingWelcomeToast(
        uid,
        plantSeed
            ? AppStrings.wizardFirstSeedPlanted
            : AppStrings.wizardSetupReady,
      );
      emit(WizardCompleted(plantedSeed: plantSeed));
    } on AppException catch (e) {
      emit(current.copyWith(submitting: false, errorMessage: e.message));
    } catch (e) {
      emit(
        current.copyWith(
          submitting: false,
          errorMessage: AppStrings.couldNotSave,
        ),
      );
    }
  }
}
