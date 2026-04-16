class BudgetGroupRow {
  const BudgetGroupRow({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.category,
    required this.colorHex,
    required this.iconCodePoint,
    required this.iconFontFamily,
    required this.itemsJson,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? description;
  final String category;
  final String colorHex;
  final int? iconCodePoint;
  final String? iconFontFamily;

  /// Supabase jsonb decoded value (ideally `List<dynamic>`).
  final Object itemsJson;

  final DateTime createdAt;
  final DateTime updatedAt;

  factory BudgetGroupRow.fromMap(Map<String, dynamic> row) {
    return BudgetGroupRow(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      category: row['category'] as String,
      colorHex: row['color_hex'] as String,
      iconCodePoint: (row['icon_code_point'] as num?)?.toInt(),
      iconFontFamily: row['icon_font_family'] as String?,
      itemsJson: row['items_json'] ?? const <dynamic>[],
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'description': description,
        'category': category,
        'color_hex': colorHex,
        'icon_code_point': iconCodePoint,
        'icon_font_family': iconFontFamily,
        'items_json': itemsJson,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}

