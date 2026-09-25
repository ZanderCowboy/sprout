import 'package:sprout/core/flags/remote_config_service.dart';
import 'package:sprout/core/flags/remote_feature_flag.dart';
import 'package:sprout/features/purchases/presentation/premium_paywall_helper.dart';

import 'premium_service.dart';

class PremiumServiceImpl implements PremiumService {
  PremiumServiceImpl({
    required RemoteConfigService remoteConfigService,
    Future<bool> Function()? hasPremium,
    Future<bool> Function()? isPurchasesReady,
  })  : _remoteConfigService = remoteConfigService,
        _hasPremium = hasPremium ?? PremiumPaywall.hasPremium,
        _isPurchasesReady = isPurchasesReady ?? PremiumPaywall.isPurchasesReady;

  final RemoteConfigService _remoteConfigService;
  final Future<bool> Function() _hasPremium;
  final Future<bool> Function() _isPurchasesReady;

  @override
  Future<bool> canUsePremiumFeature({required bool isPremiumFeature}) async {
    if (!isPremiumFeature) return true;

    final revenueCatEnabled =
        _remoteConfigService.isEnabled(RemoteFeatureFlag.revenueCatEnabled);

    if (!revenueCatEnabled) return true;

    return _hasPremium();
  }

  @override
  Future<bool> canShowPaywall() async {
    final revenueCatEnabled =
        _remoteConfigService.isEnabled(RemoteFeatureFlag.revenueCatEnabled);
    if (!revenueCatEnabled) return false;

    return _isPurchasesReady();
  }

  @override
  Future<bool> hasPremiumEntitlement() async {
    return _hasPremium();
  }
}
