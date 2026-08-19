import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/config/app_environment.dart';
import 'package:sprout/core/storage/hive_adapters.dart';
import 'package:sprout/core/theme/app_theme.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/auth/application/auth_service.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:sprout/features/auth/presentation/sign_in_page.dart';
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
    cubit = AuthCubit(
      authService: AuthService(
        authRepository: fakeAuth,
        userContext: UserContext(settingsBox),
        accountsBox: accountsBox,
        goalsBox: goalsBox,
        budgetGroupsBox: budgetGroupsBox,
        transactionsBox: transactionsBox,
        pendingSyncQueue: PendingSyncQueue(pendingBox),
        flushPending: () async {},
        pullRemote: () async {},
      ),
      appConfig: const AppConfig(
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
      ),
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

    expect(find.text('Send code'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
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
}
