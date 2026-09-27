/// Port for checking whether Play has a newer build for this install.
abstract class PlayUpdateAvailabilityChecker {
  /// Returns true when Play reports an update is available.
  Future<bool> isUpdateAvailable();
}
