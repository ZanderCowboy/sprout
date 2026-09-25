import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/flags/remote_feature_flag.dart';
import 'package:sprout/features/purchases/application/premium_service.dart';
import 'package:sprout/features/purchases/application/premium_service_impl.dart';

import '../mocks/mocks.dart';

void main() {
  group('PremiumService', () {
    late FakeRemoteConfigService fakeRemoteConfig;
    late PremiumService premiumService;

    setUp(() {
      fakeRemoteConfig = FakeRemoteConfigService();
      premiumService = PremiumServiceImpl(
        remoteConfigService: fakeRemoteConfig,
      );
    });

    group('canUsePremiumFeature', () {
      test('returns true for non-premium features regardless of flag', () async {
        final result = await premiumService.canUsePremiumFeature(
          isPremiumFeature: false,
        );
        expect(result, true);
      });

      test(
        'returns true for premium features when revenuecat_enabled is false '
        '(fail-open)',
        () async {
          final result = await premiumService.canUsePremiumFeature(
            isPremiumFeature: true,
          );
          expect(result, true);
        },
      );

      test(
        'returns false for premium features when revenuecat_enabled is true '
        'and no entitlement',
        () async {
          fakeRemoteConfig = FakeRemoteConfigService();
          premiumService = PremiumServiceImpl(
            remoteConfigService: FakeRemoteConfigServiceWithFlag(
              revenueCatEnabled: true,
            ),
          );

          final result = await premiumService.canUsePremiumFeature(
            isPremiumFeature: true,
          );
          expect(result, false);
        },
      );
    });

    group('canShowPaywall', () {
      test('returns false when revenuecat_enabled is false', () async {
        final result = await premiumService.canShowPaywall();
        expect(result, false);
      });

      test(
        'returns false when revenuecat_enabled is true '
        'but Purchases not configured',
        () async {
          premiumService = PremiumServiceImpl(
            remoteConfigService: FakeRemoteConfigServiceWithFlag(
              revenueCatEnabled: true,
            ),
          );

          final result = await premiumService.canShowPaywall();
          expect(result, false);
        },
      );
    });

    group('hasPremiumEntitlement', () {
      test('returns false when Purchases not configured', () async {
        final result = await premiumService.hasPremiumEntitlement();
        expect(result, false);
      });
    });

    group('gate matrix', () {
      test(
        'Non-premium feature, flag off: accessible',
        () async {
          final result = await premiumService.canUsePremiumFeature(
            isPremiumFeature: false,
          );
          expect(result, true);
        },
      );

      test(
        'Non-premium feature, flag on: accessible',
        () async {
          premiumService = PremiumServiceImpl(
            remoteConfigService: FakeRemoteConfigServiceWithFlag(
              revenueCatEnabled: true,
            ),
          );

          final result = await premiumService.canUsePremiumFeature(
            isPremiumFeature: false,
          );
          expect(result, true);
        },
      );

      test(
        'Premium feature, flag off: accessible (fail-open)',
        () async {
          final result = await premiumService.canUsePremiumFeature(
            isPremiumFeature: true,
          );
          expect(result, true);
        },
      );

      test(
        'Premium feature, flag on, no entitlement: blocked',
        () async {
          premiumService = PremiumServiceImpl(
            remoteConfigService: FakeRemoteConfigServiceWithFlag(
              revenueCatEnabled: true,
            ),
          );

          final result = await premiumService.canUsePremiumFeature(
            isPremiumFeature: true,
          );
          expect(result, false);
        },
      );
    });

    group('paywall blocking when flag off', () {
      test('paywall hidden when revenuecat_enabled is false', () async {
        final canShow = await premiumService.canShowPaywall();
        expect(canShow, false);
      });

      test(
        'premium features accessible even when paywall hidden (flag off)',
        () async {
          final canShow = await premiumService.canShowPaywall();
          final canUse = await premiumService.canUsePremiumFeature(
            isPremiumFeature: true,
          );

          expect(canShow, false);
          expect(canUse, true);
        },
      );
    });
  });
}

class FakeRemoteConfigServiceWithFlag extends FakeRemoteConfigService {
  FakeRemoteConfigServiceWithFlag({required this.revenueCatEnabled});

  final bool revenueCatEnabled;

  @override
  bool isEnabled(RemoteFeatureFlag flag) {
    if (flag == RemoteFeatureFlag.revenueCatEnabled) {
      return revenueCatEnabled;
    }
    return flag.defaultValue;
  }
}
