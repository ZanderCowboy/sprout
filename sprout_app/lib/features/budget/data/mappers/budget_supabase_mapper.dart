import '../../domain/budget_category.dart';
import '../../domain/budget_group.dart';
import '../../domain/budget_item.dart';
import '../remote/models/budget_group_row.dart';

BudgetGroup budgetGroupFromSupabaseRow(Map<String, dynamic> row) =>
    budgetGroupFromSupabaseDto(BudgetGroupRow.fromMap(row));

Map<String, dynamic> budgetGroupToSupabaseRow(BudgetGroup g) =>
    budgetGroupToSupabaseDto(g).toMap();

BudgetGroup budgetGroupFromSupabaseDto(BudgetGroupRow row) {
  return BudgetGroup(
    id: row.id,
    userId: row.userId,
    name: row.name,
    description: row.description,
    colorHex: row.colorHex,
    iconCodePoint: row.iconCodePoint,
    iconFontFamily: row.iconFontFamily,
    category: BudgetCategoryCodec.fromWireName(row.category),
    items: _decodeItems(row.itemsJson),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

BudgetGroupRow budgetGroupToSupabaseDto(BudgetGroup g) => BudgetGroupRow(
      id: g.id,
      userId: g.userId,
      name: g.name,
      description: g.description,
      category: g.category.wireName,
      colorHex: g.colorHex,
      iconCodePoint: g.iconCodePoint,
      iconFontFamily: g.iconFontFamily,
      itemsJson: g.items
          .map(
            (i) => {
              'id': i.id,
              'name': i.name,
              'amount': i.amount,
            },
          )
          .toList(),
      createdAt: g.createdAt,
      updatedAt: g.updatedAt,
    );

List<BudgetItem> _decodeItems(Object itemsJson) {
  try {
    if (itemsJson is! List) return const <BudgetItem>[];
    return itemsJson
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .map(
          (m) => BudgetItem(
            id: (m['id'] as String?) ?? '',
            name: (m['name'] as String?) ?? '',
            amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
          ),
        )
        .where((i) => i.id.isNotEmpty && i.name.trim().isNotEmpty)
        .toList();
  } on Object {
    return const <BudgetItem>[];
  }
}

