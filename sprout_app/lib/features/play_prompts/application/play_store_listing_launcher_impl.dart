import 'package:url_launcher/url_launcher.dart';

import 'play_store_listing_launcher.dart';

class PlayStoreListingLauncherImpl implements PlayStoreListingLauncher {
  @override
  Future<void> openListing(String androidApplicationId) async {
    final market = Uri.parse('market://details?id=$androidApplicationId');
    if (await canLaunchUrl(market)) {
      final launched = await launchUrl(
        market,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    }
    final https = Uri.parse(
      'https://play.google.com/store/apps/details?id=$androidApplicationId',
    );
    await launchUrl(https, mode: LaunchMode.externalApplication);
  }
}
