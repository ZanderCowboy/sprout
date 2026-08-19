import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/features/auth/domain/auth_user.dart';
import 'package:sprout/features/auth/presentation/utils/account_identity_labels.dart';

void main() {
  test('title prefers display name then email then Account', () {
    expect(
      accountTileTitle(
        const AuthUser(
          id: 'u1',
          displayName: 'Ada',
          email: 'ada@example.com',
          isAnonymous: false,
        ),
      ),
      'Ada',
    );
    expect(
      accountTileTitle(
        const AuthUser(id: 'u1', email: 'ada@example.com', isAnonymous: false),
      ),
      'ada@example.com',
    );
    expect(
      accountTileTitle(const AuthUser(id: 'u1', isAnonymous: false)),
      AppStrings.account,
    );
  });

  test('subtitle is email when a name is shown', () {
    expect(
      accountTileSubtitle(
        const AuthUser(
          id: 'u1',
          displayName: 'Ada',
          email: 'ada@example.com',
          isAnonymous: false,
        ),
      ),
      'ada@example.com',
    );
  });

  test('subtitle falls back to signed-in provider copy', () {
    expect(
      accountTileSubtitle(
        const AuthUser(id: 'u1', email: 'ada@example.com', isAnonymous: false),
      ),
      AppStrings.signedInWithEmail,
    );
    expect(
      accountTileSubtitle(
        const AuthUser(
          id: 'u1',
          email: 'ada@example.com',
          isAnonymous: false,
          signedInWithGoogle: true,
        ),
      ),
      AppStrings.signedInWithGoogle,
    );
  });

  test('avatar initial uses the first letter of the title', () {
    expect(
      accountAvatarInitial(
        const AuthUser(
          id: 'u1',
          displayName: 'ada',
          email: 'z@example.com',
          isAnonymous: false,
        ),
      ),
      'A',
    );
    expect(
      accountAvatarInitial(
        const AuthUser(id: 'u1', email: 'ada@example.com', isAnonymous: false),
      ),
      'A',
    );
  });
}
