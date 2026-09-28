/// Opens the app's Play Store listing (store navigation, not in-app update).
abstract class PlayStoreListingLauncher {
  /// Opens the listing for [androidApplicationId].
  Future<void> openListing(String androidApplicationId);
}
