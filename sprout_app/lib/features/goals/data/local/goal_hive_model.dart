class GoalHiveModel {
  GoalHiveModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmountCents,
    required this.color,
    required this.createdAtMillis,
    required this.updatedAtMillis,
  });

  final String id;
  final String userId;
  final String name;
  final int targetAmountCents;
  final int color;
  final int createdAtMillis;
  final int updatedAtMillis;
}
