import 'package:flutter/foundation.dart';

import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/features/transactions/domain/transactions_repository.dart';
import '../data/pending_sync_queue.dart';
import '../domain/pending_sync_operation.dart';
import '../domain/sync_remote_datasource.dart';
import 'sync_service.dart';

class SyncServiceImpl implements SyncService {
  SyncServiceImpl({
    required PendingSyncQueue queue,
    required AppConfig config,
    required SyncRemoteDatasource remote,
    required TransactionsRepository transactionsRepository,
    required bool Function() canSync,
    this.onAfterFlush,
  })  : _queue = queue,
        _config = config,
        _remote = remote,
        _transactionsRepository = transactionsRepository,
        _canSync = canSync;

  final PendingSyncQueue _queue;
  final AppConfig _config;
  final SyncRemoteDatasource _remote;
  final TransactionsRepository _transactionsRepository;
  final bool Function() _canSync;

  @override
  final SyncFlushCallback? onAfterFlush;

  @override
  Future<void> flushPending() async {
    if (!_config.isSupabaseConfigured) return;
    if (!_canSync()) {
      if (kDebugMode) {
        debugPrint(
          'SyncService: verified Supabase session required; '
          'remote writes skipped until sign-in.',
        );
      }
      onAfterFlush?.call();
      return;
    }

    final authUid = _remote.authUserId;
    if (authUid == null || authUid.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'SyncService: no Supabase auth session; remote writes skipped.',
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
        final syncedTransactionId = await _remote.apply(
          type: type,
          payloadJson: item.payloadJson,
        );
        if (syncedTransactionId != null) {
          await _transactionsRepository.markTransactionSynced(
            syncedTransactionId,
          );
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
