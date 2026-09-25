import 'package:sprout/core/flags/remote_config_service.dart';
import 'package:sprout/core/flags/remote_feature_flag.dart';
import 'package:sprout/features/purchases/presentation/premium_paywall_helper.dart';

import 'premium_service.dart';

class PremiumServiceImpl implements PremiumService {
  PremiumServiceImpl({
    required RemoteConfigService remoteConfigService,
  }) : _remoteConfigService = remoteConfigService;

  final RemoteConfigService _remoteConfigService;

  @override
  Future<bool> canUsePremiumFeature({required bool isPremiumFeature}) async {
    if (!isPremiumFeature) return true;

    final revenueCatEnabled =
        _remoteConfigService.isEnabled(RemoteFeatureFlag.revenueCatEnabled);

    if (!revenueCatEnabled) return true;

    return PremiumPaywall.hasPremium();
  }

  @override
  Future<bool> canShowPaywall() async {
    final revenueCatEnabled =
        _remoteConfigService.isEnabled(RemoteFeatureFlag.revenueCatEnabled);
    if (!revenueCatEnabled) return false;

    return PremiumPaywall.isPurchasesReady();
  }

  @override
  Future<bool> hasPremiumEntitlement() async {
    return PremiumPaywall.hasPremium();
  }
}
