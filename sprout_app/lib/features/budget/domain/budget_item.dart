import 'package:equatable/equatable.dart';

class BudgetItem extends Equatable {
  const BudgetItem({
    required this.id,
    required this.name,
    required this.amount,
  });

  /// Used when the user adds another draft item without naming the previous one.
  static const String defaultDraftName = 'Item name';

  final String id;
  final String name;

  /// Major units (ZAR).
  final double amount;

  BudgetItem copyWith({
    String? id,
    String? name,
    double? amount,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
    );
  }

  @override
  List<Object?> get props => [id, name, amount];
}

