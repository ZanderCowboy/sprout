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
      throw const AuthAppException(
        'Supabase is not configured. Sign-in is unavailable.',
      );
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
  Future<void> sendEmailOtp(String email) async {
    final normalized = email.trim();
    if (normalized.isEmpty) {
      throw const ValidationAppException('Enter an email address.');
    }
    try {
      await _client.auth.signInWithOtp(
        email: normalized,
        shouldCreateUser: true,
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
  Future<AuthUser> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final normalizedEmail = email.trim();
    final normalizedToken = token.trim();
    if (normalizedEmail.isEmpty) {
      throw const ValidationAppException('Enter an email address.');
    }
    if (normalizedToken.isEmpty) {
      throw const ValidationAppException('Enter the verification code.');
    }
    try {
      final response = await _client.auth.verifyOTP(
        type: OtpType.email,
        email: normalizedEmail,
        token: normalizedToken,
      );
      final user = _mapUser(response.user ?? _client.auth.currentUser);
      if (user == null || !user.isVerified) {
        throw const AuthAppException('Could not verify the code.');
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
  Future<AuthUser> signInWithGoogle() async {
    final google = _googleSignIn;
    if (google == null) {
      throw const AuthAppException(
        'Google Sign-In is not configured. Add googleWebClientId to the flavor config.',
      );
    }
    try {
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthAppException(
          'Google Sign-In did not return an ID token.',
        );
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
        throw const AuthAppException('Google Sign-In failed.');
      }
      return user;
    } on AuthAppException {
      rethrow;
    } on AuthException catch (e) {
      throw AuthAppException(e.message);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthAppException('Google Sign-In was cancelled.');
      }
      throw AuthAppException(e.description ?? e.toString());
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
        throw const AuthAppException('Could not update display name.');
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
      await _client.rpc('delete_own_account');
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
