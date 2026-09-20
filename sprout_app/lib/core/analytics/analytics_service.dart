/// Firebase Analytics tracking for Sprout.
///
/// Thin wrapper around Firebase Analytics. Call sites decide *when* to fire
/// events based on business logic; the service only *sends* them.
///
/// For the complete event catalog (names, params, allowed values), see
/// `analytics_events.dart`.
///
/// No PII is logged. Development flavor sends to Firebase; production flavor
/// uses the same API but is not yet configured for PROD Firebase project.
abstract class AnalyticsService {
  /// True after Firebase Analytics has been initialized.
  bool get isReady;

  /// Initializes Firebase Analytics.
  ///
  /// No-op when Firebase is not configured. Logs failures silently in debug.
  Future<void> setup();

  /// Logs an analytics event with optional parameters.
  ///
  /// Use [AnalyticsEvent] constants for event names and [AnalyticsParam]
  /// for parameter names.
  Future<void> logEvent(String eventName, [Map<String, Object>? parameters]);
}
