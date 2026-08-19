import 'package:flutter/services.dart';

import 'package:sprout/core/flags/remote_config_service.dart';

/// Loads Privacy Policy markdown from Remote Config, with a bundled fallback.
class PrivacyPolicyService {
  PrivacyPolicyService({
    required RemoteConfigService remoteConfig,
    AssetBundle? assetBundle,
  }) : _remoteConfig = remoteConfig,
       _assetBundle = assetBundle ?? rootBundle;

  static const bundledAssetPath = 'assets/legal/privacy.md';

  final RemoteConfigService _remoteConfig;
  final AssetBundle _assetBundle;

  /// Remote markdown when Firebase RC has a non-empty `privacy_policy`;
  /// otherwise the bundled asset (first launch / offline / prod until RC is on).
  Future<String> loadMarkdown() async {
    final remote = _remoteConfig.getString(RemoteConfigKeys.privacyPolicy);
    if (remote != null && remote.trim().isNotEmpty) {
      return remote;
    }
    return _assetBundle.loadString(bundledAssetPath);
  }
}
