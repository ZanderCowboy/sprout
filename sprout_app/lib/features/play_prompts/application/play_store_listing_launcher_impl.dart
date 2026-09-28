import 'package:url_launcher/url_launcher.dart';

import 'play_store_listing_launcher.dart';
import 'play_store_listing_uris.dart';

class PlayStoreListingLauncherImpl implements PlayStoreListingLauncher {
  @override
  Future<void> openListing(String androidApplicationId) async {
    final market = PlayStoreListingUris.marketDetails(androidApplicationId);
    if (await canLaunchUrl(market)) {
      final launched = await launchUrl(
        market,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    }
    final https = PlayStoreListingUris.httpsDetails(androidApplicationId);
    await launchUrl(https, mode: LaunchMode.externalApplication);
  }
}
