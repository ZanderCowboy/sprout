import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/config/app_environment.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/error/error.dart';
import 'package:sprout/core/user/user_context.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import 'auth_service.dart';

class AuthServiceImpl implements AuthService {
  AuthServiceImpl({
    required AuthRepository authRepository,
    required UserContext userContext,
    required AppConfig appConfig,
    required Future<void> Function() clearLocalData,
    required Future<void> Function() flushPending,
    required Future<void> Function() pullRemote,
    Future<void> Function()? logOutPurchases,
  }) : _authRepository = authRepository,
       _userContext = userContext,
       _appConfig = appConfig,
       _clearLocalData = clearLocalData,
       _flushPending = flushPending,
       _pullRemote = pullRemote,
       _logOutPurchases = logOutPurchases;

  final AuthRepository _authRepository;
  final UserContext _userContext;
  final AppConfig _appConfig;
  final Future<void> Function() _clearLocalData;
  final Future<void> Function() _flushPending;
  final Future<void> Function() _pullRemote;
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
  }

  @override
  bool get canSync {
    final user = _authRepository.currentUser;
    return user != null && user.isVerified;
  }

  @override
  Future<void> sendEmailOtp(String email) =>
      _authRepository.sendEmailOtp(email);

  @override
  Future<AuthUser> verifyEmailOtp({
    required String email,
    required String token,
    String? displayName,
  }) async {
    var user = await _authRepository.verifyEmailOtp(email: email, token: token);
    final trimmedName = displayName?.trim() ?? '';
    if (trimmedName.isNotEmpty) {
      user = await _authRepository.updateDisplayName(trimmedName);
    }
    await bindAfterVerifiedSignIn(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final user = await _authRepository.signInWithGoogle();
    await bindAfterVerifiedSignIn(user);
    return user;
  }

  @override
  Future<AuthUser> updateDisplayName(String displayName) =>
      _authRepository.updateDisplayName(displayName);

  @override
  Future<void> signOut() async {
    _debugSignedIn = false;
    await _authRepository.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    _debugSignedIn = false;
    await _authRepository.deleteOwnAccount();
    await _clearLocalEntityData();
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
      return;
    }

    await _clearLocalEntityData();
    await _userContext.setActiveUserId(newUid);
    await _userContext.markVerifiedUserId(newUid);
    await _pullRemote();
  }

  Future<void> _clearLocalEntityData() => _clearLocalData();
}
