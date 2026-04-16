import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/budget_service.dart';
import '../domain/budget_category.dart';
import '../domain/budget_group.dart';
import '../domain/budget_item.dart';

sealed class BudgetEvent extends Equatable {
  const BudgetEvent();
  @override
  List<Object?> get props => [];
}

final class BudgetSubscriptionRequested extends BudgetEvent {
  const BudgetSubscriptionRequested();
}

final class BudgetGroupUpsertRequested extends BudgetEvent {
  const BudgetGroupUpsertRequested(this.group);
  final BudgetGroup group;

  @override
  List<Object?> get props => [group];
}

final class BudgetGroupDeleted extends BudgetEvent {
  const BudgetGroupDeleted(this.groupId);
  final String groupId;
  @override
  List<Object?> get props => [groupId];
}

final class BudgetItemUpsertRequested extends BudgetEvent {
  const BudgetItemUpsertRequested({
    required this.groupId,
    required this.item,
  });

  final String groupId;
  final BudgetItem item;

  @override
  List<Object?> get props => [groupId, item];
}

final class BudgetItemDeleted extends BudgetEvent {
  const BudgetItemDeleted({
    required this.groupId,
    required this.itemId,
  });

  final String groupId;
  final String itemId;

  @override
  List<Object?> get props => [groupId, itemId];
}

sealed class BudgetState extends Equatable {
  const BudgetState();
  @override
  List<Object?> get props => [];
}

final class BudgetInitial extends BudgetState {
  const BudgetInitial();
}

final class BudgetReady extends BudgetState {
  const BudgetReady({
    required this.groups,
    required this.groupTotals,
    required this.totalIncome,
    required this.totalEssentials,
    required this.totalLifestyle,
    required this.disposableIncome,
  });

  final List<BudgetGroup> groups;

  /// Total amount per groupId.
  final Map<String, double> groupTotals;

  final double totalIncome;
  final double totalEssentials;
  final double totalLifestyle;
  final double disposableIncome;

  factory BudgetReady.fromGroups(List<BudgetGroup> groups) {
    final totals = <String, double>{};
    var income = 0.0;
    var essentials = 0.0;
    var lifestyle = 0.0;

    for (final g in groups) {
      final total = g.items.fold<double>(0.0, (sum, i) => sum + i.amount);
      totals[g.id] = total;
      switch (g.category) {
        case BudgetCategory.income:
          income += total;
          break;
        case BudgetCategory.essentials:
          essentials += total;
          break;
        case BudgetCategory.lifestyle:
          lifestyle += total;
          break;
      }
    }

    return BudgetReady(
      groups: groups,
      groupTotals: totals,
      totalIncome: income,
      totalEssentials: essentials,
      totalLifestyle: lifestyle,
      disposableIncome: income - essentials - lifestyle,
    );
  }

  @override
  List<Object?> get props => [
        groups,
        groupTotals,
        totalIncome,
        totalEssentials,
        totalLifestyle,
        disposableIncome,
      ];
}

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  BudgetBloc({required BudgetService budgetService})
      : _budgetService = budgetService,
        super(const BudgetInitial()) {
    on<BudgetSubscriptionRequested>(
      _onSubscribe,
      transformer: restartable(),
    );
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

