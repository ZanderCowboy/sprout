import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:sprout/core/core.dart';

import '../application/goals_service.dart';
import '../domain/goal.dart';

part 'goal_form_state.dart';

class GoalFormCubit extends Cubit<GoalFormState> {
  GoalFormCubit({
    required GoalsService goalsService,
    required UserContext userContext,
    Goal? initial,
    required int defaultColorArgb,
  }) : _goalsService = goalsService,
       _userContext = userContext,
       _initial = initial,
       super(
         GoalFormReady(
           name: initial?.name ?? '',
           targetText: initial != null
               ? (initial.targetAmountCents / 100).toStringAsFixed(2)
               : '',
           colorArgb: initial?.color ?? defaultColorArgb,
         ),
       );

  final GoalsService _goalsService;
  final UserContext _userContext;
  final Goal? _initial;
  static const _uuid = Uuid();

  List<({String id, String name})> _existing = const [];

  Future<void> load() async {
    final list = await _goalsService.getGoals();
    _existing = list.map((g) => (id: g.id, name: g.name)).toList();
    final current = state;
    if (current is GoalFormReady) {
      emit(
        current.copyWith(
          loaded: true,
          updateNameError: true,
          updateTargetError: true,
          nameError: _nameError(current.name),
          targetError: _targetError(current.targetText),
        ),
      );
    }
  }

  void nameChanged(String name) {
    final current = state;
    if (current is! GoalFormReady) return;
    emit(
      current.copyWith(
        name: name,
        updateNameError: true,
        nameError: _nameError(name),
      ),
    );
  }

  void targetChanged(String targetText) {
    final current = state;
    if (current is! GoalFormReady) return;
    emit(
      current.copyWith(
        targetText: targetText,
        updateTargetError: true,
        targetError: _targetError(targetText),
      ),
    );
  }

  void colorChanged(int colorArgb) {
    final current = state;
    if (current is! GoalFormReady) return;
    emit(current.copyWith(colorArgb: colorArgb));
  }

  String? _nameError(String name) {
    if (name.trim().isEmpty) return null;
    final taken = UniqueName.isTaken(
      existing: _existing,
      candidateName: name,
      excludeId: _initial?.id,
    );
    return taken ? AppStrings.duplicateGoalName : null;
  }

  String? _targetError(String targetText) {
    return switch (classifyPositiveZarField(targetText)) {
      PositiveZarFieldState.empty => null,
      PositiveZarFieldState.incomplete => null,
      PositiveZarFieldState.invalid => AppStrings.invalidAmount,
      PositiveZarFieldState.negative => AppStrings.amountCannotBeNegative,
      PositiveZarFieldState.notPositive => AppStrings.goalTargetMustBePositive,
      PositiveZarFieldState.ok => null,
    };
  }

  Future<void> submit() async {
    final current = state;
    if (current is! GoalFormReady || !current.canSave) return;

    final cents = parseZarToCents(current.targetText);
    if (cents == null || cents <= 0) return;

    emit(current.copyWith(submitting: true, clearSubmitError: true));

    try {
      final now = DateTime.now();
      final uid = await _userContext.resolveUserId();
      final goal = Goal(
        id: _initial?.id ?? _uuid.v4(),
        userId: uid,
        name: current.name.trim(),
        targetAmountCents: cents,
        color: current.colorArgb,
        createdAt: _initial?.createdAt ?? now,
        updatedAt: now,
      );

      await _goalsService.saveGoal(goal);
      emit(GoalFormSaved(goal: goal));
    } on AppException catch (e) {
      emit(current.copyWith(submitting: false, submitError: e.message));
    } catch (_) {
      emit(
        current.copyWith(
          submitting: false,
          submitError: AppStrings.couldNotSave,
        ),
      );
    }
  }
}
