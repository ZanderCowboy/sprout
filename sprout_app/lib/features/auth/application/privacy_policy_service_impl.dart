import 'package:flutter/services.dart';

import 'package:sprout/core/flags/remote_config_service.dart';
import 'privacy_policy_service.dart';

class PrivacyPolicyServiceImpl implements PrivacyPolicyService {
  PrivacyPolicyServiceImpl({
    required RemoteConfigService remoteConfig,
    AssetBundle? assetBundle,
  }) : _remoteConfig = remoteConfig,
       _assetBundle = assetBundle ?? rootBundle;

  final RemoteConfigService _remoteConfig;
  final AssetBundle _assetBundle;

  @override
  Future<String> loadMarkdown() async {
    final remote = _remoteConfig.getString(RemoteConfigKeys.privacyPolicy);
    if (remote != null && remote.trim().isNotEmpty) {
      return remote;
    }
    return _assetBundle.loadString(PrivacyPolicyService.bundledAssetPath);
  }
}
