/// Analytics event catalog exports.
///
/// Single source of truth for all Firebase Analytics events, their parameters,
/// and allowed values. Import this barrel to access the full catalog.
///
/// Each constant class is defined in its own file:
/// - [AnalyticsEvent] — Event names
/// - [AnalyticsParam] — Parameter names
/// - [AnalyticsScreenName] — Screen name values
/// - [AnalyticsSignInMethod] — Sign-in/sign-up method values
library;

export 'analytics_event.dart';
export 'analytics_param.dart';
export 'analytics_screen_name.dart';
export 'analytics_sign_in_method.dart';
