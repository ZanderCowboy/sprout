/// Supported sign-in methods for the `sign_in_success` event.
enum SignInMethod {
  emailOtp('email_otp'),
  google('google'),
  other('other');

  const SignInMethod(this.value);
  final String value;
}

/// Firebase Analytics tracking for Sprout.
///
/// Tracks minimal MVP events:
/// - `app_open` (automatically tracked by Firebase SDK)
/// - `sign_in_success` with method param
/// - `wizard_completed`
/// - `first_deposit_logged`
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

  /// Logs a successful sign-in with the given method.
  ///
  /// Event name: `sign_in_success`
  /// Params: `method` (email_otp | google | other)
  Future<void> logSignInSuccess(SignInMethod method);

  /// Logs wizard completion (first-run setup).
  ///
  /// Event name: `wizard_completed`
  Future<void> logWizardCompleted();

  /// Logs the first deposit recorded by the user.
  ///
  /// Event name: `first_deposit_logged`
  Future<void> logFirstDepositLogged();
}
