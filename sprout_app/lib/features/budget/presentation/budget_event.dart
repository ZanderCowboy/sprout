part of 'budget_bloc.dart';

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
