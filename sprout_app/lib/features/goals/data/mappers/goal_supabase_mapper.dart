import '../../domain/goal.dart';
import '../remote/models/goal_row.dart';

Goal goalFromSupabaseRow(Map<String, dynamic> row) =>
    goalFromSupabaseDto(GoalRow.fromMap(row));

Map<String, dynamic> goalToSupabaseRow(Goal g) =>
    goalToSupabaseDto(g).toMap();

Goal goalFromSupabaseDto(GoalRow row) {
  return Goal(
    id: row.id,
    userId: row.userId,
    name: row.name,
    targetAmountCents: row.targetAmountCents,
    color: row.color,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

GoalRow goalToSupabaseDto(Goal g) => GoalRow(
      id: g.id,
      userId: g.userId,
      name: g.name,
      targetAmountCents: g.targetAmountCents,
      color: g.color,
      createdAt: g.createdAt,
      updatedAt: g.updatedAt,
    );

