/// Port for Play In-App Review API.
abstract class PlayInAppReviewGateway {
  /// Returns whether the platform can show an in-app review flow.
  Future<bool> isAvailable();

  /// Requests the native in-app review UI (Play may no-op).
  Future<void> requestReview();
}
