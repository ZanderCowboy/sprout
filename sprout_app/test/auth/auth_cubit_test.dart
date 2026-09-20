import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/config/app_environment.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/error/error.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/auth/application/auth_service.dart';
import 'package:sprout/features/auth/application/auth_service_impl.dart';
import 'package:sprout/features/auth/domain/auth_user.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';

import '../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
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
  });

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    settingsBox = await Hive.openBox<dynamic>('settings_$stamp');
    fakeAuth = FakeAuthRepository();
    final config = appConfig();
    cubit = AuthCubit(
      authService: AuthServiceImpl(
        authRepository: fakeAuth,
        userContext: UserContext(settingsBox),
        appConfig: config,
        localSessionCleaner: FakeLocalSessionCleaner(),
        analyticsService: FakeAnalyticsService(),
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
    expect(cubit.state, isA<AuthViewSignedOut>());
    final signedOut = cubit.state as AuthViewSignedOut;
    expect(signedOut.supabaseConfigured, isTrue);
    expect(signedOut.googleAvailable, isTrue);
    expect(signedOut.otpSent, isFalse);
  });

  test('sendOtp then verifyOtp transitions to signed in', () async {
    cubit.emailChanged('user@example.com');
    await cubit.sendOtp();

    expect(cubit.state, isA<AuthViewSignedOut>());
    final afterSend = cubit.state as AuthViewSignedOut;
    expect(afterSend.otpSent, isTrue);
    expect(fakeAuth.sendSignInOtpCalls, 1);

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

  test('Google sign-in surfaces AuthFailure message', () async {
    fakeAuth.googleError = const AuthAppException('Network error');
    await cubit.signInWithGoogle();

    final signedOut = cubit.state as AuthViewSignedOut;
    expect(signedOut.errorMessage, 'Network error');
    expect(signedOut.busy, isFalse);
  });

  test('sendOtp surfaces AuthFailure message', () async {
    fakeAuth.sendSignInOtpError = const AuthAppException('Rate limited');
    cubit.emailChanged('user@example.com');
    await cubit.sendOtp();

    final signedOut = cubit.state as AuthViewSignedOut;
    expect(signedOut.errorMessage, 'Rate limited');
    expect(signedOut.busy, isFalse);
  });

  test('sendRegisterOtp does not repeat check-email copy as info', () async {
    cubit.emailChanged('user@example.com');
    await cubit.sendRegisterOtp();

    final signedOut = cubit.state as AuthViewSignedOut;
    expect(signedOut.otpSent, isTrue);
    expect(signedOut.isRegisterPath, isTrue);
    expect(signedOut.infoMessage, isNull);
    expect(fakeAuth.sendRegisterOtpCalls, 1);
  });

  test('register resend is not blocked by the pending signup row', () async {
    fakeAuth.sendRegisterOtpErrorAfterFirst = const AuthAppException(
      AppStrings.emailAlreadyHasAccount,
    );
    cubit.emailChanged('user@example.com');
    await cubit.sendRegisterOtp();

    await cubit.sendOtp();

    final signedOut = cubit.state as AuthViewSignedOut;
    expect(signedOut.errorMessage, isNull);
    expect(signedOut.otpSent, isTrue);
    expect(fakeAuth.sendRegisterOtpCalls, 1);
    expect(fakeAuth.resendEmailOtpCalls, 1);
    expect(fakeAuth.lastResendShouldCreateUser, isTrue);
  });

  test(
    'sendRegisterOtp keeps user on create account when email exists',
    () async {
      fakeAuth.sendRegisterOtpError = const AuthAppException(
        AppStrings.emailAlreadyHasAccount,
      );
      cubit.emailChanged('user@example.com');
      await cubit.sendRegisterOtp();

      final signedOut = cubit.state as AuthViewSignedOut;
      expect(signedOut.otpSent, isFalse);
      expect(signedOut.errorMessage, AppStrings.emailAlreadyHasAccount);
      expect(signedOut.busy, isFalse);
    },
  );

  test('switchToSignInPath clears register flags and error', () async {
    fakeAuth.sendRegisterOtpError = const AuthAppException(
      AppStrings.emailAlreadyHasAccount,
    );
    cubit.emailChanged('user@example.com');
    await cubit.sendRegisterOtp();
    cubit.switchToSignInPath();

    final signedOut = cubit.state as AuthViewSignedOut;
    expect(signedOut.isRegisterPath, isFalse);
    expect(signedOut.otpSent, isFalse);
    expect(signedOut.errorMessage, isNull);
    expect(signedOut.email, 'user@example.com');
  });

  test(
    'sendSignInOtp keeps user on sign in when email has no account',
    () async {
      fakeAuth.sendSignInOtpError = const AuthAppException(
        AppStrings.emailHasNoAccount,
      );
      cubit.emailChanged('user@example.com');
      await cubit.sendSignInOtp();

      final signedOut = cubit.state as AuthViewSignedOut;
      expect(signedOut.otpSent, isFalse);
      expect(signedOut.errorMessage, AppStrings.emailHasNoAccount);
      expect(signedOut.busy, isFalse);
    },
  );

  test('switchToRegisterPath clears sign-in flags and error', () async {
    fakeAuth.sendSignInOtpError = const AuthAppException(
      AppStrings.emailHasNoAccount,
    );
    cubit.emailChanged('user@example.com');
    await cubit.sendSignInOtp();
    cubit.switchToRegisterPath();

    final signedOut = cubit.state as AuthViewSignedOut;
    expect(signedOut.isRegisterPath, isTrue);
    expect(signedOut.otpSent, isFalse);
    expect(signedOut.errorMessage, isNull);
    expect(signedOut.email, 'user@example.com');
  });

  test('auth stream preserves register path after OTP send', () async {
    cubit.emailChanged('user@example.com');
    await cubit.sendRegisterOtp();
    fakeAuth.setUser(null);
    await Future<void>.delayed(Duration.zero);

    final signedOut = cubit.state as AuthViewSignedOut;
    expect(signedOut.isRegisterPath, isTrue);
    expect(signedOut.otpSent, isTrue);
    expect(signedOut.email, 'user@example.com');
  });

  test('signOut returns to guest', () async {
    fakeAuth.setUser(
      const AuthUser(id: 'u1', email: 'a@b.com', isAnonymous: false),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<AuthViewSignedIn>());

    await cubit.signOut();
    expect(cubit.state, isA<AuthViewSignedOut>());
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
    expect(cubit.state, isA<AuthViewSignedOut>());
    expect(fakeAuth.deleteOwnAccountCalls, 1);
    expect(fakeAuth.signOutCalls, 1);
  });
}
