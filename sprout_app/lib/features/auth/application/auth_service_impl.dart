import 'package:sprout/core/analytics/analytics_catalog.dart';
import 'package:sprout/core/analytics/analytics_service.dart';
import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/config/app_environment.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/error/error.dart';
import 'package:sprout/core/user/user_context.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import '../domain/local_session_cleaner.dart';
import 'auth_service.dart';

class AuthServiceImpl implements AuthService {
  AuthServiceImpl({
    required AuthRepository authRepository,
    required UserContext userContext,
    required AppConfig appConfig,
    required LocalSessionCleaner localSessionCleaner,
    required AnalyticsService analyticsService,
    required Future<void> Function() flushPending,
    required Future<void> Function() pullRemote,
    Future<void> Function(String appUserId)? logInPurchases,
    Future<void> Function()? logOutPurchases,
  }) : _authRepository = authRepository,
       _userContext = userContext,
       _appConfig = appConfig,
       _localSessionCleaner = localSessionCleaner,
       _analyticsService = analyticsService,
       _flushPending = flushPending,
       _pullRemote = pullRemote,
       _logInPurchases = logInPurchases,
       _logOutPurchases = logOutPurchases;

  final AuthRepository _authRepository;
  final UserContext _userContext;
  final AppConfig _appConfig;
  final LocalSessionCleaner _localSessionCleaner;
  final AnalyticsService _analyticsService;
  final Future<void> Function() _flushPending;
  final Future<void> Function() _pullRemote;
  final Future<void> Function(String appUserId)? _logInPurchases;
  final Future<void> Function()? _logOutPurchases;
  bool _debugSignedIn = false;

  @override
  AuthUser? get currentUser => _authRepository.currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => _authRepository.authStateChanges();

  @override
  bool get debugSignInAvailable =>
      _appConfig.environment == AppEnvironment.development;

  @override
  bool get isDebugSignedIn => _debugSignedIn;

  @override
  Future<void> debugSignIn() async {
    if (!debugSignInAvailable) {
      throw const AuthAppException(AppStrings.debugSignInDevOnly);
    }

    _debugSignedIn = true;
    await _userContext.setActiveUserId(AuthService.maestroTestUserId);
    await _userContext.markIntroCompleted();
    // Do not mark verified — keep sync disabled for local-only test data.

    // Sync RevenueCat identity for promo grants in E2E flows.
    final logInPurchases = _logInPurchases;
    if (logInPurchases != null) {
      try {
        await logInPurchases(AuthService.maestroTestUserId);
      } on Object {
        // Best-effort identity sync; debug sign-in continues either way.
      }
    }
  }

  @override
  bool get canSync {
    final user = _authRepository.currentUser;
    return user != null && user.isVerified;
  }

  @override
  Future<void> sendRegisterOtp(String email) =>
      _authRepository.sendRegisterOtp(email);

  @override
  Future<void> sendSignInOtp(String email) =>
      _authRepository.sendSignInOtp(email);

  @override
  Future<void> resendEmailOtp({
    required String email,
    required bool shouldCreateUser,
  }) => _authRepository.resendEmailOtp(
    email: email,
    shouldCreateUser: shouldCreateUser,
  );

  @override
  Future<AuthUser> verifyEmailOtp({
    required String email,
    required String token,
    String? displayName,
    bool isSignUp = false,
  }) async {
    var user = await _authRepository.verifyEmailOtp(email: email, token: token);
    final trimmedName = displayName?.trim() ?? '';
    if (trimmedName.isNotEmpty) {
      user = await _authRepository.updateDisplayName(trimmedName);
    }
    await bindAfterVerifiedSignIn(user);
    
    // Log analytics event determined by caller
    final eventName = isSignUp
        ? AnalyticsEvent.signUpSuccess
        : AnalyticsEvent.signInSuccess;
    await _analyticsService.logEvent(
      eventName,
      {AnalyticsParam.method: AnalyticsSignInMethod.emailOtp},
    );
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final previousUserId = _userContext.lastVerifiedUserId;
    final user = await _authRepository.signInWithGoogle();
    await bindAfterVerifiedSignIn(user);
    
    // Sign-up if this is a different user than previously verified
    final isSignUp = previousUserId == null || previousUserId != user.id;
    final eventName = isSignUp
        ? AnalyticsEvent.signUpSuccess
        : AnalyticsEvent.signInSuccess;
    await _analyticsService.logEvent(
      eventName,
      {AnalyticsParam.method: AnalyticsSignInMethod.google},
    );
    return user;
  }

  @override
  Future<AuthUser> updateDisplayName(String displayName) =>
      _authRepository.updateDisplayName(displayName);

  @override
  Future<void> signOut() async {
    _debugSignedIn = false;
    await _authRepository.signOut();
    await _analyticsService.logEvent(AnalyticsEvent.signOut);

    // Best-effort RevenueCat logout to restore anonymous identity.
    final logOutPurchases = _logOutPurchases;
    if (logOutPurchases != null) {
      try {
        await logOutPurchases();
      } on Object {
        // Continue sign-out even if RevenueCat logout fails.
      }
    }
  }

  @override
  Future<void> deleteAccount() async {
    _debugSignedIn = false;
    await _authRepository.deleteOwnAccount();
    await _localSessionCleaner.clearLocalEntityData();
    final logOutPurchases = _logOutPurchases;
    if (logOutPurchases != null) {
      try {
        await logOutPurchases();
      } on Object {
        // Best-effort RevenueCat logout; the auth user is already gone.
      }
    }
    await _authRepository.signOut();
  }

  @override
  Future<void> bindAfterVerifiedSignIn(AuthUser user) async {
    if (!user.isVerified) {
      throw const AuthAppException(AppStrings.verifiedSessionRequired);
    }

    final newUid = user.id;
    final previousUid = _userContext.cachedUserId;

    if (previousUid == newUid) {
      await _userContext.setActiveUserId(newUid);
      await _userContext.markVerifiedUserId(newUid);
      await _flushPending();
      await _pullRemote();

      // Sync RevenueCat identity for same-user re-login.
      final logInPurchases = _logInPurchases;
      if (logInPurchases != null) {
        try {
          await logInPurchases(newUid);
        } on Object {
          // Best-effort identity sync; continue bind.
        }
      }
      return;
    }

    await _localSessionCleaner.clearLocalEntityData();
    await _userContext.setActiveUserId(newUid);
    await _userContext.markVerifiedUserId(newUid);
    await _pullRemote();

    // Sync RevenueCat identity for new-user bind.
    final logInPurchases = _logInPurchases;
    if (logInPurchases != null) {
      try {
        await logInPurchases(newUid);
      } on Object {
        // Best-effort identity sync; continue bind.
      }
    }
  }
}
