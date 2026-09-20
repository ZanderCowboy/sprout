import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/error/error.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({SupabaseClient? supabase, GoogleSignIn? googleSignIn})
    : _supabase = supabase,
      _googleSignIn = googleSignIn;

  final SupabaseClient? _supabase;
  final GoogleSignIn? _googleSignIn;

  SupabaseClient get _client {
    final client = _supabase;
    if (client == null) {
      throw const AuthAppException(AppStrings.supabaseNotConfigured);
    }
    return client;
  }

  @override
  AuthUser? get currentUser => _mapUser(_supabase?.auth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() {
    final client = _supabase;
    if (client == null) {
      return Stream<AuthUser?>.value(null);
    }
    return client.auth.onAuthStateChange.map(
      (event) => _mapUser(event.session?.user ?? client.auth.currentUser),
    );
  }

  @override
  Future<void> sendRegisterOtp(String email) async {
    final normalized = email.trim();
    if (normalized.isEmpty) {
      throw const ValidationAppException(AppStrings.enterEmailAddress);
    }
    try {
      if (await _emailHasAccount(normalized)) {
        throw const AuthAppException(AppStrings.emailAlreadyHasAccount);
      }
      await _client.auth.signInWithOtp(
        email: normalized,
        shouldCreateUser: true,
      );
    } on AuthException catch (e) {
      throw AuthAppException(e.message);
    } on AuthAppException {
      rethrow;
    } on ValidationAppException {
      rethrow;
    } on Object catch (e) {
      throw AuthAppException(e.toString());
    }
  }

  @override
  Future<void> sendSignInOtp(String email) async {
    final normalized = email.trim();
    if (normalized.isEmpty) {
      throw const ValidationAppException(AppStrings.enterEmailAddress);
    }
    try {
      if (!await _emailHasAccount(normalized)) {
        throw const AuthAppException(AppStrings.emailHasNoAccount);
      }
      await _client.auth.signInWithOtp(
        email: normalized,
        shouldCreateUser: false,
      );
    } on AuthException catch (e) {
      throw AuthAppException(e.message);
    } on AuthAppException {
      rethrow;
    } on Object catch (e) {
      throw AuthAppException(e.toString());
    }
  }

  @override
  Future<void> resendEmailOtp({
    required String email,
    required bool shouldCreateUser,
  }) async {
    final normalized = email.trim();
    if (normalized.isEmpty) {
      throw const ValidationAppException(AppStrings.enterEmailAddress);
    }
    try {
      await _client.auth.signInWithOtp(
        email: normalized,
        shouldCreateUser: shouldCreateUser,
      );
    } on AuthException catch (e) {
      throw AuthAppException(e.message);
    } on ValidationAppException {
      rethrow;
    } on Object catch (e) {
      throw AuthAppException(e.toString());
    }
  }

  @override
  Future<AuthUser> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final normalizedEmail = email.trim();
    final normalizedToken = token.trim();
    if (normalizedEmail.isEmpty) {
      throw const ValidationAppException(AppStrings.enterEmailAddress);
    }
    if (normalizedToken.isEmpty) {
      throw const ValidationAppException(AppStrings.enterVerificationCode);
    }
    try {
      // Existing users get Magic link (type email). First-time users with
      // Confirm email enabled get Confirm signup (type signup).
      final response = await _verifyEmailOrSignupOtp(
        email: normalizedEmail,
        token: normalizedToken,
      );
      final user = _mapUser(response.user ?? _client.auth.currentUser);
      if (user == null || !user.isVerified) {
        throw const AuthAppException(AppStrings.couldNotVerifyCode);
      }
      return user;
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('token') ||
          e.message.toLowerCase().contains('expired') ||
          e.message.toLowerCase().contains('invalid')) {
        throw const AuthAppException(
          AppStrings.verificationCodeIncorrectOrExpired,
        );
      }
      throw AuthAppException(e.message);
    } on AuthAppException {
      rethrow;
    } on ValidationAppException {
      rethrow;
    } on Object catch (e) {
      throw AuthAppException(e.toString());
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final google = _googleSignIn;
    if (google == null) {
      throw const AuthAppException(AppStrings.googleSignInNotConfigured);
    }
    try {
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthAppException(AppStrings.googleSignInNoIdToken);
      }

      String? accessToken;
      try {
        final authorization = await account.authorizationClient
            .authorizationForScopes(const ['email', 'profile']);
        accessToken = authorization?.accessToken;
      } on Object {
        // Access token is optional unless the ID token includes at_hash.
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      final user = _mapUser(response.user ?? _client.auth.currentUser);
      if (user == null || !user.isVerified) {
        throw const AuthAppException(AppStrings.googleSignInFailed);
      }
      return user;
    } on AuthAppException {
      rethrow;
    } on AuthException catch (e) {
      throw AuthAppException(e.message);
    } on GoogleSignInException catch (e) {
      throw AuthAppException(_mapGoogleSignInException(e));
    } on Object catch (e) {
      throw AuthAppException(e.toString());
    }
  }

  @override
  Future<AuthUser> updateDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw const ValidationAppException(AppStrings.nameRequired);
    }
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(data: {'display_name': trimmed, 'full_name': trimmed}),
      );
      final user = _mapUser(response.user ?? _client.auth.currentUser);
      if (user == null || !user.isVerified) {
        throw const AuthAppException(AppStrings.couldNotUpdateDisplayName);
      }
      return user;
    } on AuthException catch (e) {
      throw AuthAppException(e.message);
    } on AuthAppException {
      rethrow;
    } on ValidationAppException {
      rethrow;
    } on Object catch (e) {
      throw AuthAppException(e.toString());
    }
  }

  @override
  Future<void> deleteOwnAccount() async {
    try {
      await _client.rpc<void>('delete_own_account');
    } on AuthException catch (e) {
      throw AuthAppException(e.message);
    } on PostgrestException {
      throw const AuthAppException(AppStrings.deleteAccountFailed);
    } on AuthAppException {
      rethrow;
    } on Object {
      throw const AuthAppException(AppStrings.deleteAccountFailed);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn?.signOut();
    } on Object {
      // Best-effort Google sign-out; still clear Supabase session.
    }
    final client = _supabase;
    if (client == null) return;
    try {
      await client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthAppException(e.message);
    } on Object catch (e) {
      throw AuthAppException(e.toString());
    }
  }

  /// True when [email] belongs to a verified Supabase user.
  /// Unverified signup rows must not count — the first register OTP creates
  /// one, and treating that as an account blocks resend / retry.
  Future<bool> _emailHasAccount(String email) async {
    try {
      final result = await _client.rpc<dynamic>(
        'email_has_account',
        params: {'p_email': email},
      );
      return result == true;
    } on PostgrestException catch (e) {
      throw AuthAppException(e.message);
    }
  }

  Future<AuthResponse> _verifyEmailOrSignupOtp({
    required String email,
    required String token,
  }) async {
    try {
      return await _client.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: token,
      );
    } on AuthException {
      return _client.auth.verifyOTP(
        type: OtpType.signup,
        email: email,
        token: token,
      );
    }
  }

  @visibleForTesting
  static String mapGoogleSignInException(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        // The canceled code is overloaded: it can mean user cancellation OR
        // configuration errors (OAuth client / SHA-1 mismatch / etc.).
        // Check the description to differentiate.
        final description = e.description ?? '';
        final lower = description.toLowerCase();

        // First check: if description looks like user cancellation, treat as such
        final isUserCancel =
            lower.contains('cancelled by user') ||
            lower.contains('canceled by user') ||
            lower.contains('cancelled by') ||
            lower.contains('canceled by');
        if (isUserCancel) {
          return AppStrings.googleSignInCancelled;
        }

        // Second check: clear configuration/auth error signals
        final isConfigError =
            lower.contains('reauth failed') ||
            lower.contains('configuration') ||
            lower.contains('sha') ||
            lower.contains('client id');
        if (isConfigError) {
          return e.description ?? AppStrings.googleSignInFailed;
        }

        // Default: treat as user cancellation
        return AppStrings.googleSignInCancelled;
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return e.description ?? AppStrings.googleSignInFailed;
      case GoogleSignInExceptionCode.interrupted:
      case GoogleSignInExceptionCode.uiUnavailable:
      case GoogleSignInExceptionCode.userMismatch:
      case GoogleSignInExceptionCode.unknownError:
        return e.description ?? AppStrings.googleSignInFailed;
    }
  }

  String _mapGoogleSignInException(GoogleSignInException e) =>
      mapGoogleSignInException(e);

  AuthUser? _mapUser(User? user) {
    if (user == null || user.id.isEmpty) return null;
    return AuthUser(
      id: user.id,
      email: user.email,
      displayName: displayNameFromMetadata(user.userMetadata),
      isAnonymous: user.isAnonymous,
      signedInWithGoogle: signedInWithGoogleFromAuth(
        identityProviders:
            user.identities?.map((identity) => identity.provider) ?? const [],
        appMetadata: user.appMetadata,
      ),
    );
  }
}
