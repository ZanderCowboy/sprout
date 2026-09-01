typedef SyncFlushCallback = void Function();

/// Flushes the pending sync queue to Supabase when a verified session exists.
abstract class SyncService {
  /// Optional callback invoked after each flush attempt (success or early exit).
  SyncFlushCallback? get onAfterFlush;

  /// Processes pending sync operations in order until one fails or the queue
  /// is empty.
  Future<void> flushPending();
}
