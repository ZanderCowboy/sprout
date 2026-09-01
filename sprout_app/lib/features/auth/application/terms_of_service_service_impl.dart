import 'package:flutter/services.dart';

import 'package:sprout/core/flags/remote_config_service.dart';
import 'terms_of_service_service.dart';

class TermsOfServiceServiceImpl implements TermsOfServiceService {
  TermsOfServiceServiceImpl({
    required RemoteConfigService remoteConfig,
    AssetBundle? assetBundle,
  }) : _remoteConfig = remoteConfig,
       _assetBundle = assetBundle ?? rootBundle;

  final RemoteConfigService _remoteConfig;
  final AssetBundle _assetBundle;

  @override
  Future<String> loadMarkdown() async {
    final remote = _remoteConfig.getString(RemoteConfigKeys.termsOfService);
    if (remote != null && remote.trim().isNotEmpty) {
      return remote;
    }
    return _assetBundle.loadString(TermsOfServiceService.bundledAssetPath);
  }
}
