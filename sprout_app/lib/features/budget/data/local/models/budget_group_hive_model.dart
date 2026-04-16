class BudgetGroupHiveModel {
  BudgetGroupHiveModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.colorHex,
    required this.iconCodePoint,
    required this.iconFontFamily,
    required this.categoryIndex,
    required this.itemsJson,
    required this.createdAtMillis,
    required this.updatedAtMillis,
  });

  final String id;
  final String userId;
  final String name;
  final String? description;
  final String colorHex;
  final int? iconCodePoint;
  final String? iconFontFamily;
  final int categoryIndex;
  final String itemsJson;
  final int createdAtMillis;
  final int updatedAtMillis;
}

