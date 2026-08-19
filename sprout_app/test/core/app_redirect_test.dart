import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/router/app_redirect.dart';
import 'package:sprout/core/router/app_route.dart';
import 'package:sprout/features/auth/domain/auth_user.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';

void main() {
  const guest = AuthViewGuest(
    supabaseConfigured: true,
    googleAvailable: false,
  );
  const signedIn = AuthViewSignedIn(
    user: AuthUser(id: 'u1', isAnonymous: false, email: 'a@b.c'),
  );
  const loading = AuthViewLoading();

  group('resolveAuthRedirect', () {
    test('loading stays on loading and sends other paths there', () {
      expect(
        resolveAuthRedirect(
          auth: loading,
          introCompleted: false,
          location: AppRoute.loading.path,
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          auth: loading,
          introCompleted: true,
          location: AppRoute.overview.path,
        ),
        AppRoute.loading.path,
      );
    });

    test('unsigned without intro is forced to intro', () {
      expect(
        resolveAuthRedirect(
          auth: guest,
          introCompleted: false,
          location: AppRoute.intro.path,
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          auth: guest,
          introCompleted: false,
          location: AppRoute.signIn.path,
        ),
        AppRoute.intro.path,
      );
      expect(
        resolveAuthRedirect(
          auth: guest,
          introCompleted: false,
          location: AppRoute.overview.path,
        ),
        AppRoute.intro.path,
      );
    });

    test('unsigned with intro cannot open overview', () {
      final redirect = resolveAuthRedirect(
        auth: guest,
        introCompleted: true,
        location: AppRoute.overview.path,
        uri: Uri.parse(AppRoute.overview.path),
      );
      expect(redirect, '${AppRoute.signIn.path}?from=%2Foverview');
    });

    test('unsigned with intro can stay on sign-in, intro, terms, and privacy', () {
      expect(
        resolveAuthRedirect(
          auth: guest,
          introCompleted: true,
          location: AppRoute.signIn.path,
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          auth: guest,
          introCompleted: true,
          location: AppRoute.intro.path,
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          auth: guest,
          introCompleted: true,
          location: AppRoute.terms.path,
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          auth: guest,
          introCompleted: true,
          location: AppRoute.privacy.path,
        ),
        isNull,
      );
    });

    test('unsigned with intro leaves loading for sign-in', () {
      expect(
        resolveAuthRedirect(
          auth: guest,
          introCompleted: true,
          location: AppRoute.loading.path,
        ),
        AppRoute.signIn.path,
      );
    });

    test('signed-in skips intro and sign-in', () {
      expect(
        resolveAuthRedirect(
          auth: signedIn,
          introCompleted: true,
          location: AppRoute.intro.path,
        ),
        AppRoute.overview.path,
      );
      expect(
        resolveAuthRedirect(
          auth: signedIn,
          introCompleted: true,
          location: AppRoute.signIn.path,
        ),
        AppRoute.overview.path,
      );
      expect(
        resolveAuthRedirect(
          auth: signedIn,
          introCompleted: true,
          location: AppRoute.overview.path,
        ),
        isNull,
      );
    });

    test('signed-in restores a safe from query', () {
      expect(
        resolveAuthRedirect(
          auth: signedIn,
          introCompleted: true,
          location: AppRoute.signIn.path,
          uri: Uri(
            path: AppRoute.signIn.path,
            queryParameters: {'from': AppRoute.accountDetail.location(id: 'abc')},
          ),
        ),
        '/accounts/abc',
      );
    });

    test('signed-in ignores unsafe from query', () {
      expect(
        resolveAuthRedirect(
          auth: signedIn,
          introCompleted: true,
          location: AppRoute.signIn.path,
          uri: Uri.parse('${AppRoute.signIn.path}?from=https://evil.example'),
        ),
        AppRoute.overview.path,
      );
    });
  });
}
