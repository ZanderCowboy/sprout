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
import 'package:sprout/features/auth/application/auth_service_impl.dart';
import 'package:sprout/features/auth/application/privacy_policy_service.dart';
import 'package:sprout/features/auth/application/privacy_policy_service_impl.dart';
import 'package:sprout/features/auth/domain/auth_user.dart';
import 'package:sprout/features/auth/presentation/account_page.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:sprout/features/auth/presentation/privacy_page.dart';
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
    tempDir = Directory.systemTemp.createTempSync('sprout_account_');
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

  testWidgets('Privacy row opens PrivacyPage', (tester) async {
    sl.registerSingleton<PrivacyPolicyService>(
      PrivacyPolicyServiceImpl(
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
            initialLocation: AppRoute.account.path,
            routes: [
              GoRoute(
                path: AppRoute.account.path,
                builder: (context, _) => const AccountPage(),
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
    await tester.pumpAndSettle();

    final privacy = find.text(AppStrings.privacyPolicy);
    await tester.ensureVisible(privacy);
    await tester.pumpAndSettle();
    await tester.tap(privacy);
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
