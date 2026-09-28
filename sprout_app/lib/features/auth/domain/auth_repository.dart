import 'auth_user.dart';

abstract class AuthRepository {
  AuthUser? get currentUser;

  Stream<AuthUser?> authStateChanges();

  Future<void> sendRegisterOtp(String email);

  Future<void> sendSignInOtp(String email);

  /// Sends another email OTP without create/sign-in existence checks.
  Future<void> resendEmailOtp({
    required String email,
    required bool shouldCreateUser,
  });

  Future<AuthUser> verifyEmailOtp({
    required String email,
    required String token,
  });

  Future<AuthUser> signInWithGoogle();

  Future<AuthUser> updateDisplayName(String displayName);

  /// Sets or clears `user_metadata.avatar_path` for the signed-in user.
  Future<AuthUser> updateAvatarPath(String? avatarPath);

  Future<void> deleteOwnAccount();

  Future<void> signOut();
}
