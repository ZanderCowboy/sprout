import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/features/auth/data/auth_repository_impl.dart';

void main() {
  group('AuthRepositoryImpl.mapGoogleSignInException', () {
    test('user cancellation shows cancelled message', () {
      final exception = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: 'User dismissed the account picker',
      );

      final message = AuthRepositoryImpl.mapGoogleSignInException(exception);

      expect(message, AppStrings.googleSignInCancelled);
    });

    test('[16] Account reauth failed shows error description', () {
      final exception = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: '[16] Account reauth failed.',
      );

      final message = AuthRepositoryImpl.mapGoogleSignInException(exception);

      expect(message, '[16] Account reauth failed.');
    });

    test('OAuth configuration error shows error description', () {
      final exception = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: 'Invalid client ID configuration',
      );

      final message = AuthRepositoryImpl.mapGoogleSignInException(exception);

      expect(message, 'Invalid client ID configuration');
    });

    test('SHA-1 mismatch error shows error description', () {
      final exception = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: 'SHA-1 fingerprint mismatch',
      );

      final message = AuthRepositoryImpl.mapGoogleSignInException(exception);

      expect(message, 'SHA-1 fingerprint mismatch');
    });

    test('reauth failed keyword triggers config error path', () {
      final exception = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: 'Account reauth failed due to network',
      );

      final message = AuthRepositoryImpl.mapGoogleSignInException(exception);

      expect(message, 'Account reauth failed due to network');
    });

    test('clientConfigurationError shows error description', () {
      final exception = GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: 'Client misconfigured',
      );

      final message = AuthRepositoryImpl.mapGoogleSignInException(exception);

      expect(message, 'Client misconfigured');
    });

    test('providerConfigurationError shows error description', () {
      final exception = GoogleSignInException(
        code: GoogleSignInExceptionCode.providerConfigurationError,
        description: 'Provider SDK unavailable',
      );

      final message = AuthRepositoryImpl.mapGoogleSignInException(exception);

      expect(message, 'Provider SDK unavailable');
    });

    test('unknownError with description shows description', () {
      final exception = GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'Something unexpected happened',
      );

      final message = AuthRepositoryImpl.mapGoogleSignInException(exception);

      expect(message, 'Something unexpected happened');
    });

    test('interrupted exception shows error description', () {
      final exception = GoogleSignInException(
        code: GoogleSignInExceptionCode.interrupted,
        description: 'Sign-in was interrupted',
      );

      final message = AuthRepositoryImpl.mapGoogleSignInException(exception);

      expect(message, 'Sign-in was interrupted');
    });

    test('canceled without description falls back to cancelled message', () {
      final exception = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      );

      final message = AuthRepositoryImpl.mapGoogleSignInException(exception);

      expect(message, AppStrings.googleSignInCancelled);
    });

    test('unknownError without description falls back to generic', () {
      final exception = GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
      );

      final message = AuthRepositoryImpl.mapGoogleSignInException(exception);

      expect(message, AppStrings.googleSignInFailed);
    });
  });
}
