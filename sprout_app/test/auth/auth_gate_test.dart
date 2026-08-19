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
import 'package:sprout/features/auth/presentation/auth_gate.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:sprout/features/auth/presentation/intro_page.dart';
import 'package:sprout/features/auth/presentation/sign_in_page.dart';
import 'package:sprout/features/budget/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/sync/export.dart';
import 'package:sprout/features/transactions/export.dart';

import '../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IntroPage', () {
    testWidgets('last CTA completes intro', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: IntroPage(onCompleted: () => completed = true),
        ),
      );

      expect(find.text('Track your savings in one place'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Set goals and watch them grow'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Sign in so your data stays with you'), findsOneWidget);

      await tester.tap(find.text('Sign in'));
      await tester.pump();
      expect(completed, isTrue);
    });
  });

  group('AuthGate', () {
    late Directory tempDir;
    late Box<AccountHiveModel> accountsBox;
    late Box<GoalHiveModel> goalsBox;
    late Box<BudgetGroupHiveModel> budgetGroupsBox;
    late Box<TransactionHiveModel> transactionsBox;
    late Box<PendingSyncHiveModel> pendingBox;
    late Box<dynamic> settingsBox;
    late FakeAuthRepository fakeAuth;
    late UserContext userContext;
    late AuthCubit cubit;

    AppConfig appConfig() {
      return const AppConfig(
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
    }

    setUpAll(() {
      tempDir = Directory.systemTemp.createTempSync('sprout_auth_gate_');
      Hive.init(tempDir.path);
      registerHiveAdapters();
    });

    setUp(() async {
      final stamp = DateTime.now().microsecondsSinceEpoch;
      accountsBox = await Hive.openBox<AccountHiveModel>('accounts_$stamp');
      goalsBox = await Hive.openBox<GoalHiveModel>('goals_$stamp');
      budgetGroupsBox = await Hive.openBox<BudgetGroupHiveModel>(
        'budget_$stamp',
      );
      transactionsBox = await Hive.openBox<TransactionHiveModel>('tx_$stamp');
      pendingBox = await Hive.openBox<PendingSyncHiveModel>('pending_$stamp');
      settingsBox = await Hive.openBox<dynamic>('settings_$stamp');
      fakeAuth = FakeAuthRepository();
      userContext = UserContext(settingsBox);
      cubit = AuthCubit(
        authService: AuthService(
          authRepository: fakeAuth,
          userContext: userContext,
          accountsBox: accountsBox,
          goalsBox: goalsBox,
          budgetGroupsBox: budgetGroupsBox,
          transactionsBox: transactionsBox,
          pendingSyncQueue: PendingSyncQueue(pendingBox),
          flushPending: () async {},
          pullRemote: () async {},
        ),
        appConfig: appConfig(),
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

    Future<void> pumpGate(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: BlocProvider.value(
            value: cubit,
            child: AuthGate(
              userContext: userContext,
              signedIn: const SizedBox(key: Key('shell')),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('intro is shown until completed', (tester) async {
      await pumpGate(tester);

      expect(find.byType(IntroPage), findsOneWidget);
      expect(find.byType(SignInPage), findsNothing);
      expect(find.byKey(const Key('shell')), findsNothing);
      expect(find.text('Track your savings in one place'), findsOneWidget);
      expect(userContext.introCompleted, isFalse);
    });

    test('intro_completed persists on UserContext', () async {
      expect(userContext.introCompleted, isFalse);
      final pending = userContext.markIntroCompleted();
      expect(userContext.introCompleted, isTrue);
      await pending;
      expect(userContext.introCompleted, isTrue);
    });
  });
}
