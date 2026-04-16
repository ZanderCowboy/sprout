class GoalRow {
  const GoalRow({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmountCents,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final int targetAmountCents;
  final int color;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory GoalRow.fromMap(Map<String, dynamic> row) {
    return GoalRow(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      targetAmountCents: (row['target_amount_cents'] as num).toInt(),
      color: (row['color'] as num).toInt(),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'target_amount_cents': targetAmountCents,
        'color': color,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}

