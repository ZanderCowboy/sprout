/// Analytics event catalog for Sprout.
///
/// Single source of truth for all Firebase Analytics events, their parameters,
/// and allowed values. Call sites should reference this catalog rather than
/// using raw event name strings.
library;

/// Analytics event names.
abstract final class AnalyticsEvent {
  /// Automatic event tracked by Firebase SDK when app starts.
  static const String appOpen = 'app_open';

  /// Logged when a screen is viewed.
  ///
  /// Parameters: [AnalyticsParam.screenName]
  static const String screenView = 'screen_view';

  /// Logged when an existing user successfully signs in.
  ///
  /// Parameters: [AnalyticsParam.method]
  static const String signInSuccess = 'sign_in_success';

  /// Logged when a new user successfully creates an account.
  ///
  /// Parameters: [AnalyticsParam.method]
  static const String signUpSuccess = 'sign_up_success';

  /// Logged when a user successfully signs out.
  static const String signOut = 'sign_out';

  /// Logged when the first-run wizard is completed.
  static const String wizardCompleted = 'wizard_completed';

  /// Logged the first time a user records a deposit (one-time per user).
  static const String firstDepositLogged = 'first_deposit_logged';
}

/// Analytics event parameter names.
abstract final class AnalyticsParam {
  /// Screen name parameter for [AnalyticsEvent.screenView].
  ///
  /// Allowed values: [ScreenName]
  static const String screenName = 'screen_name';

  /// Sign-in/sign-up method parameter.
  ///
  /// Allowed values: [SignInMethod]
  static const String method = 'method';
}

/// Screen name values for [AnalyticsEvent.screenView].
abstract final class ScreenName {
  /// Home overview page.
  static const String overview = 'overview';

  /// Accounts list page.
  static const String accounts = 'accounts';

  /// Individual account detail page.
  static const String account = 'account';

  /// Goals list page.
  static const String goals = 'goals';

  /// Settings page.
  static const String settings = 'settings';

  /// Sign-in page.
  static const String signIn = 'sign_in';

  /// Create account page.
  static const String createAccount = 'create_account';

  /// OTP verification page.
  static const String verifyOtp = 'verify_otp';

  /// First-run wizard.
  static const String wizard = 'wizard';
}

/// Sign-in/sign-up method values for [AnalyticsEvent.signInSuccess]
/// and [AnalyticsEvent.signUpSuccess].
abstract final class SignInMethod {
  /// Email OTP verification.
  static const String emailOtp = 'email_otp';

  /// Google Sign-In.
  static const String google = 'google';

  /// Other methods (reserved).
  static const String other = 'other';
}
