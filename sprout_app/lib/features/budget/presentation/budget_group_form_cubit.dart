import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:sprout/core/core.dart';

import '../application/budget_service.dart';
import '../domain/budget_category.dart';
import '../domain/budget_group.dart';
import '../domain/budget_item.dart';

part 'budget_group_form_state.dart';

class BudgetGroupFormCubit extends Cubit<BudgetGroupFormState> {
  BudgetGroupFormCubit({
    required BudgetService budgetService,
    required UserContext userContext,
    BudgetGroup? initial,
  }) : _budgetService = budgetService,
       _userContext = userContext,
       _initial = initial,
       super(
         BudgetGroupFormReady(
           name: initial?.name ?? '',
           description: initial?.description ?? '',
           category: initial?.category ?? BudgetCategory.income,
         ),
       );

  final BudgetService _budgetService;
  final UserContext _userContext;
  final BudgetGroup? _initial;
  static const _uuid = Uuid();

  List<({String id, String name})> _existing = const [];

  Future<void> load() async {
    final list = await _budgetService.getBudgetGroups();
    _existing = list.map((g) => (id: g.id, name: g.name)).toList();
    final current = state;
    if (current is BudgetGroupFormReady) {
      emit(
        current.copyWith(
          loaded: true,
          updateNameError: true,
          nameError: _nameError(current.name),
        ),
      );
    }
  }

  void nameChanged(String name) {
    final current = state;
    if (current is! BudgetGroupFormReady) return;
    emit(
      current.copyWith(
        name: name,
        updateNameError: true,
        nameError: _nameError(name),
      ),
    );
  }

  void descriptionChanged(String description) {
    final current = state;
    if (current is! BudgetGroupFormReady) return;
    emit(current.copyWith(description: description));
  }

  void categoryChanged(BudgetCategory category) {
    final current = state;
    if (current is! BudgetGroupFormReady) return;
    emit(current.copyWith(category: category));
  }

  String? _nameError(String name) {
    if (name.trim().isEmpty) return null;
    final taken = UniqueName.isTaken(
      existing: _existing,
      candidateName: name,
      excludeId: _initial?.id,
    );
    return taken ? AppStrings.duplicateGroupName : null;
  }

  Future<void> submit({
    required int iconCodePoint,
    required String? iconFontFamily,
    required String colorHex,
  }) async {
    final current = state;
    if (current is! BudgetGroupFormReady || !current.canSave) return;

    emit(current.copyWith(submitting: true, clearSubmitError: true));

    try {
      final now = DateTime.now();
      final uid = await _userContext.resolveUserId();
      final description = current.description.trim();
      final group = BudgetGroup(
        id: _initial?.id ?? _uuid.v4(),
        userId: uid,
        name: current.name.trim(),
        description: description.isEmpty ? null : description,
        category: current.category,
        colorHex: colorHex,
        iconCodePoint: iconCodePoint,
        iconFontFamily: iconFontFamily,
        items: _initial?.items ?? const <BudgetItem>[],
        createdAt: _initial?.createdAt ?? now,
        updatedAt: now,
      );

      await _budgetService.saveBudgetGroup(group);
      emit(BudgetGroupFormSaved(group: group));
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
