import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/sync/sync.dart';
import 'package:sprout/features/transactions/transactions.dart';
import '../domain/goal.dart';
import '../domain/goals_repository.dart';
import 'goal_mapper.dart';
import 'local/goal_hive_model.dart';

class GoalsRepositoryImpl implements GoalsRepository {
  GoalsRepositoryImpl({
    required Box<GoalHiveModel> box,
    required UserContext userContext,
    required AppConfig appConfig,
    SupabaseClient? supabase,
    PendingSyncQueue? pendingSyncQueue,
  })  : _box = box,
        _userContext = userContext,
        _appConfig = appConfig,
        _supabase = supabase,
        _pendingSyncQueue = pendingSyncQueue;

  final Box<GoalHiveModel> _box;
  final UserContext _userContext;
  final AppConfig _appConfig;
  final SupabaseClient? _supabase;
  final PendingSyncQueue? _pendingSyncQueue;
  final _updates = StreamController<void>.broadcast();

  void _notify() {
    if (!_updates.isClosed) _updates.add(null);
  }

  @override
  Stream<List<Goal>> watchGoals() async* {
    yield await getGoals();
    await for (final _ in _updates.stream) {
      yield await getGoals();
    }
  }

  @override
  Future<List<Goal>> getGoals() async {
    final uid = await _userContext.resolveUserId();
    return _box.values
        .map(goalFromHive)
        .where((g) => g.userId == uid)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<void> upsertGoal(Goal goal) async {
    await _box.put(goal.id, goalToHive(goal));
    _notify();
    final q = _pendingSyncQueue;
    if (_appConfig.isSupabaseConfigured && q != null) {
      await q.enqueue(
        PendingSyncOperationType.upsertGoal,
        encodeGoalPayload(goal),
      );
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _box.delete(id);
    _notify();
    final q = _pendingSyncQueue;
    if (_appConfig.isSupabaseConfigured && q != null) {
      await q.enqueue(
        PendingSyncOperationType.deleteGoal,
        encodeIdPayload(id),
      );
    }
  }

  @override
  Future<void> pullRemote() async {
    if (!_appConfig.isSupabaseConfigured) return;
    final client = _supabase;
    if (client == null) return;
    if ((_pendingSyncQueue?.length ?? 0) > 0) return;

    final uid = await _userContext.resolveUserId();
    final response = await client
        .from(SupabaseTables.goals)
        .select()
        .eq('user_id', uid);
    final rows = response as List<dynamic>;

    if (rows.isEmpty) {
      final hasLocal = _box.values.any((h) => h.userId == uid);
      if (hasLocal) return;
    }

    await _box.clear();
    for (final raw in rows) {
      final g = goalFromSupabaseRow(Map<String, dynamic>.from(raw as Map));
      await _box.put(g.id, goalToHive(g));
    }
    _notify();
  }
}
