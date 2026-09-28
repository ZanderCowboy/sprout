import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/features/purchases/domain/enums/manage_subscription_period.dart';
import 'package:sprout/features/purchases/domain/enums/manage_subscription_status.dart';
import 'package:sprout/features/purchases/domain/manage_subscription_plan_mapper.dart';

void main() {
  group('ManageSubscriptionPlanMapper.periodFromIdentifiers', () {
    test('maps premium_annual / yearly to annual', () {
      expect(
        ManageSubscriptionPlanMapper.periodFromIdentifiers(
          productIdentifier: 'premium_annual',
          productPlanIdentifier: 'yearly',
        ),
        ManageSubscriptionPeriod.annual,
      );
    });

    test('maps premium_monthly / monthly to monthly', () {
      expect(
        ManageSubscriptionPlanMapper.periodFromIdentifiers(
          productIdentifier: 'premium_monthly',
          productPlanIdentifier: 'monthly',
        ),
        ManageSubscriptionPeriod.monthly,
      );
    });

    test('defaults ambiguous ids to annual (never raw store id)', () {
      expect(
        ManageSubscriptionPlanMapper.periodFromIdentifiers(
          productIdentifier: 'unknown_sku',
        ),
        ManageSubscriptionPeriod.annual,
      );
      expect(
        ManageSubscriptionPlanMapper.planNameFor(
          ManageSubscriptionPeriod.annual,
        ),
        'Annual Plan',
      );
    });
  });

  group('ManageSubscriptionPlanMapper.statusFromPeriodType', () {
    test('trial periodType → Trial', () {
      expect(
        ManageSubscriptionPlanMapper.statusFromPeriodType('trial'),
        ManageSubscriptionStatus.trial,
      );
    });

    test('normal / intro / unknown → Active', () {
      for (final value in ['normal', 'intro', 'unknown', null, '']) {
        expect(
          ManageSubscriptionPlanMapper.statusFromPeriodType(value),
          ManageSubscriptionStatus.active,
        );
      }
    });
  });

  group('ManageSubscriptionPlanMapper.dateLine', () {
    String format(DateTime d) => '28 Oct 2026';

    test('omits row when date is null', () {
      expect(
        ManageSubscriptionPlanMapper.dateLine(
          status: ManageSubscriptionStatus.active,
          willRenew: true,
          expirationDate: null,
          formatDate: format,
        ),
        isNull,
      );
    });

    test('trial → Trial ends on', () {
      expect(
        ManageSubscriptionPlanMapper.dateLine(
          status: ManageSubscriptionStatus.trial,
          willRenew: true,
          expirationDate: DateTime.utc(2026, 10, 28),
          formatDate: format,
        ),
        'Trial ends on 28 Oct 2026',
      );
    });

    test('willRenew → Renews on', () {
      expect(
        ManageSubscriptionPlanMapper.dateLine(
          status: ManageSubscriptionStatus.active,
          willRenew: true,
          expirationDate: DateTime.utc(2026, 10, 28),
          formatDate: format,
        ),
        'Renews on 28 Oct 2026',
      );
    });

    test('!willRenew → Expires on', () {
      expect(
        ManageSubscriptionPlanMapper.dateLine(
          status: ManageSubscriptionStatus.active,
          willRenew: false,
          expirationDate: DateTime.utc(2026, 10, 28),
          formatDate: format,
        ),
        'Expires on 28 Oct 2026',
      );
    });
  });

  group('ManageSubscriptionPlanMapper.build', () {
    test('builds Annual Plan with price and Active status', () {
      final plan = ManageSubscriptionPlanMapper.build(
        productIdentifier: 'premium_annual',
        productPlanIdentifier: 'yearly',
        periodType: 'normal',
        willRenew: true,
        expirationDateRaw: '2026-10-28T00:00:00Z',
        priceString: 'R399.00',
      );

      expect(plan.planName, 'Annual Plan');
      expect(plan.period, ManageSubscriptionPeriod.annual);
      expect(plan.status, ManageSubscriptionStatus.active);
      expect(plan.priceString, 'R399.00');
      expect(plan.willRenew, isTrue);
      expect(plan.expirationDate, isNotNull);
    });

    test('builds without price when missing', () {
      final plan = ManageSubscriptionPlanMapper.build(
        productIdentifier: 'premium_monthly',
        productPlanIdentifier: 'monthly',
        periodType: 'trial',
        willRenew: true,
        expirationDateRaw: null,
        priceString: null,
      );

      expect(plan.planName, 'Monthly Plan');
      expect(plan.status, ManageSubscriptionStatus.trial);
      expect(plan.priceString, isNull);
      expect(plan.expirationDate, isNull);
    });
  });
}
