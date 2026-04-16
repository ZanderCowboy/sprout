import '../../domain/goal.dart';
import '../local/models/goal_hive_model.dart';

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

