import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/config/app_environment.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/router/app_route.dart';
import 'package:sprout/core/theme/app_theme.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/auth/application/auth_service_impl.dart';
import 'package:sprout/features/auth/domain/auth_user.dart';
import 'package:sprout/features/auth/presentation/account_page.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';

import '../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<dynamic> settingsBox;
  late FakeAuthRepository fakeAuth;
  late AuthCubit cubit;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('sprout_account_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    settingsBox = await Hive.openBox<dynamic>('settings_$stamp');
    fakeAuth = FakeAuthRepository(
      initialUser: const AuthUser(
        id: 'u1',
        isAnonymous: false,
        email: 'ada@example.com',
        displayName: 'Ada',
      ),
    );
    const config = AppConfig(
      environment: AppEnvironment.development,
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'sb_publishable_test_key_1234567890',
      googleWebClientId: 'web-client.apps.googleusercontent.com',
      androidApplicationId: 'app.stackmint.sprout.dev',
      revenueCatAndroidApiKey: '',
      firebaseApiKey: '',
      firebaseAppId: '',
      firebaseMessagingSenderId: '',
      firebaseProjectId: '',
      firebaseStorageBucket: '',
    );
    cubit = AuthCubit(
      authService: AuthServiceImpl(
        authRepository: fakeAuth,
        userContext: UserContext(settingsBox),
        appConfig: config,
        localSessionCleaner: FakeLocalSessionCleaner(),
        flushPending: () async {},
        pullRemote: () async {},
      ),
      appConfig: config,
    );
  });

  tearDown(() async {
    await cubit.close();
    await fakeAuth.dispose();
    await settingsBox.deleteFromDisk();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('shows edit profile and change-email coming soon', (tester) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp.router(
          theme: buildAppTheme(),
          routerConfig: GoRouter(
            initialLocation: AppRoute.account.path,
            routes: [
              GoRoute(
                path: AppRoute.account.path,
                builder: (context, _) => const AccountPage(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.accountSectionProfile), findsWidgets);
    expect(find.text(AppStrings.editDisplayName), findsOneWidget);
    expect(find.text(AppStrings.changeEmail), findsOneWidget);
    expect(find.text('ada@example.com'), findsWidgets);
    expect(find.text(AppStrings.changeEmailComingSoon), findsOneWidget);
    expect(find.text(AppStrings.deleteAccount), findsOneWidget);
  });
}
