/// Remote Config feature flags (keys must match Firebase Console parameters).
enum RemoteFeatureFlag {
  /// Kill switch for `Purchases.configure` (development only today).
  revenueCatEnabled('revenuecat_enabled', defaultValue: false);

  const RemoteFeatureFlag(this.key, {required this.defaultValue});

  /// Firebase Remote Config parameter name.
  final String key;

  /// Fail-closed / in-app default when unset, offline, or setup skipped.
  final bool defaultValue;
}
