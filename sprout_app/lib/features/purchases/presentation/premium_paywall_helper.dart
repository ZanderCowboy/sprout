import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// Small presentation helper for RevenueCat paywall flows.
///
/// Keep this intentionally thin so the rest of the app doesn't need to know
/// about RevenueCat SDK types.
abstract final class PremiumPaywall {
  static const String kPremiumEntitlementId = 'premium';

  /// True when the SDK has been configured for this app process.
  static Future<bool> isPurchasesReady() async {
    return await Purchases.isConfigured;
  }

  /// Returns whether the user has the premium entitlement active.
  static Future<bool> hasPremium() async {
    if (!await Purchases.isConfigured) return false;

    final customerInfo = await Purchases.getCustomerInfo();
    return customerInfo.entitlements.active.containsKey(
      kPremiumEntitlementId,
    );
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
}

