import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/config/app_environment.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/core/router/app_route.dart';
import 'package:sprout/core/storage/hive_adapters.dart';
import 'package:sprout/core/theme/app_theme.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/auth/application/auth_service.dart';
import 'package:sprout/features/auth/application/privacy_policy_service.dart';
import 'package:sprout/features/auth/application/terms_of_service_service.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:sprout/features/auth/presentation/privacy_page.dart';
import 'package:sprout/features/auth/presentation/sign_in_page.dart';
import 'package:sprout/features/auth/presentation/terms_page.dart';
import 'package:sprout/features/budget/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/sync/export.dart';
import 'package:sprout/features/transactions/export.dart';

import '../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<AccountHiveModel> accountsBox;
  late Box<GoalHiveModel> goalsBox;
  late Box<BudgetGroupHiveModel> budgetGroupsBox;
  late Box<TransactionHiveModel> transactionsBox;
  late Box<PendingSyncHiveModel> pendingBox;
  late Box<dynamic> settingsBox;
  late FakeAuthRepository fakeAuth;
  late AuthCubit cubit;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('sprout_sign_in_');
    Hive.init(tempDir.path);
    registerHiveAdapters();
  });

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    accountsBox = await Hive.openBox<AccountHiveModel>('accounts_$stamp');
    goalsBox = await Hive.openBox<GoalHiveModel>('goals_$stamp');
    budgetGroupsBox = await Hive.openBox<BudgetGroupHiveModel>('budget_$stamp');
    transactionsBox = await Hive.openBox<TransactionHiveModel>('tx_$stamp');
    pendingBox = await Hive.openBox<PendingSyncHiveModel>('pending_$stamp');
    settingsBox = await Hive.openBox<dynamic>('settings_$stamp');
    fakeAuth = FakeAuthRepository();
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
      authService: AuthService(
        authRepository: fakeAuth,
        userContext: UserContext(settingsBox),
        appConfig: config,
        accountsBox: accountsBox,
        goalsBox: goalsBox,
        budgetGroupsBox: budgetGroupsBox,
        transactionsBox: transactionsBox,
        pendingSyncQueue: PendingSyncQueue(pendingBox),
        flushPending: () async {},
        pullRemote: () async {},
      ),
      appConfig: config,
    );
  });

  tearDown(() async {
    await cubit.close();
    await fakeAuth.dispose();
    await accountsBox.deleteFromDisk();
    await goalsBox.deleteFromDisk();
    await budgetGroupsBox.deleteFromDisk();
    await transactionsBox.deleteFromDisk();
    await pendingBox.deleteFromDisk();
    await settingsBox.deleteFromDisk();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('sign-in form is shown when unsigned', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: BlocProvider.value(value: cubit, child: const SignInPage()),
      ),
    );

    expect(find.text(AppStrings.sendCode), findsOneWidget);
    expect(find.text(AppStrings.continueWithGoogle), findsOneWidget);
    expect(find.text(AppStrings.termsOfService), findsOneWidget);
    expect(find.text(AppStrings.privacyPolicy), findsOneWidget);
    expect(find.text(AppStrings.displayNameOptional), findsOneWidget);
    expect(
      find.text(AppStrings.displayNameExistingAccountHint),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
  });

  testWidgets('back button calls onBackToIntro', (tester) async {
    var back = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: BlocProvider.value(
          value: cubit,
          child: SignInPage(onBackToIntro: () => back = true),
        ),
      ),
    );

    await tester.tap(find.byType(BackButton));
    expect(back, isTrue);
  });

  testWidgets('verification code appears after sending email OTP', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: BlocProvider.value(value: cubit, child: const SignInPage()),
      ),
    );

    expect(find.text(AppStrings.displayNameOptional), findsOneWidget);
    expect(find.text(AppStrings.verificationCode), findsNothing);

    await tester.enterText(find.byType(TextField).at(1), 'user@example.com');
    await tester.tap(find.text(AppStrings.sendCode));
    await tester.pump();

    expect(find.text(AppStrings.displayNameOptional), findsOneWidget);
    expect(find.text(AppStrings.verificationCode), findsOneWidget);
  });

  testWidgets('Terms hyperlink opens TermsPage', (tester) async {
    sl.registerSingleton<TermsOfServiceService>(
      TermsOfServiceService(
        remoteConfig: FakeRemoteConfigService(),
        assetBundle: _FakeAssetBundle({
          TermsOfServiceService.bundledAssetPath:
              '# Bundled Terms\n\nLocal placeholder.',
        }),
      ),
    );
    addTearDown(() async {
      await sl.reset(dispose: false);
    });

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp.router(
          theme: buildAppTheme(),
          routerConfig: GoRouter(
            initialLocation: AppRoute.signIn.path,
            routes: [
              GoRoute(
                path: AppRoute.signIn.path,
                builder: (context, _) => const SignInPage(),
              ),
              GoRoute(
                path: AppRoute.terms.path,
                builder: (context, _) => const TermsPage(),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.termsOfService));
    await tester.pumpAndSettle();

    expect(find.byType(TermsPage), findsOneWidget);
    expect(find.textContaining('Local placeholder.'), findsOneWidget);
  });

  testWidgets('Privacy hyperlink opens PrivacyPage', (tester) async {
    sl.registerSingleton<PrivacyPolicyService>(
      PrivacyPolicyService(
        remoteConfig: FakeRemoteConfigService(),
        assetBundle: _FakeAssetBundle({
          PrivacyPolicyService.bundledAssetPath:
              '# Bundled Privacy\n\nLocal privacy placeholder.',
        }),
      ),
    );
    addTearDown(() async {
      await sl.reset(dispose: false);
    });

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp.router(
          theme: buildAppTheme(),
          routerConfig: GoRouter(
            initialLocation: AppRoute.signIn.path,
            routes: [
              GoRoute(
                path: AppRoute.signIn.path,
                builder: (context, _) => const SignInPage(),
              ),
              GoRoute(
                path: AppRoute.privacy.path,
                builder: (context, _) => const PrivacyPage(),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.privacyPolicy));
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyPage), findsOneWidget);
    expect(find.textContaining('Local privacy placeholder.'), findsOneWidget);
  });
}

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._strings);

  final Map<String, String> _strings;

  @override
  Future<ByteData> load(String key) async {
    final value = _strings[key];
    if (value == null) {
      throw FlutterError('Unable to load asset: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}
