import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:sprout/features/purchases/domain/manage_subscription_plan.dart';
import 'package:sprout/features/purchases/domain/manage_subscription_plan_mapper.dart';

/// Outcome of a Customer Center session after the sheet is dismissed.
enum CustomerCenterOutcome { dismissed, restored, restoreFailed }

/// Outcome of an in-app restore attempt on Manage Subscription.
enum RestorePurchasesOutcome { restored, noPremium, failed }

/// Small presentation helper for RevenueCat paywall and Customer Center flows.
///
/// Keep this intentionally thin so the rest of the app doesn't need to know
/// about RevenueCat SDK types.
abstract final class PremiumPaywall {
  static const String kPremiumEntitlementId = 'premium';

  /// True when the SDK has been configured for this app process.
  static Future<bool> isPurchasesReady() async {
    return Purchases.isConfigured;
  }

  /// Best-effort RevenueCat logout after in-app account deletion.
  static Future<void> logOutIfConfigured() async {
    if (!await Purchases.isConfigured) return;
    await Purchases.logOut();
  }

  /// Best-effort RevenueCat identity sync after successful sign-in.
  ///
  /// When Purchases is configured, logs in with the stable app user ID so that
  /// RevenueCat entitlements (including promo grants for Maestro E2E) apply to
  /// the expected identity.
  static Future<void> logInIfConfigured(String appUserId) async {
    if (!await Purchases.isConfigured) return;
    await Purchases.logIn(appUserId);
  }

  /// Returns whether the user has the premium entitlement active.
  static Future<bool> hasPremium() async {
    if (!await Purchases.isConfigured) return false;

    final customerInfo = await Purchases.getCustomerInfo();
    return customerInfo.entitlements.active.containsKey(kPremiumEntitlementId);
  }

  /// Refreshes CustomerInfo from RevenueCat servers and returns whether the
  /// user has the premium entitlement active.
  ///
  /// Use this before opening Manage / Customer Center to avoid stale
  /// entitlement state after purchase on another device.
  static Future<bool> hasPremiumAfterRefresh() async {
    if (!await Purchases.isConfigured) return false;

    await Purchases.invalidateCustomerInfoCache();
    final customerInfo = await Purchases.getCustomerInfo();
    return customerInfo.entitlements.active.containsKey(kPremiumEntitlementId);
  }

  /// Loads plan display data for Manage Subscription from the active
  /// `premium` entitlement (+ offerings price when available).
  ///
  /// Returns `null` when Purchases is not ready or premium is not active.
  static Future<ManageSubscriptionPlan?> loadManageSubscriptionPlan() async {
    if (!await Purchases.isConfigured) return null;

    final customerInfo = await Purchases.getCustomerInfo();
    final entitlement =
        customerInfo.entitlements.active[kPremiumEntitlementId];
    if (entitlement == null) return null;

    final priceString = await _priceStringForProduct(
      entitlement.productIdentifier,
    );

    return ManageSubscriptionPlanMapper.build(
      productIdentifier: entitlement.productIdentifier,
      productPlanIdentifier: entitlement.productPlanIdentifier,
      periodType: entitlement.periodType.name,
      willRenew: entitlement.willRenew,
      expirationDateRaw: entitlement.expirationDate,
      priceString: priceString,
    );
  }

  /// Restores purchases via RevenueCat and reports whether premium is active.
  static Future<RestorePurchasesOutcome> restorePurchases() async {
    if (!await Purchases.isConfigured) {
      return RestorePurchasesOutcome.failed;
    }

    try {
      final info = await Purchases.restorePurchases();
      final hasPremium = info.entitlements.active.containsKey(
        kPremiumEntitlementId,
      );
      return hasPremium
          ? RestorePurchasesOutcome.restored
          : RestorePurchasesOutcome.noPremium;
    } on Object {
      return RestorePurchasesOutcome.failed;
    }
  }

  /// Presents the RevenueCat dashboard paywall (attached to the `premium`
  /// entitlement in the dashboard).
  ///
  /// RevenueCatUI owns the purchase/restore flow; do not call
  /// `Purchases.purchasePackage(...)` around this.
  static Future<PaywallResult> presentPremiumPaywall({
    bool displayCloseButton = true,
  }) {
    return RevenueCatUI.presentPaywallIfNeeded(
      kPremiumEntitlementId,
      displayCloseButton: displayCloseButton,
    );
  }

  /// Presents the RevenueCat Customer Center for an active subscriber.
  ///
  /// Used as tertiary help from Manage Subscription — not the primary Manage
  /// surface. RevenueCatUI owns restore callbacks while the sheet is open.
  static Future<CustomerCenterOutcome> presentCustomerCenter() async {
    var outcome = CustomerCenterOutcome.dismissed;
    await RevenueCatUI.presentCustomerCenter(
      onRestoreCompleted: (_) => outcome = CustomerCenterOutcome.restored,
      onRestoreFailed: (_) => outcome = CustomerCenterOutcome.restoreFailed,
    );
    return outcome;
  }

  static Future<String?> _priceStringForProduct(String productIdentifier) async {
    try {
      final offerings = await Purchases.getOfferings();
      for (final offering in offerings.all.values) {
        for (final package in offering.availablePackages) {
          if (package.storeProduct.identifier == productIdentifier) {
            return package.storeProduct.priceString;
          }
        }
      }
      final current = offerings.current;
      if (current != null) {
        for (final package in current.availablePackages) {
          if (package.storeProduct.identifier == productIdentifier) {
            return package.storeProduct.priceString;
          }
        }
      }
    } on Object {
      // Price is optional — plan name / status / dates still show.
    }
    return null;
  }
}
