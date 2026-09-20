/// Supported sign-in/sign-up methods.
enum SignInMethod {
  emailOtp('email_otp'),
  google('google'),
  other('other');

  const SignInMethod(this.value);
  final String value;
}

/// Firebase Analytics tracking for Sprout.
///
/// Tracks core events:
/// - `app_open` (automatically tracked by Firebase SDK)
/// - `screen_view` with screen_name param
/// - `sign_in_success` with method param
/// - `sign_up_success` with method param
/// - `sign_out`
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

  /// Logs a screen view.
  ///
  /// Event name: `screen_view`
  /// Params: `screen_name` (e.g. overview, accounts, sign_in, wizard)
  Future<void> logScreenView(String screenName);

  /// Logs a successful sign-in for an existing user.
  ///
  /// Event name: `sign_in_success`
  /// Params: `method` (email_otp | google | other)
  Future<void> logSignInSuccess(SignInMethod method);

  /// Logs a successful sign-up for a new user.
  ///
  /// Event name: `sign_up_success`
  /// Params: `method` (email_otp | google | other)
  Future<void> logSignUpSuccess(SignInMethod method);

  /// Logs a successful sign-out.
  ///
  /// Event name: `sign_out`
  Future<void> logSignOut();

  /// Logs wizard completion (first-run setup).
  ///
  /// Event name: `wizard_completed`
  Future<void> logWizardCompleted();

  /// Logs the first deposit recorded by the user.
  ///
  /// Event name: `first_deposit_logged`
  Future<void> logFirstDepositLogged();
}
