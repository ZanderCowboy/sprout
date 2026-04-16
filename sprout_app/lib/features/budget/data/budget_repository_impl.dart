import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/sync/export.dart';
import 'package:sprout/features/transactions/export.dart';
import '../domain/budget_group.dart';
import '../domain/budget_repository.dart';
import 'budget_mapper.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl({
    required Box<BudgetGroupHiveModel> box,
    required UserContext userContext,
    required AppConfig appConfig,
    SupabaseClient? supabase,
    PendingSyncQueue? pendingSyncQueue,
  })  : _box = box,
        _userContext = userContext,
        _appConfig = appConfig,
        _supabase = supabase,
        _pendingSyncQueue = pendingSyncQueue;

  final Box<BudgetGroupHiveModel> _box;
  final UserContext _userContext;
  final AppConfig _appConfig;
  final SupabaseClient? _supabase;
  final PendingSyncQueue? _pendingSyncQueue;
  final _updates = StreamController<void>.broadcast();

  void _notify() {
    if (!_updates.isClosed) _updates.add(null);
  }

  @override
  Stream<List<BudgetGroup>> watchBudgetGroups() async* {
    yield await getBudgetGroups();
    await for (final _ in _updates.stream) {
      yield await getBudgetGroups();
    }
  }

  @override
  Future<List<BudgetGroup>> getBudgetGroups() async {
    final uid = await _userContext.resolveUserId();
    final list = _box.values
        .map(budgetGroupFromHive)
        .where((g) => g.userId == uid)
        .toList();
    list.sort((a, b) {
      final c = a.category.index.compareTo(b.category.index);
      if (c != 0) return c;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  @override
  Future<void> upsertBudgetGroup(BudgetGroup group) async {
    await _box.put(group.id, budgetGroupToHive(group));
    _notify();
    final q = _pendingSyncQueue;
    if (_appConfig.isSupabaseConfigured && q != null) {
      await q.enqueue(
        PendingSyncOperationType.upsertBudgetGroup,
        encodeBudgetGroupPayload(group),
      );
    }
  }

  @override
  Future<void> deleteBudgetGroup(String id) async {
    await _box.delete(id);
    _notify();
    final q = _pendingSyncQueue;
    if (_appConfig.isSupabaseConfigured && q != null) {
      await q.enqueue(
        PendingSyncOperationType.deleteBudgetGroup,
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
    final response =
        await client.from(SupabaseTables.budgetGroups).select().eq('user_id', uid);
    final rows = response as List<dynamic>;

    if (rows.isEmpty) {
      final hasLocal = _box.values.any((h) => h.userId == uid);
      if (hasLocal) return;
    }

    await _box.clear();
    for (final raw in rows) {
      final g =
          budgetGroupFromSupabaseRow(Map<String, dynamic>.from(raw as Map));
      await _box.put(g.id, budgetGroupToHive(g));
    }
    _notify();
  }
}

