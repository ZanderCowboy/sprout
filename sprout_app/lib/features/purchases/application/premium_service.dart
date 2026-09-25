import 'package:sprout/core/flags/remote_config_service.dart';
import 'package:sprout/core/flags/remote_feature_flag.dart';
import 'package:sprout/features/purchases/presentation/premium_paywall_helper.dart';

/// Service for checking premium feature access and subscription status.
///
/// Implements the V1 billing kill switch matrix:
/// - When `revenuecat_enabled` is false: all users can access Premium features
///   (fail-open), and paywalls/purchase flows are blocked.
/// - When `revenuecat_enabled` is true: only users with active RevenueCat
///   `premium` entitlement can access Premium features.
/// - Features that are not flagged as Premium: always accessible to everyone.
abstract class PremiumService {
  /// Returns whether the current user can use a Premium-flagged feature.
  ///
  /// Matrix:
  /// | Feature flagged Premium? | revenuecat_enabled | Result |
  /// |--------------------------|-------------------|--------|
  /// | No                      | on or off         | true   |
  /// | Yes                     | false             | true   |
  /// | Yes                     | true              | (check entitlement) |
  ///
  /// When the kill switch is off, this always returns true (fail-open for
  /// Premium features), but NEW purchases are blocked via [canShowPaywall].
  ///
  /// Does NOT mint fake local `subscribed=true` state when the flag is off.
  Future<bool> canUsePremiumFeature({required bool isPremiumFeature});

  /// Returns whether the paywall/purchase flow should be shown.
  ///
  /// When `revenuecat_enabled` is false, the paywall is hidden (purchases
  /// blocked) even though Premium features are accessible (fail-open).
  Future<bool> canShowPaywall();

  /// Returns the current Premium entitlement status from RevenueCat.
  ///
  /// Only reflects real RevenueCat entitlements when configured. Returns false
  /// when Purchases is not configured or the user has no active `premium`.
  ///
  /// This does NOT return true for free users when the kill switch is off.
  Future<bool> hasPremiumEntitlement();
}
