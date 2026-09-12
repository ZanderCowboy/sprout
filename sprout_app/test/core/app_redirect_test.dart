import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sprout/core/router/app_redirect.dart';
import 'package:sprout/core/router/app_route.dart';
import 'package:sprout/core/user/user_context.dart';
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

  late Directory tempDir;
  late Box<dynamic> settingsBox;
  late UserContext userContext;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('sprout_app_redirect_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    settingsBox = await Hive.openBox<dynamic>('settings_$stamp');
    userContext = UserContext(settingsBox);
  });

  tearDown(() async {
    await settingsBox.deleteFromDisk();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<String?> redirect({
    required AuthViewState auth,
    required bool introCompleted,
    required String location,
    Uri? uri,
  }) {
    return resolveAuthRedirect(
      auth: auth,
      introCompleted: introCompleted,
      userContext: userContext,
      location: location,
      uri: uri,
    );
  }

  group('resolveAuthRedirect', () {
    test('loading stays on loading and sends other paths there', () async {
      expect(
        await redirect(
          auth: loading,
          introCompleted: false,
          location: AppRoute.loading.path,
        ),
        isNull,
      );
      expect(
        await redirect(
          auth: loading,
          introCompleted: true,
          location: AppRoute.overview.path,
        ),
        AppRoute.loading.path,
      );
    });

    test('unsigned without intro is forced to intro', () async {
      expect(
        await redirect(
          auth: guest,
          introCompleted: false,
          location: AppRoute.intro.path,
        ),
        isNull,
      );
      expect(
        await redirect(
          auth: guest,
          introCompleted: false,
          location: AppRoute.signIn.path,
        ),
        AppRoute.intro.path,
      );
      expect(
        await redirect(
          auth: guest,
          introCompleted: false,
          location: AppRoute.overview.path,
        ),
        AppRoute.intro.path,
      );
    });

    test('unsigned with intro cannot open overview', () async {
      final result = await redirect(
        auth: guest,
        introCompleted: true,
        location: AppRoute.overview.path,
        uri: Uri.parse(AppRoute.overview.path),
      );
      expect(result, '${AppRoute.signIn.path}?from=%2Foverview');
    });

    test('unsigned with intro can stay on sign-in, intro, terms, and privacy',
        () async {
      expect(
        await redirect(
          auth: guest,
          introCompleted: true,
          location: AppRoute.signIn.path,
        ),
        isNull,
      );
      expect(
        await redirect(
          auth: guest,
          introCompleted: true,
          location: AppRoute.intro.path,
        ),
        isNull,
      );
      expect(
        await redirect(
          auth: guest,
          introCompleted: true,
          location: AppRoute.terms.path,
        ),
        isNull,
      );
      expect(
        await redirect(
          auth: guest,
          introCompleted: true,
          location: AppRoute.privacy.path,
        ),
        isNull,
      );
    });

    test('unsigned with intro leaves loading for sign-in', () async {
      expect(
        await redirect(
          auth: guest,
          introCompleted: true,
          location: AppRoute.loading.path,
        ),
        AppRoute.signIn.path,
      );
    });

    test('signed-in skips intro and sign-in', () async {
      expect(
        await redirect(
          auth: signedIn,
          introCompleted: true,
          location: AppRoute.intro.path,
        ),
        AppRoute.overview.path,
      );
      expect(
        await redirect(
          auth: signedIn,
          introCompleted: true,
          location: AppRoute.signIn.path,
        ),
        AppRoute.overview.path,
      );
      expect(
        await redirect(
          auth: signedIn,
          introCompleted: true,
          location: AppRoute.overview.path,
        ),
        isNull,
      );
    });

    test('signed-in restores a safe from query', () async {
      expect(
        await redirect(
          auth: signedIn,
          introCompleted: true,
          location: AppRoute.signIn.path,
          uri: Uri(
            path: AppRoute.signIn.path,
            queryParameters: {
              'from': AppRoute.accountDetail.location(id: 'abc'),
            },
          ),
        ),
        '/accounts/abc',
      );
    });

    test('signed-in ignores unsafe from query', () async {
      expect(
        await redirect(
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
