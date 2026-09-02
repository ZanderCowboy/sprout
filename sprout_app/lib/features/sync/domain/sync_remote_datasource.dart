import 'pending_sync_operation.dart';

/// Pushes pending sync operations to the remote backend.
abstract class SyncRemoteDatasource {
  /// Auth user id for the current remote session, or null if none.
  String? get authUserId;

  /// Writes [type] + [payloadJson] to the remote store.
  ///
  /// Returns the transaction id that should be marked locally synced after a
  /// successful [PendingSyncOperationType.insertTransaction], otherwise null.
  Future<String?> apply({
    required PendingSyncOperationType type,
    required String payloadJson,
  });
}
