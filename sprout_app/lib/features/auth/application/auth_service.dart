import 'package:hive_flutter/hive_flutter.dart';

import 'package:sprout/core/error/error.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/budget/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/sync/export.dart';
import 'package:sprout/features/transactions/export.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class AuthService {
  AuthService({
    required AuthRepository authRepository,
    required UserContext userContext,
    required Box<AccountHiveModel> accountsBox,
    required Box<GoalHiveModel> goalsBox,
    required Box<BudgetGroupHiveModel> budgetGroupsBox,
    required Box<TransactionHiveModel> transactionsBox,
    required PendingSyncQueue pendingSyncQueue,
    required Future<void> Function() flushPending,
    required Future<void> Function() pullRemote,
  }) : _authRepository = authRepository,
       _userContext = userContext,
       _accountsBox = accountsBox,
       _goalsBox = goalsBox,
       _budgetGroupsBox = budgetGroupsBox,
       _transactionsBox = transactionsBox,
       _pendingSyncQueue = pendingSyncQueue,
       _flushPending = flushPending,
       _pullRemote = pullRemote;

  final AuthRepository _authRepository;
  final UserContext _userContext;
  final Box<AccountHiveModel> _accountsBox;
  final Box<GoalHiveModel> _goalsBox;
  final Box<BudgetGroupHiveModel> _budgetGroupsBox;
  final Box<TransactionHiveModel> _transactionsBox;
  final PendingSyncQueue _pendingSyncQueue;
  final Future<void> Function() _flushPending;
  final Future<void> Function() _pullRemote;

  AuthUser? get currentUser => _authRepository.currentUser;

  Stream<AuthUser?> authStateChanges() => _authRepository.authStateChanges();

  /// Sync is allowed only with a verified (non-anonymous) Supabase session.
  bool get canSync {
    final user = _authRepository.currentUser;
    return user != null && user.isVerified;
  }

  Future<void> sendEmailOtp(String email) =>
      _authRepository.sendEmailOtp(email);

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

  Future<AuthUser> signInWithGoogle() async {
    final user = await _authRepository.signInWithGoogle();
    await bindAfterVerifiedSignIn(user);
    return user;
  }

  /// Clears the Supabase session and keeps local Hive data / active_user_id.
  Future<void> signOut() => _authRepository.signOut();

  /// Same-uid re-login keeps the cache and flushes pending, then pulls.
  /// Any other bind discards leftover local Hive and pulls cloud only.
  Future<void> bindAfterVerifiedSignIn(AuthUser user) async {
    if (!user.isVerified) {
      throw const AuthAppException('Verified session required.');
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

  Future<void> _clearLocalEntityData() async {
    await _accountsBox.clear();
    await _goalsBox.clear();
    await _budgetGroupsBox.clear();
    await _transactionsBox.clear();
    await _pendingSyncQueue.clear();
  }
}
