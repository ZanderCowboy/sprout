/// Remote Config feature flags (keys must match Firebase Console parameters).
enum RemoteFeatureFlag {
  /// Kill switch for `Purchases.configure` (all flavors).
  revenueCatEnabled('revenuecat_enabled', defaultValue: false),

  /// When true, show the detailed startup checklist UI instead of the splash.
  showStartupChecks('show_startup_checks', defaultValue: false),

  /// When true, enable DebugLens in production builds. Always enabled in DEV.
  debugLensEnabled('debug_lens_enabled', defaultValue: false),

  /// When true, allow the Settings App version gesture to open Environment.
  /// Always enabled in DEV. PROD default false; break-glass via RC conditions.
  environmentPageEnabled('environment_page_enabled', defaultValue: false);

  const RemoteFeatureFlag(this.key, {required this.defaultValue});

  /// Firebase Remote Config parameter name.
  final String key;

  /// Fail-closed / in-app default when unset, offline, or setup skipped.
  final bool defaultValue;
}
