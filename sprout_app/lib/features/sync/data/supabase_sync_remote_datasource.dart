import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sprout/features/accounts/data/account_mapper.dart';
import 'package:sprout/features/budget/data/mappers/budget_supabase_mapper.dart';
import 'package:sprout/features/goals/data/goal_mapper.dart';
import 'package:sprout/features/transactions/data/pending_sync_payload.dart';
import 'package:sprout/features/transactions/data/supabase_tables.dart';
import 'package:sprout/features/transactions/data/transaction_mapper.dart';

import '../domain/pending_sync_operation.dart';
import '../domain/sync_remote_datasource.dart';

class SupabaseSyncRemoteDatasource implements SyncRemoteDatasource {
  SupabaseSyncRemoteDatasource(this._client);

  final SupabaseClient? _client;

  @override
  String? get authUserId {
    final id = _client?.auth.currentUser?.id;
    if (id == null || id.isEmpty) return null;
    return id;
  }

  @override
  Future<String?> apply({
    required PendingSyncOperationType type,
    required String payloadJson,
  }) async {
    final client = _client;
    final authUid = authUserId;
    if (client == null || authUid == null) {
      throw StateError(
        'SyncRemoteDatasource.apply requires a configured client '
        'and remote session.',
      );
    }

    switch (type) {
      case PendingSyncOperationType.insertTransaction:
        final t = decodeTransactionPayload(payloadJson);
        final txRow = transactionToSupabaseRow(t);
        txRow['user_id'] = authUid;
        await client.from(SupabaseTables.transactions).upsert(
              txRow,
              onConflict: 'id',
            );
        return t.id;
      case PendingSyncOperationType.upsertAccount:
        final a = decodeAccountPayload(payloadJson);
        final accountRow = accountToSupabaseRow(a);
        accountRow['user_id'] = authUid;
        await client.from(SupabaseTables.accounts).upsert(
              accountRow,
              onConflict: 'id',
            );
        return null;
      case PendingSyncOperationType.deleteAccount:
        final id = decodeIdPayload(payloadJson);
        await client.from(SupabaseTables.accounts).delete().eq('id', id);
        return null;
      case PendingSyncOperationType.upsertGoal:
        final g = decodeGoalPayload(payloadJson);
        final goalRow = goalToSupabaseRow(g);
        goalRow['user_id'] = authUid;
        await client.from(SupabaseTables.goals).upsert(
              goalRow,
              onConflict: 'id',
            );
        return null;
      case PendingSyncOperationType.deleteGoal:
        final id = decodeIdPayload(payloadJson);
        await client.from(SupabaseTables.goals).delete().eq('id', id);
        return null;
      case PendingSyncOperationType.deleteTransaction:
        final id = decodeIdPayload(payloadJson);
        await client.from(SupabaseTables.transactions).delete().eq('id', id);
        return null;
      case PendingSyncOperationType.upsertBudgetGroup:
        final bg = decodeBudgetGroupPayload(payloadJson);
        final row = budgetGroupToSupabaseRow(bg);
        row['user_id'] = authUid;
        await client.from(SupabaseTables.budgetGroups).upsert(
              row,
              onConflict: 'id',
            );
        return null;
      case PendingSyncOperationType.deleteBudgetGroup:
        final id = decodeIdPayload(payloadJson);
        await client.from(SupabaseTables.budgetGroups).delete().eq('id', id);
        return null;
    }
  }
}
