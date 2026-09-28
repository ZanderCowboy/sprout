import 'package:url_launcher/url_launcher.dart';

/// Opens Google Play subscription management in an external browser / Play app.
abstract final class PlaySubscriptionsLauncher {
  /// Play Console / design SoT management URL.
  static final Uri subscriptionsUri = Uri.https(
    'play.google.com',
    '/store/account/subscriptions',
  );

  /// Best-effort launch; returns whether a handler accepted the URL.
  static Future<bool> openManage() async {
    if (await canLaunchUrl(subscriptionsUri)) {
      return launchUrl(
        subscriptionsUri,
        mode: LaunchMode.externalApplication,
      );
    }
    return launchUrl(
      subscriptionsUri,
      mode: LaunchMode.externalApplication,
    );
  }
}
