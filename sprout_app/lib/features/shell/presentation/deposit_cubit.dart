import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';

import 'enums/deposit_bottom_sheet_mode.dart';

class DepositAllocationRowState extends Equatable {
  const DepositAllocationRowState({
    this.goalId,
    this.amountText = '',
  });

  final String? goalId;
  final String amountText;

  DepositAllocationRowState copyWith({
    String? goalId,
    String? amountText,
  }) {
    return DepositAllocationRowState(
      goalId: goalId ?? this.goalId,
      amountText: amountText ?? this.amountText,
    );
  }

  @override
  List<Object?> get props => [goalId, amountText];
}

sealed class DepositState extends Equatable {
  const DepositState();
  @override
  List<Object?> get props => [];
}

final class DepositInitial extends DepositState {
  const DepositInitial();
}

final class DepositLoading extends DepositState {
  const DepositLoading();
}

final class DepositNoAccounts extends DepositState {
  const DepositNoAccounts();
}

final class DepositReady extends DepositState {
  const DepositReady({
    required this.accounts,
    required this.goals,
    required this.accountId,
    required this.goalId,
    required this.amountText,
    required this.selectedDate,
    required this.mode,
    required this.allocations,
    required this.isRecurring,
    required this.frequency,
    this.availableUnallocatedForAccountCents,
    this.errorMessage,
    this.submitting = false,
  });

  final List<Account> accounts;
  final List<Goal> goals;
  final String? accountId;
  final String? goalId;
  final String amountText;
  final DateTime selectedDate;
  final DepositBottomSheetMode mode;
  final List<DepositAllocationRowState> allocations;
  final bool isRecurring;
  final TransactionFrequency frequency;
  final int? availableUnallocatedForAccountCents;
  final String? errorMessage;
  final bool submitting;

  DepositReady copyWith({
    List<Account>? accounts,
    List<Goal>? goals,
    String? accountId,
    String? goalId,
    String? amountText,
    DateTime? selectedDate,
    DepositBottomSheetMode? mode,
    List<DepositAllocationRowState>? allocations,
    bool? isRecurring,
    TransactionFrequency? frequency,
    int? availableUnallocatedForAccountCents,
    String? errorMessage,
    bool? submitting,
    bool clearError = false,
    bool clearUnallocated = false,
  }) {
    return DepositReady(
      accounts: accounts ?? this.accounts,
      goals: goals ?? this.goals,
      accountId: accountId ?? this.accountId,
      goalId: goalId ?? this.goalId,
      amountText: amountText ?? this.amountText,
      selectedDate: selectedDate ?? this.selectedDate,
      mode: mode ?? this.mode,
      allocations: allocations ?? this.allocations,
      isRecurring: isRecurring ?? this.isRecurring,
      frequency: frequency ?? this.frequency,
      availableUnallocatedForAccountCents: clearUnallocated
          ? null
          : availableUnallocatedForAccountCents ??
              this.availableUnallocatedForAccountCents,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      submitting: submitting ?? this.submitting,
    );
  }

  @override
  List<Object?> get props => [
        accounts,
        goals,
        accountId,
        goalId,
        amountText,
        selectedDate,
        mode,
        allocations,
        isRecurring,
        frequency,
        availableUnallocatedForAccountCents,
        errorMessage,
        submitting,
      ];
}

final class DepositSubmitSuccess extends DepositState {
  const DepositSubmitSuccess();
}

class DepositCubit extends Cubit<DepositState> {
  DepositCubit({
    required AccountsService accountsService,
    required GoalsService goalsService,
    required TransactionsService transactionsService,
    String? initialAccountId,
    String? initialGoalId,
    int? initialAmountCents,
    DepositBottomSheetMode initialMode = DepositBottomSheetMode.fullDepositToGoal,
  })  : _accountsService = accountsService,
        _goalsService = goalsService,
        _transactionsService = transactionsService,
        _initialAccountId = initialAccountId,
        _initialGoalId = initialGoalId,
        _initialAmountCents = initialAmountCents,
        _initialMode = initialMode,
        super(const DepositInitial());

  final AccountsService _accountsService;
  final GoalsService _goalsService;
  final TransactionsService _transactionsService;
  final String? _initialAccountId;
  final String? _initialGoalId;
  final int? _initialAmountCents;
  final DepositBottomSheetMode _initialMode;
  static const _uuid = Uuid();

  Future<void> load() async {
    emit(const DepositLoading());
    final accounts = await _accountsService.getAccounts();
    if (accounts.isEmpty) {
      emit(const DepositNoAccounts());
      return;
    }
    final goals = await _goalsService.getGoals();
    final initialAccount = _initialAccountId;
    final initialGoal = _initialGoalId;
    final accountId = initialAccount != null &&
            accounts.any((a) => a.id == initialAccount)
        ? initialAccount
        : accounts.first.id;
    final goalId = initialGoal != null && goals.any((g) => g.id == initialGoal)
        ? initialGoal
        : (goals.isNotEmpty ? goals.first.id : null);
    final amountText = _initialAmountCents == null
        ? ''
        : (_initialAmountCents / 100).toStringAsFixed(2);

    var ready = DepositReady(
      accounts: accounts,
      goals: goals,
      accountId: accountId,
      goalId: goalId,
      amountText: amountText,
      selectedDate: DateTime.now(),
      mode: _initialMode,
      allocations: [DepositAllocationRowState(goalId: goalId)],
      isRecurring: false,
      frequency: TransactionFrequency.monthly,
    );
    emit(ready);

    if (_initialMode == DepositBottomSheetMode.allocateExistingUnallocated) {
      await refreshAvailableUnallocated();
    }
  }

