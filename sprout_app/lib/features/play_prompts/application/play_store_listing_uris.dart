/// Play Store listing URIs for [androidApplicationId].
abstract final class PlayStoreListingUris {
  /// Native Play Store deep link (`market://details?id=`).
  static Uri marketDetails(String androidApplicationId) =>
      Uri.parse('market://details?id=$androidApplicationId');

  /// HTTPS listing used when the market scheme cannot be launched.
  static Uri httpsDetails(String androidApplicationId) => Uri.https(
    'play.google.com',
    '/store/apps/details',
    {'id': androidApplicationId},
  );
}
