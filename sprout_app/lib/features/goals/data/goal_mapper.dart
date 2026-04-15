import '../domain/goal.dart';
import 'local/goal_hive_model.dart';

Goal goalFromHive(GoalHiveModel m) => Goal(
      id: m.id,
      userId: m.userId,
      name: m.name,
      targetAmountCents: m.targetAmountCents,
      color: m.color,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m.createdAtMillis),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m.updatedAtMillis),
    );

GoalHiveModel goalToHive(Goal g) => GoalHiveModel(
      id: g.id,
      userId: g.userId,
      name: g.name,
      targetAmountCents: g.targetAmountCents,
      color: g.color,
      createdAtMillis: g.createdAt.millisecondsSinceEpoch,
      updatedAtMillis: g.updatedAt.millisecondsSinceEpoch,
    );

Goal goalFromSupabaseRow(Map<String, dynamic> row) {
  return Goal(
    id: row['id'] as String,
    userId: row['user_id'] as String,
    name: row['name'] as String,
    targetAmountCents: (row['target_amount_cents'] as num).toInt(),
    color: (row['color'] as num).toInt(),
    createdAt: DateTime.parse(row['created_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
  );
}

Map<String, dynamic> goalToSupabaseRow(Goal g) => {
      'id': g.id,
      'user_id': g.userId,
      'name': g.name,
      'target_amount_cents': g.targetAmountCents,
      'color': g.color,
      'created_at': g.createdAt.toUtc().toIso8601String(),
      'updated_at': g.updatedAt.toUtc().toIso8601String(),
    };
