import 'package:flutter/services.dart';

import 'package:sprout/core/flags/remote_config_service.dart';

/// Loads Terms of Service markdown from Remote Config, with a bundled fallback.
class TermsOfServiceService {
  TermsOfServiceService({
    required RemoteConfigService remoteConfig,
    AssetBundle? assetBundle,
  }) : _remoteConfig = remoteConfig,
       _assetBundle = assetBundle ?? rootBundle;

  static const bundledAssetPath = 'assets/legal/terms.md';

  final RemoteConfigService _remoteConfig;
  final AssetBundle _assetBundle;

  /// Remote markdown when Firebase RC has a non-empty `terms_of_service`;
  /// otherwise the bundled asset (first launch / offline / prod until RC is on).
  Future<String> loadMarkdown() async {
    final remote = _remoteConfig.getString(RemoteConfigKeys.termsOfService);
    if (remote != null && remote.trim().isNotEmpty) {
      return remote;
    }
    return _assetBundle.loadString(bundledAssetPath);
  }
}
