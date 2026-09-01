import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/budget_service.dart';
import '../domain/budget_group.dart';
import '../domain/budget_item.dart';
import '../domain/budget_totals.dart';

part 'budget_event.dart';
part 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  BudgetBloc({required BudgetService budgetService})
    : _budgetService = budgetService,
      super(const BudgetInitial()) {
    on<BudgetSubscriptionRequested>(_onSubscribe, transformer: restartable());
    on<BudgetGroupUpsertRequested>(_onUpsertGroup, transformer: sequential());
    on<BudgetGroupDeleted>(_onDeleteGroup, transformer: sequential());
    on<BudgetItemUpsertRequested>(_onUpsertItem, transformer: sequential());
    on<BudgetItemDeleted>(_onDeleteItem, transformer: sequential());
  }

  final BudgetService _budgetService;

  Future<void> _onSubscribe(
    BudgetSubscriptionRequested event,
    Emitter<BudgetState> emit,
  ) {
    return emit.forEach<BudgetReady>(
      _budgetService.watchBudgetGroups().map(BudgetReady.fromGroups),
      onData: (s) => s,
    );
  }

  Future<void> _onUpsertGroup(
    BudgetGroupUpsertRequested event,
    Emitter<BudgetState> emit,
  ) async {
    await _budgetService.saveBudgetGroup(event.group);
  }

  Future<void> _onDeleteGroup(
    BudgetGroupDeleted event,
    Emitter<BudgetState> emit,
  ) async {
    await _budgetService.removeBudgetGroup(event.groupId);
  }

  Future<void> _onUpsertItem(
    BudgetItemUpsertRequested event,
    Emitter<BudgetState> emit,
  ) async {
    final currentGroups = state is BudgetReady
        ? (state as BudgetReady).groups
        : await _budgetService.getBudgetGroups();

    final g = currentGroups.where((x) => x.id == event.groupId).firstOrNull;
    if (g == null) return;

    final items = [...g.items];
    final idx = items.indexWhere((i) => i.id == event.item.id);
    if (idx == -1) {
      items.add(event.item);
    } else {
      items[idx] = event.item;
    }
    final updated = g.copyWith(items: items, updatedAt: DateTime.now());
    await _budgetService.saveBudgetGroup(updated);
  }

  Future<void> _onDeleteItem(
    BudgetItemDeleted event,
    Emitter<BudgetState> emit,
  ) async {
    final currentGroups = state is BudgetReady
        ? (state as BudgetReady).groups
        : await _budgetService.getBudgetGroups();

    final g = currentGroups.where((x) => x.id == event.groupId).firstOrNull;
    if (g == null) return;

    final items = g.items.where((i) => i.id != event.itemId).toList();
    final updated = g.copyWith(items: items, updatedAt: DateTime.now());
    await _budgetService.saveBudgetGroup(updated);
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
