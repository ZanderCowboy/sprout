/// Sign-in/sign-up method values for authentication analytics events.
abstract final class AnalyticsSignInMethod {
  /// Email OTP verification.
  static const String emailOtp = 'email_otp';

  /// Google Sign-In.
  static const String google = 'google';

  /// Other methods (reserved).
  static const String other = 'other';
}
