import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/budget/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';
import '../data/pending_sync_queue.dart';
import '../domain/pending_sync_operation.dart';

typedef SyncFlushCallback = void Function();

class SyncService {
  SyncService({
    required PendingSyncQueue queue,
    required AppConfig config,
    required SupabaseClient? supabase,
    required TransactionsRepository transactionsRepository,
    this.onAfterFlush,
  })  : _queue = queue,
        _config = config,
        _supabase = supabase,
        _transactionsRepository = transactionsRepository;

  final PendingSyncQueue _queue;
  final AppConfig _config;
  final SupabaseClient? _supabase;
  final TransactionsRepository _transactionsRepository;
  final SyncFlushCallback? onAfterFlush;

  Future<void> flushPending() async {
    if (!_config.isSupabaseConfigured) return;
    final client = _supabase;
    if (client == null) return;

    final authUid = client.auth.currentUser?.id;
    if (authUid == null || authUid.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'SyncService: no Supabase auth session; remote writes skipped. '
          'Dashboard → Authentication → Providers → enable Anonymous.',
        );
      }
      onAfterFlush?.call();
      return;
    }

    final items = _queue.orderedPending();
    for (final item in items) {
      if (item.operationTypeIndex < 0 ||
          item.operationTypeIndex >= PendingSyncOperationType.values.length) {
        await _queue.remove(item.queueId);
        continue;
      }
      final type = PendingSyncOperationType.values[item.operationTypeIndex];
      try {
        switch (type) {
          case PendingSyncOperationType.insertTransaction:
            final t = decodeTransactionPayload(item.payloadJson);
            final txRow = transactionToSupabaseRow(t);
            txRow['user_id'] = authUid;
            await client.from(SupabaseTables.transactions).upsert(
                  txRow,
                  onConflict: 'id',
                );
            await _transactionsRepository.markTransactionSynced(t.id);
            break;
          case PendingSyncOperationType.upsertAccount:
            final a = decodeAccountPayload(item.payloadJson);
            final accountRow = accountToSupabaseRow(a);
            accountRow['user_id'] = authUid;
            await client.from(SupabaseTables.accounts).upsert(
                  accountRow,
                  onConflict: 'id',
                );
            break;
          case PendingSyncOperationType.deleteAccount:
            final id = decodeIdPayload(item.payloadJson);
            await client.from(SupabaseTables.accounts).delete().eq('id', id);
            break;
          case PendingSyncOperationType.upsertGoal:
            final g = decodeGoalPayload(item.payloadJson);
            final goalRow = goalToSupabaseRow(g);
            goalRow['user_id'] = authUid;
            await client.from(SupabaseTables.goals).upsert(
                  goalRow,
                  onConflict: 'id',
                );
            break;
          case PendingSyncOperationType.deleteGoal:
            final id = decodeIdPayload(item.payloadJson);
            await client.from(SupabaseTables.goals).delete().eq('id', id);
            break;
          case PendingSyncOperationType.deleteTransaction:
            final id = decodeIdPayload(item.payloadJson);
            await client.from(SupabaseTables.transactions).delete().eq('id', id);
            break;
          case PendingSyncOperationType.upsertBudgetGroup:
            final bg = decodeBudgetGroupPayload(item.payloadJson);
            final row = budgetGroupToSupabaseRow(bg);
            row['user_id'] = authUid;
            await client.from(SupabaseTables.budgetGroups).upsert(
                  row,
                  onConflict: 'id',
                );
            break;
          case PendingSyncOperationType.deleteBudgetGroup:
            final id = decodeIdPayload(item.payloadJson);
            await client.from(SupabaseTables.budgetGroups).delete().eq('id', id);
            break;
        }
        await _queue.remove(item.queueId);
      } on Object catch (e, st) {
        if (kDebugMode) {
          debugPrint('SyncService: failed on $type — $e');
          debugPrint('$st');
        }
        break;
      }
    }
    onAfterFlush?.call();
  }
}
