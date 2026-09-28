import 'package:sprout/features/purchases/domain/enums/manage_subscription_period.dart';
import 'package:sprout/features/purchases/domain/enums/manage_subscription_status.dart';
import 'package:sprout/features/purchases/domain/manage_subscription_plan.dart';

/// Pure helpers that turn RevenueCat entitlement / product ids into UI copy.
abstract final class ManageSubscriptionPlanMapper {
  static const String annualPlanName = 'Annual Plan';
  static const String monthlyPlanName = 'Monthly Plan';

  /// Resolves Annual vs Monthly from product / base-plan identifiers.
  ///
  /// Prefers explicit annual/yearly or monthly tokens; defaults to annual when
  /// ambiguous so we never surface a raw store id as the plan title.
  static ManageSubscriptionPeriod periodFromIdentifiers({
    required String productIdentifier,
    String? productPlanIdentifier,
  }) {
    final haystack =
        '${productIdentifier}_${productPlanIdentifier ?? ''}'.toLowerCase();
    if (_looksAnnual(haystack)) {
      return ManageSubscriptionPeriod.annual;
    }
    if (_looksMonthly(haystack)) {
      return ManageSubscriptionPeriod.monthly;
    }
    // Prefer annual when ambiguous (locked Play catalog is monthly + annual).
    return ManageSubscriptionPeriod.annual;
  }

  static String planNameFor(ManageSubscriptionPeriod period) {
    return switch (period) {
      ManageSubscriptionPeriod.annual => annualPlanName,
      ManageSubscriptionPeriod.monthly => monthlyPlanName,
    };
  }

  static ManageSubscriptionStatus statusFromPeriodType(String? periodType) {
    final normalized = (periodType ?? '').toLowerCase();
    if (normalized == 'trial') {
      return ManageSubscriptionStatus.trial;
    }
    return ManageSubscriptionStatus.active;
  }

  /// Builds the date-row label, or `null` when [expirationDate] is missing.
  static String? dateLine({
    required ManageSubscriptionStatus status,
    required bool willRenew,
    required DateTime? expirationDate,
    required String Function(DateTime date) formatDate,
  }) {
    if (expirationDate == null) return null;
    final formatted = formatDate(expirationDate);
    if (status == ManageSubscriptionStatus.trial) {
      return 'Trial ends on $formatted';
    }
    if (willRenew) {
      return 'Renews on $formatted';
    }
    return 'Expires on $formatted';
  }

  /// Parses an ISO-8601 entitlement date string; returns null when unusable.
  static DateTime? parseEntitlementDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static ManageSubscriptionPlan build({
    required String productIdentifier,
    String? productPlanIdentifier,
    required String? periodType,
    required bool willRenew,
    required String? expirationDateRaw,
    String? priceString,
  }) {
    final period = periodFromIdentifiers(
      productIdentifier: productIdentifier,
      productPlanIdentifier: productPlanIdentifier,
    );
    final status = statusFromPeriodType(periodType);
    return ManageSubscriptionPlan(
      planName: planNameFor(period),
      period: period,
      status: status,
      willRenew: willRenew,
      priceString: priceString,
      expirationDate: parseEntitlementDate(expirationDateRaw),
    );
  }

  static bool _looksAnnual(String haystack) {
    return haystack.contains('annual') || haystack.contains('yearly');
  }

  static bool _looksMonthly(String haystack) {
    return haystack.contains('monthly') ||
        haystack.contains(':monthly') ||
        RegExp(r'(^|[_\-:.])month([_\-:.]|$)').hasMatch(haystack);
  }
}
