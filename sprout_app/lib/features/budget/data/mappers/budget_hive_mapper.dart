import 'dart:convert';

import '../../domain/budget_category.dart';
import '../../domain/budget_group.dart';
import '../../domain/budget_item.dart';
import '../local/models/budget_group_hive_model.dart';

BudgetGroup budgetGroupFromHive(BudgetGroupHiveModel m) {
  final decoded = _decodeItems(m.itemsJson);
  return BudgetGroup(
    id: m.id,
    userId: m.userId,
    name: m.name,
    description: m.description,
    colorHex: m.colorHex,
    iconCodePoint: m.iconCodePoint,
    iconFontFamily: m.iconFontFamily,
    category: BudgetCategory.values[(m.categoryIndex >= 0 &&
            m.categoryIndex < BudgetCategory.values.length)
        ? m.categoryIndex
        : 0],
    items: decoded,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m.createdAtMillis),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(m.updatedAtMillis),
  );
}

BudgetGroupHiveModel budgetGroupToHive(BudgetGroup g) {
  return BudgetGroupHiveModel(
    id: g.id,
    userId: g.userId,
    name: g.name,
    description: g.description,
    colorHex: g.colorHex,
    iconCodePoint: g.iconCodePoint,
    iconFontFamily: g.iconFontFamily,
    categoryIndex: g.category.index,
    itemsJson: jsonEncode(
      g.items
          .map(
            (i) => {
              'id': i.id,
              'name': i.name,
              'amount': i.amount,
            },
          )
          .toList(),
    ),
    createdAtMillis: g.createdAt.millisecondsSinceEpoch,
    updatedAtMillis: g.updatedAt.millisecondsSinceEpoch,
  );
}

List<BudgetItem> _decodeItems(String json) {
  try {
    final raw = jsonDecode(json);
    if (raw is! List) return const <BudgetItem>[];
    return raw
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

