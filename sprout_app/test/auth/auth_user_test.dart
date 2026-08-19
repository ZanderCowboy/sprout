import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/features/auth/domain/auth_user.dart';

void main() {
  group('displayNameFromMetadata', () {
    test('prefers display_name over full_name and name', () {
      expect(
        displayNameFromMetadata({
          'display_name': 'Ada',
          'full_name': 'Ada Lovelace',
          'name': 'A.L.',
        }),
        'Ada',
      );
    });

    test('falls back to full_name then name', () {
      expect(
        displayNameFromMetadata({'full_name': 'Ada Lovelace', 'name': 'A.L.'}),
        'Ada Lovelace',
      );
      expect(displayNameFromMetadata({'name': 'Ada'}), 'Ada');
    });

    test('ignores blank strings and missing metadata', () {
      expect(displayNameFromMetadata({'display_name': '  '}), isNull);
      expect(displayNameFromMetadata({'display_name': 1}), isNull);
      expect(displayNameFromMetadata(const {}), isNull);
      expect(displayNameFromMetadata(null), isNull);
    });

    test('trims whitespace', () {
      expect(displayNameFromMetadata({'display_name': '  Ada  '}), 'Ada');
    });
  });

  group('signedInWithGoogleFromAuth', () {
    test('is true when google is an identity provider', () {
      expect(
        signedInWithGoogleFromAuth(
          identityProviders: const ['email', 'google'],
        ),
        isTrue,
      );
    });

    test('is true when app_metadata provider is google', () {
      expect(
        signedInWithGoogleFromAuth(appMetadata: const {'provider': 'google'}),
        isTrue,
      );
    });

    test('is true when app_metadata providers list includes google', () {
      expect(
        signedInWithGoogleFromAuth(
          appMetadata: const {
            'providers': ['email', 'google'],
          },
        ),
        isTrue,
      );
    });

    test('is false for email-only metadata', () {
      expect(
        signedInWithGoogleFromAuth(
          identityProviders: const ['email'],
          appMetadata: const {
            'provider': 'email',
            'providers': ['email'],
          },
        ),
        isFalse,
      );
      expect(signedInWithGoogleFromAuth(), isFalse);
    });
  });
}
