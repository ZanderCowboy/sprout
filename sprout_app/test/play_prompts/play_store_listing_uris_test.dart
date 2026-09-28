import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/features/play_prompts/application/play_store_listing_uris.dart';

void main() {
  test('market and https listing URIs use the Android application id', () {
    const id = 'app.stackmint.sprout.dev';
    expect(
      PlayStoreListingUris.marketDetails(id).toString(),
      'market://details?id=$id',
    );
    expect(
      PlayStoreListingUris.httpsDetails(id).toString(),
      'https://play.google.com/store/apps/details?id=$id',
    );
  });
}
