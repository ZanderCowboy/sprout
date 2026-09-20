import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/error/error.dart';
import 'package:sprout/features/auth/data/auth_repository_impl.dart';
import 'package:sprout/features/auth/domain/auth_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../mocks/fake_google_sign_in.dart';
import '../mocks/fake_supabase_client.dart';

void main() {
  group('AuthRepositoryImpl Google Sign-In', () {
    late FakeSupabaseClient supabase;
    late FakeGoogleSignIn googleSignIn;
    late AuthRepositoryImpl repository;

    setUp(() {
      supabase = FakeSupabaseClient();
      googleSignIn = FakeGoogleSignIn();
      repository = AuthRepositoryImpl(
        supabase: supabase,
        googleSignIn: googleSignIn,
      );
    });

    test('successful sign-in returns AuthUser', () async {
      googleSignIn.mockUser = FakeGoogleSignInAccount(
        id: 'google-id',
        email: 'user@gmail.com',
        displayName: 'Google User',
        idToken: 'mock-id-token',
      );
      supabase.mockAuthUser = User(
        id: 'sb-user-id',
        appMetadata: const {},
        userMetadata: const {'display_name': 'Google User'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      final user = await repository.signInWithGoogle();

      expect(user.id, 'sb-user-id');
      expect(user.displayName, 'Google User');
      expect(user.signedInWithGoogle, isTrue);
    });

    test('user cancellation shows cancelled message', () async {
      googleSignIn.mockException = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: 'User dismissed the account picker',
      );

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(
          isA<AuthAppException>().having(
            (e) => e.message,
            'message',
            AppStrings.googleSignInCancelled,
          ),
        ),
      );
    });

    test('[16] Account reauth failed shows error description', () async {
      googleSignIn.mockException = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: '[16] Account reauth failed.',
      );

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(
          isA<AuthAppException>().having(
            (e) => e.message,
            'message',
            '[16] Account reauth failed.',
          ),
        ),
      );
    });

    test('OAuth configuration error shows error description', () async {
      googleSignIn.mockException = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: 'Invalid client ID configuration',
      );

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(
          isA<AuthAppException>().having(
            (e) => e.message,
            'message',
            'Invalid client ID configuration',
          ),
        ),
      );
    });

    test('SHA-1 mismatch error shows error description', () async {
      googleSignIn.mockException = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: 'SHA-1 fingerprint mismatch',
      );

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(
          isA<AuthAppException>().having(
            (e) => e.message,
            'message',
            'SHA-1 fingerprint mismatch',
          ),
        ),
      );
    });

    test('clientConfigurationError shows error description', () async {
      googleSignIn.mockException = GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: 'Client misconfigured',
      );

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(
          isA<AuthAppException>().having(
            (e) => e.message,
            'message',
            'Client misconfigured',
          ),
        ),
      );
    });

    test('providerConfigurationError shows error description', () async {
      googleSignIn.mockException = GoogleSignInException(
        code: GoogleSignInExceptionCode.providerConfigurationError,
        description: 'Provider SDK unavailable',
      );

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(
          isA<AuthAppException>().having(
            (e) => e.message,
            'message',
            'Provider SDK unavailable',
          ),
        ),
      );
    });

    test('unknownError with description shows description', () async {
      googleSignIn.mockException = GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'Something unexpected happened',
      );

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(
          isA<AuthAppException>().having(
            (e) => e.message,
            'message',
            'Something unexpected happened',
          ),
        ),
      );
    });

    test('interrupted exception shows error description', () async {
      googleSignIn.mockException = GoogleSignInException(
        code: GoogleSignInExceptionCode.interrupted,
        description: 'Sign-in was interrupted',
      );

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(
          isA<AuthAppException>().having(
            (e) => e.message,
            'message',
            'Sign-in was interrupted',
          ),
        ),
      );
    });
  });
}
