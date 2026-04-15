import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/sync/sync.dart';
import 'package:sprout/features/transactions/transactions.dart';
import '../domain/account.dart';
import '../domain/accounts_repository.dart';
import 'account_mapper.dart';
import 'local/account_hive_model.dart';

class AccountsRepositoryImpl implements AccountsRepository {
  AccountsRepositoryImpl({
    required Box<AccountHiveModel> box,
    required UserContext userContext,
    required AppConfig appConfig,
    SupabaseClient? supabase,
    PendingSyncQueue? pendingSyncQueue,
  })  : _box = box,
        _userContext = userContext,
        _appConfig = appConfig,
        _supabase = supabase,
        _pendingSyncQueue = pendingSyncQueue;

  final Box<AccountHiveModel> _box;
  final UserContext _userContext;
  final AppConfig _appConfig;
  final SupabaseClient? _supabase;
  final PendingSyncQueue? _pendingSyncQueue;
  final _updates = StreamController<void>.broadcast();

  void _notify() {
    if (!_updates.isClosed) _updates.add(null);
  }

  Future<void> _enqueueUpsert(Account a) async {
    final q = _pendingSyncQueue;
    if (_appConfig.isSupabaseConfigured && q != null) {
      await q.enqueue(
        PendingSyncOperationType.upsertAccount,
        encodeAccountPayload(a),
      );
    }
  }

  @override
  Stream<List<Account>> watchAccounts() async* {
    yield await getAccounts();
    await for (final _ in _updates.stream) {
      yield await getAccounts();
    }
  }

  @override
  Future<List<Account>> getAccounts() async {
    final uid = await _userContext.resolveUserId();
    final list = _box.values
        .map(accountFromHive)
        .where((a) => a.userId == uid)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Future<void> upsertAccount(Account account) async {
    await _box.put(account.id, accountToHive(account));
    _notify();
    await _enqueueUpsert(account);
  }

  @override
  Future<void> deleteAccount(String id) async {
    await _box.delete(id);
    _notify();
    final q = _pendingSyncQueue;
    if (_appConfig.isSupabaseConfigured && q != null) {
      await q.enqueue(
        PendingSyncOperationType.deleteAccount,
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
        .from(SupabaseTables.accounts)
        .select()
        .eq('user_id', uid);
    final rows = response as List<dynamic>;

    if (rows.isEmpty) {
      final hasLocal = _box.values.any((h) => h.userId == uid);
      if (hasLocal) return;
    }

    await _box.clear();
    for (final raw in rows) {
      final a = accountFromSupabaseRow(Map<String, dynamic>.from(raw as Map));
      await _box.put(a.id, accountToHive(a));
    }
    _notify();
  }
}
