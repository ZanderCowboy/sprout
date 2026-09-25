import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/features/purchases/application/premium_service.dart';
import 'package:sprout/features/purchases/application/premium_service_impl.dart';

import '../mocks/mocks.dart';

void main() {
  group('Master Budget Premium gate', () {
    late PremiumService premiumService;

    group('Flag off (fail-open)', () {
      setUp(() {
        premiumService = PremiumServiceImpl(
          remoteConfigService: FakeRemoteConfigServiceWithFlag(
            revenueCatEnabled: false,
          ),
          hasPremium: () async => false,
          isPurchasesReady: () async => false,
        );
      });

      test('Master Budget accessible when flag off', () async {
        final canUse = await premiumService.canUsePremiumFeature(
          isPremiumFeature: true,
        );
        expect(canUse, true);
      });

      test('Paywall not shown when flag off', () async {
        final canShow = await premiumService.canShowPaywall();
        expect(canShow, false);
      });
    });

    group('Flag on, no Premium entitlement', () {
      setUp(() {
        premiumService = PremiumServiceImpl(
          remoteConfigService: FakeRemoteConfigServiceWithFlag(
            revenueCatEnabled: true,
          ),
          hasPremium: () async => false,
          isPurchasesReady: () async => true,
        );
      });

      test('Master Budget blocked without entitlement', () async {
        final canUse = await premiumService.canUsePremiumFeature(
          isPremiumFeature: true,
        );
        expect(canUse, false);
      });

      test('Paywall can be shown', () async {
        final canShow = await premiumService.canShowPaywall();
        expect(canShow, true);
      });
    });

    group('Flag on, Premium entitlement active', () {
      setUp(() {
        premiumService = PremiumServiceImpl(
          remoteConfigService: FakeRemoteConfigServiceWithFlag(
            revenueCatEnabled: true,
          ),
          hasPremium: () async => true,
          isPurchasesReady: () async => true,
        );
      });

      test('Master Budget accessible with Premium', () async {
        final canUse = await premiumService.canUsePremiumFeature(
          isPremiumFeature: true,
        );
        expect(canUse, true);
      });

      test('Has Premium entitlement', () async {
        final hasPremium = await premiumService.hasPremiumEntitlement();
        expect(hasPremium, true);
      });
    });

    group('Flag on, Purchases not ready', () {
      setUp(() {
        premiumService = PremiumServiceImpl(
          remoteConfigService: FakeRemoteConfigServiceWithFlag(
            revenueCatEnabled: true,
          ),
          hasPremium: () async => false,
          isPurchasesReady: () async => false,
        );
      });

      test('Master Budget blocked', () async {
        final canUse = await premiumService.canUsePremiumFeature(
          isPremiumFeature: true,
        );
        expect(canUse, false);
      });

      test('Paywall not shown when Purchases not ready', () async {
        final canShow = await premiumService.canShowPaywall();
        expect(canShow, false);
      });
    });
  });
}