  void setAccountId(String? accountId) {
    final current = state;
    if (current is! DepositReady) return;
    emit(current.copyWith(accountId: accountId, clearError: true));
  }

  void setGoalId(String? goalId) {
    final current = state;
    if (current is! DepositReady) return;
    emit(current.copyWith(goalId: goalId, clearError: true));
  }

  void setAmountText(String value) {
    final current = state;
    if (current is! DepositReady) return;
    emit(current.copyWith(amountText: value, clearError: true));
  }

  void setSelectedDate(DateTime value) {
    final current = state;
    if (current is! DepositReady) return;
    emit(current.copyWith(selectedDate: value, clearError: true));
  }

  Future<void> setMode(DepositBottomSheetMode mode) async {
    final current = state;
    if (current is! DepositReady) return;
    emit(current.copyWith(mode: mode, clearError: true));
    if (mode == DepositBottomSheetMode.allocateExistingUnallocated) {
      await refreshAvailableUnallocated();
    }
  }

  void setRecurring(bool value) {
    final current = state;
    if (current is! DepositReady) return;
    emit(current.copyWith(isRecurring: value, clearError: true));
  }

  void setFrequency(TransactionFrequency value) {
    final current = state;
    if (current is! DepositReady) return;
    emit(current.copyWith(frequency: value, clearError: true));
  }

  void setAllocationGoalId(int index, String? goalId) {
    final current = state;
    if (current is! DepositReady) return;
    if (index < 0 || index >= current.allocations.length) return;
    final next = [...current.allocations];
    next[index] = next[index].copyWith(goalId: goalId);
    emit(current.copyWith(allocations: next, clearError: true));
  }

  void setAllocationAmountText(int index, String value) {
    final current = state;
    if (current is! DepositReady) return;
    if (index < 0 || index >= current.allocations.length) return;
    final next = [...current.allocations];
    next[index] = next[index].copyWith(amountText: value);
    emit(current.copyWith(allocations: next, clearError: true));
  }

  void addAllocationRow() {
    final current = state;
    if (current is! DepositReady) return;
    emit(
      current.copyWith(
        allocations: [
          ...current.allocations,
          DepositAllocationRowState(goalId: current.goalId),
        ],
        clearError: true,
      ),
    );
  }

  void removeAllocationRow(int index) {
    final current = state;
    if (current is! DepositReady) return;
    if (current.allocations.length <= 1) return;
    if (index < 0 || index >= current.allocations.length) return;
    final next = [...current.allocations]..removeAt(index);
    emit(current.copyWith(allocations: next, clearError: true));
  }

  Future<void> refreshAvailableUnallocated() async {
    final current = state;
    if (current is! DepositReady) return;
    final accountId = current.accountId;
    if (accountId == null) return;
    final txs = await _transactionsService.getForAccount(accountId);
    final available = _transactionsService.unallocatedCentsForAccount(txs, accountId);
    emit(
      current.copyWith(
        availableUnallocatedForAccountCents: available,
        clearError: true,
      ),
    );
  }

  Future<void> submitForm({
    required String amountText,
    required List<({String? goalId, String amountText})> allocationRows,
  }) async {
    final current = state;
    if (current is! DepositReady) return;
    if (current.accountId == null) {
      emit(current.copyWith(errorMessage: AppStrings.pickAnAccount));
      return;
    }

    emit(current.copyWith(submitting: true, clearError: true));

    try {
      final depositCents = parseZarToCents(amountText);
      final allocations = [
        for (final row in allocationRows)
          DepositAllocationInput(
            goalId: row.goalId ?? '',
            amountCents: parseZarToCents(row.amountText) ?? 0,
          ),
      ];

      await _transactionsService.submitDepositFlow(
        mode: _mapMode(current.mode),
        accountId: current.accountId!,
        goalId: current.goalId,
        depositAmountCents: depositCents,
        allocations: allocations,
        occurredAt: current.selectedDate,
        groupId: _uuid.v4(),
        isRecurring: current.isRecurring,
        frequency: current.frequency,
        availableUnallocatedCents: current.availableUnallocatedForAccountCents,
      );
      emit(const DepositSubmitSuccess());
    } on ValidationAppException catch (e) {
      emit(current.copyWith(submitting: false, errorMessage: e.message));
    } catch (e) {
      emit(current.copyWith(submitting: false, errorMessage: e.toString()));
    }
  }

  DepositFlowMode _mapMode(DepositBottomSheetMode mode) {
    return switch (mode) {
      DepositBottomSheetMode.fullDepositToGoal =>
        DepositFlowMode.fullDepositToGoal,
      DepositBottomSheetMode.depositToAccountThenAllocate =>
        DepositFlowMode.depositToAccountThenAllocate,
      DepositBottomSheetMode.allocateExistingUnallocated =>
        DepositFlowMode.allocateExistingUnallocated,
    };
  }
}
