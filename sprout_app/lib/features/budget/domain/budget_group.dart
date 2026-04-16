import 'package:equatable/equatable.dart';

import 'budget_category.dart';
import 'budget_item.dart';

class BudgetGroup extends Equatable {
  const BudgetGroup({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.colorHex,
    required this.iconCodePoint,
    required this.iconFontFamily,
    required this.category,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? description;

  /// `#AARRGGBB` or `#RRGGBB` (UI will normalize).
  final String colorHex;

  final int? iconCodePoint;
  final String? iconFontFamily;

  final BudgetCategory category;
  final List<BudgetItem> items;

  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetGroup copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? colorHex,
    int? iconCodePoint,
    String? iconFontFamily,
    BudgetCategory? category,
    List<BudgetItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetGroup(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      category: category ?? this.category,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get totalAmount => items.fold<double>(0.0, (sum, i) => sum + i.amount);

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        colorHex,
        iconCodePoint,
        iconFontFamily,
        category,
        items,
        createdAt,
        updatedAt,
      ];
}

