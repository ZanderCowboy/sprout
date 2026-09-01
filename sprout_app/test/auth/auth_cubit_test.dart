import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/config/app_environment.dart';
import 'package:sprout/core/error/error.dart';
import 'package:sprout/core/storage/hive_adapters.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/auth/application/auth_service.dart';
import 'package:sprout/features/auth/application/auth_service_impl.dart';
import 'package:sprout/features/auth/domain/auth_user.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';
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

  AppConfig appConfig({
    bool supabase = true,
    String googleWebClientId = 'web-client.apps.googleusercontent.com',
  }) {
    return AppConfig(
      environment: AppEnvironment.development,
      supabaseUrl: supabase ? 'https://example.supabase.co' : '',
      supabaseAnonKey: supabase ? 'sb_publishable_test_key_1234567890' : '',
      googleWebClientId: googleWebClientId,
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
    tempDir = Directory.systemTemp.createTempSync('sprout_auth_cubit_');
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
    final config = appConfig();
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

  test('debug sign-in stays signed in when Supabase has no session', () async {
    expect(cubit.debugSignInAvailable, isTrue);
    await cubit.debugSignIn();

    expect(cubit.state, isA<AuthViewSignedIn>());
    expect(
      (cubit.state as AuthViewSignedIn).user.id,
      AuthService.maestroTestUserId,
    );
    expect((cubit.state as AuthViewSignedIn).user.email, 'maestro@test.local');

    fakeAuth.setUser(null);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<AuthViewSignedIn>());
    expect(
      (cubit.state as AuthViewSignedIn).user.id,
      AuthService.maestroTestUserId,
    );
  });

  test('starts as guest when signed out', () {
    expect(cubit.state, isA<AuthViewGuest>());
    final guest = cubit.state as AuthViewGuest;
    expect(guest.supabaseConfigured, isTrue);
    expect(guest.googleAvailable, isTrue);
    expect(guest.otpSent, isFalse);
  });

  test('sendOtp then verifyOtp transitions to signed in', () async {
    cubit.emailChanged('user@example.com');
    await cubit.sendOtp();

    expect(cubit.state, isA<AuthViewGuest>());
    final afterSend = cubit.state as AuthViewGuest;
    expect(afterSend.otpSent, isTrue);
    expect(fakeAuth.sendOtpCalls, 1);

    await cubit.verifyOtp('123456');
    expect(cubit.state, isA<AuthViewSignedIn>());
    final signedIn = cubit.state as AuthViewSignedIn;
    expect(signedIn.user.email, 'user@example.com');
    expect(fakeAuth.verifyOtpCalls, 1);
    expect(fakeAuth.updateDisplayNameCalls, 0);
  });

  test('verifyOtp with display name updates metadata', () async {
    cubit.emailChanged('user@example.com');
    cubit.displayNameChanged('Ada');
    await cubit.sendOtp();
    await cubit.verifyOtp('123456');

    expect(cubit.state, isA<AuthViewSignedIn>());
    final signedIn = cubit.state as AuthViewSignedIn;
    expect(signedIn.user.displayName, 'Ada');
    expect(fakeAuth.updateDisplayNameCalls, 1);
    expect(fakeAuth.lastDisplayName, 'Ada');
  });

  test('verifyOtp skips display name when empty', () async {
    cubit.emailChanged('user@example.com');
    cubit.displayNameChanged('   ');
    await cubit.sendOtp();
    await cubit.verifyOtp('123456');

    expect(fakeAuth.updateDisplayNameCalls, 0);
    expect((cubit.state as AuthViewSignedIn).user.displayName, isNull);
  });

  test(
    'Google sign-in uses profile name and does not require a name field',
    () async {
      await cubit.signInWithGoogle();

      expect(cubit.state, isA<AuthViewSignedIn>());
      final signedIn = cubit.state as AuthViewSignedIn;
      expect(signedIn.user.displayName, 'Google User');
      expect(fakeAuth.updateDisplayNameCalls, 0);
      expect(fakeAuth.googleCalls, 1);
    },
  );

  test('sendOtp surfaces AuthFailure message', () async {
    fakeAuth.sendOtpError = const AuthAppException('Rate limited');
    cubit.emailChanged('user@example.com');
    await cubit.sendOtp();

    final guest = cubit.state as AuthViewGuest;
    expect(guest.errorMessage, 'Rate limited');
    expect(guest.busy, isFalse);
  });

  test('signOut returns to guest', () async {
    fakeAuth.setUser(
      const AuthUser(id: 'u1', email: 'a@b.com', isAnonymous: false),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<AuthViewSignedIn>());

    await cubit.signOut();
    expect(cubit.state, isA<AuthViewGuest>());
  });

  test('updateDisplayName saves metadata', () async {
    fakeAuth.setUser(
      const AuthUser(id: 'u1', email: 'a@b.com', isAnonymous: false),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<AuthViewSignedIn>());

    await cubit.updateDisplayName('Ada');
    expect(cubit.state, isA<AuthViewSignedIn>());
    final signedIn = cubit.state as AuthViewSignedIn;
    expect(signedIn.user.displayName, 'Ada');
    expect(fakeAuth.updateDisplayNameCalls, 1);
    expect(fakeAuth.lastDisplayName, 'Ada');
  });

  test('deleteAccount clears session after RPC', () async {
    fakeAuth.setUser(
      const AuthUser(id: 'u1', email: 'a@b.com', isAnonymous: false),
    );
    await Future<void>.delayed(Duration.zero);

    await cubit.deleteAccount();
    expect(cubit.state, isA<AuthViewGuest>());
    expect(fakeAuth.deleteOwnAccountCalls, 1);
    expect(fakeAuth.signOutCalls, 1);
  });
}
