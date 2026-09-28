import 'package:sprout/features/purchases/domain/enums/manage_subscription_period.dart';
import 'package:sprout/features/purchases/domain/enums/manage_subscription_status.dart';

/// Display model for the Manage Subscription plan card.
class ManageSubscriptionPlan {
  const ManageSubscriptionPlan({
    required this.planName,
    required this.period,
    required this.status,
    required this.willRenew,
    this.priceString,
    this.expirationDate,
  });

  /// Human plan title, e.g. `Annual Plan` / `Monthly Plan`.
  final String planName;

  final ManageSubscriptionPeriod period;
  final ManageSubscriptionStatus status;
  final bool willRenew;

  /// Localized store price when available (e.g. `R399.00`).
  final String? priceString;

  /// Entitlement expiration / renewal / trial-end date when known.
  final DateTime? expirationDate;
}
