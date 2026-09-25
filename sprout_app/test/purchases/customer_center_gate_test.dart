import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/features/purchases/application/premium_service.dart';
import 'package:sprout/features/purchases/application/premium_service_impl.dart';
import 'package:sprout/features/purchases/presentation/premium_paywall_helper.dart';

import '../mocks/mocks.dart';

void main() {
  group('Customer Center gating', () {
    late FakeRemoteConfigService fakeRemoteConfig;
    late PremiumService premiumService;

    setUp(() {
      fakeRemoteConfig = FakeRemoteConfigService();
      premiumService = PremiumServiceImpl(
        remoteConfigService: fakeRemoteConfig,
        hasPremium: () async => false,
        isPurchasesReady: () async => false,
      );
    });

    group('canShowPaywall gate', () {
      test('returns false when revenuecat_enabled is false', () async {
        final canShow = await premiumService.canShowPaywall();
        expect(canShow, false);
      });

      test(
        'returns false when revenuecat_enabled is true '
        'but Purchases not configured',
        () async {
          premiumService = PremiumServiceImpl(
            remoteConfigService: FakeRemoteConfigServiceWithFlag(
              revenueCatEnabled: true,
            ),
            hasPremium: () async => false,
            isPurchasesReady: () async => false,
          );

          final canShow = await premiumService.canShowPaywall();
          expect(canShow, false);
        },
      );

      test(
        'returns true when revenuecat_enabled is true '
        'and Purchases configured',
        () async {
          premiumService = PremiumServiceImpl(
            remoteConfigService: FakeRemoteConfigServiceWithFlag(
              revenueCatEnabled: true,
            ),
            hasPremium: () async => false,
            isPurchasesReady: () async => true,
          );

          final canShow = await premiumService.canShowPaywall();
          expect(canShow, true);
        },
      );
    });

    group('hasPremium vs hasPremiumAfterRefresh', () {
      test('hasPremium returns false when Purchases not configured', () async {
        final result = await PremiumPaywall.hasPremium();
        expect(result, false);
      });

      test(
        'hasPremiumAfterRefresh returns false when Purchases not configured',
        () async {
          final result = await PremiumPaywall.hasPremiumAfterRefresh();
          expect(result, false);
        },
      );
    });

    group('Customer Center presentation matrix', () {
      test(
        'Flag off, not premium: should block presentation',
        () async {
          premiumService = PremiumServiceImpl(
            remoteConfigService: FakeRemoteConfigService(),
            hasPremium: () async => false,
            isPurchasesReady: () async => false,
          );

          final canShow = await premiumService.canShowPaywall();
          expect(canShow, false);
        },
      );

      test(
        'Flag on, Purchases not ready, not premium: should block presentation',
        () async {
          premiumService = PremiumServiceImpl(
            remoteConfigService: FakeRemoteConfigServiceWithFlag(
              revenueCatEnabled: true,
            ),
            hasPremium: () async => false,
            isPurchasesReady: () async => false,
          );

          final canShow = await premiumService.canShowPaywall();
          expect(canShow, false);
        },
      );

      test(
        'Flag on, Purchases ready, not premium: should block presentation',
        () async {
          premiumService = PremiumServiceImpl(
            remoteConfigService: FakeRemoteConfigServiceWithFlag(
              revenueCatEnabled: true,
            ),
            hasPremium: () async => false,
            isPurchasesReady: () async => true,
          );

          final canShow = await premiumService.canShowPaywall();
          final hasPremium = await premiumService.hasPremiumEntitlement();
          expect(canShow, true);
          expect(
            hasPremium,
            false,
            reason: 'Not premium - Settings should not call presentCustomerCenter',
          );
        },
      );

      test(
        'Flag on, Purchases ready, has premium: can present Customer Center',
        () async {
          premiumService = PremiumServiceImpl(
            remoteConfigService: FakeRemoteConfigServiceWithFlag(
              revenueCatEnabled: true,
            ),
            hasPremium: () async => true,
            isPurchasesReady: () async => true,
          );

          final canShow = await premiumService.canShowPaywall();
          final hasPremium = await premiumService.hasPremiumEntitlement();
          expect(canShow, true);
          expect(hasPremium, true);
        },
      );
    });
  });
}
