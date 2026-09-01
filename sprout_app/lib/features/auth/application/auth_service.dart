import '../domain/auth_user.dart';

/// Auth use-cases: sign-in, session binding, sync gating, and account lifecycle.
abstract class AuthService {
  /// Stable user id for Maestro / development debug sign-in.
  static const maestroTestUserId = 'maestro-test-user';

  /// Stable [AuthUser] for Maestro / development debug sign-in.
  static const maestroTestUser = AuthUser(
    id: maestroTestUserId,
    email: 'maestro@test.local',
    displayName: 'Maestro Test',
    isAnonymous: false,
    signedInWithGoogle: false,
  );

  /// Current Supabase auth user, if any.
  AuthUser? get currentUser;

  /// Emits auth user changes from the repository.
  Stream<AuthUser?> authStateChanges();

  /// Development flavor only. Production never shows or accepts debug sign-in.
  bool get debugSignInAvailable;

  /// True after [debugSignIn] until [signOut] or [deleteAccount].
  bool get isDebugSignedIn;

  /// Development-only: skip OTP/Google and bind a stable local test user.
  Future<void> debugSignIn();

  /// Sync is allowed only with a verified (non-anonymous) Supabase session.
  bool get canSync;

  /// Sends an email OTP to [email].
  Future<void> sendEmailOtp(String email);

  /// Verifies the OTP and binds the verified session to local storage.
  Future<AuthUser> verifyEmailOtp({
    required String email,
    required String token,
    String? displayName,
  });

  /// Signs in with Google and binds the verified session.
  Future<AuthUser> signInWithGoogle();

  /// Updates the signed-in user's display name.
  Future<AuthUser> updateDisplayName(String displayName);

  /// Clears the Supabase session and keeps local Hive data / active_user_id.
  Future<void> signOut();

  /// Deletes the auth user remotely, wipes local entity Hive, then signs out.
  ///
  /// Keeps `intro_completed` in settings. Does not cancel Play billing.
  Future<void> deleteAccount();

  /// Same-uid re-login keeps the cache and flushes pending, then pulls.
  /// Any other bind discards leftover local Hive and pulls cloud only.
  Future<void> bindAfterVerifiedSignIn(AuthUser user);
}
