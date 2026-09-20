/// Analytics event name constants.
///
/// Single source of truth for all Firebase Analytics event names tracked
/// in Sprout.
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
