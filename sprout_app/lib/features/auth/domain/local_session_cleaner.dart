/// Wipes locally persisted entity data and the pending sync queue.
///
/// Used when deleting an account or binding a different verified user.
/// Does not clear settings (`intro_completed`, active user id).
abstract class LocalSessionCleaner {
  /// Clears accounts, goals, budget groups, transactions, and pending sync.
  Future<void> clearLocalEntityData();
}
