import 'dart:async';

import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/flags/remote_config_service.dart';
import 'package:sprout/core/flags/remote_feature_flag.dart';
import 'package:sprout/features/accounts/domain/account.dart';
import 'package:sprout/features/accounts/domain/accounts_repository.dart';
import 'package:sprout/features/auth/domain/auth_repository.dart';
import 'package:sprout/features/auth/domain/auth_user.dart';
import 'package:sprout/features/auth/domain/local_session_cleaner.dart';
import 'package:sprout/features/sync/domain/pending_sync_operation.dart';
import 'package:sprout/features/sync/domain/sync_remote_datasource.dart';
import 'package:sprout/features/budget/domain/budget_group.dart';
import 'package:sprout/features/budget/domain/budget_repository.dart';
import 'package:sprout/features/goals/domain/goal.dart';
import 'package:sprout/features/goals/domain/goals_repository.dart';
import 'package:sprout/features/transactions/domain/portfolio_summary.dart';
import 'package:sprout/features/transactions/domain/transaction.dart';
import 'package:sprout/features/transactions/domain/transaction_frequency.dart';
import 'package:sprout/features/transactions/domain/transactions_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? initialUser}) : _currentUser = initialUser;

  AuthUser? _currentUser;
  final _controller = StreamController<AuthUser?>.broadcast();

  int sendOtpCalls = 0;
  int verifyOtpCalls = 0;
  int googleCalls = 0;
  int updateDisplayNameCalls = 0;
  int deleteOwnAccountCalls = 0;
  int signOutCalls = 0;

  String? lastEmail;
  String? lastToken;
  String? lastDisplayName;
  Object? sendOtpError;
  Object? verifyOtpError;
  Object? googleError;
  Object? updateDisplayNameError;
  Object? deleteOwnAccountError;
  Object? signOutError;

  void setUser(AuthUser? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  Future<void> sendEmailOtp(String email) async {
    sendOtpCalls++;
    lastEmail = email;
    final error = sendOtpError;
    if (error != null) throw error;
  }

  @override
  Future<AuthUser> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    verifyOtpCalls++;
    lastEmail = email;
    lastToken = token;
    final error = verifyOtpError;
    if (error != null) throw error;
    final user = AuthUser(id: 'verified-uid', email: email, isAnonymous: false);
    setUser(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    googleCalls++;
    final error = googleError;
    if (error != null) throw error;
    const user = AuthUser(
      id: 'google-uid',
      email: 'user@gmail.com',
      displayName: 'Google User',
      isAnonymous: false,
      signedInWithGoogle: true,
    );
    setUser(user);
    return user;
  }

  @override
  Future<AuthUser> updateDisplayName(String displayName) async {
    updateDisplayNameCalls++;
    lastDisplayName = displayName;
    final error = updateDisplayNameError;
    if (error != null) throw error;
    final current = _currentUser;
    if (current == null) {
      throw StateError('No signed-in user to update.');
    }
    final user = AuthUser(
      id: current.id,
      email: current.email,
      displayName: displayName,
      isAnonymous: current.isAnonymous,
      signedInWithGoogle: current.signedInWithGoogle,
    );
    setUser(user);
    return user;
  }

  @override
  Future<void> deleteOwnAccount() async {
    deleteOwnAccountCalls++;
    final error = deleteOwnAccountError;
    if (error != null) throw error;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    final error = signOutError;
    if (error != null) throw error;
    setUser(null);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class FakeLocalSessionCleaner implements LocalSessionCleaner {
  FakeLocalSessionCleaner({this.onClear});

  final Future<void> Function()? onClear;
  int clearCalls = 0;

  @override
  Future<void> clearLocalEntityData() async {
    clearCalls++;
    await onClear?.call();
  }
}

class FakeSyncRemoteDatasource implements SyncRemoteDatasource {
  FakeSyncRemoteDatasource({
    this.authUserId = 'auth-uid',
    this.syncedTransactionId,
  });

  @override
  String? authUserId;

  final List<PendingSyncOperationType> appliedTypes = [];
  final List<String> appliedPayloads = [];
  Object? applyError;
  String? syncedTransactionId;

  @override
  Future<String?> apply({
    required PendingSyncOperationType type,
    required String payloadJson,
  }) async {
    final error = applyError;
    if (error != null) throw error;
    appliedTypes.add(type);
    appliedPayloads.add(payloadJson);
    if (type == PendingSyncOperationType.insertTransaction) {
      return syncedTransactionId ?? 'tx-1';
    }
    return null;
  }
}

class FakeRemoteConfigService implements RemoteConfigService {
  FakeRemoteConfigService({Map<String, String> strings = const {}})
    : _strings = Map.of(strings);

  final Map<String, String> _strings;

  @override
  bool get isReady => true;

  @override
  Future<void> setup(AppConfig config) async {}

  @override
  Future<bool> fetchFlags() async => true;

  @override
  bool isEnabled(RemoteFeatureFlag flag) => flag.defaultValue;

  @override
  String? getString(String key) {
    final value = _strings[key];
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }
}

class FakeTransactionsRepository implements TransactionsRepository {
  FakeTransactionsRepository({List<Transaction>? initial}) {
    if (initial != null) _transactions.addAll(initial);
  }

  final _controller = StreamController<void>.broadcast();
  final List<Transaction> _transactions = [];

  int addTransactionCalls = 0;
  Transaction? lastAdded;
  Transaction? lastUpdatedRecurring;
  final List<String> markedSyncedIds = [];

  List<Transaction> get items => List.unmodifiable(_transactions);

  void setTransactions(List<Transaction> txs) {
    _transactions
      ..clear()
      ..addAll(txs);
    _notify();
  }

  void _notify() {
    if (!_controller.isClosed) _controller.add(null);
  }

  @override
  Stream<List<Transaction>> watchTransactions() async* {
    yield List.unmodifiable(_transactions);
    await for (final _ in _controller.stream) {
      yield List.unmodifiable(_transactions);
    }
  }

  @override
  Stream<PortfolioSummary> watchPortfolioSummary() async* {
    yield const PortfolioSummary(totalCents: 0, lastActivityAt: null);
    await for (final _ in _controller.stream) {
      yield const PortfolioSummary(totalCents: 0, lastActivityAt: null);
    }
  }

  @override
  Future<List<Transaction>> getForAccount(String accountId) async =>
      _transactions.where((t) => t.accountId == accountId).toList();

  @override
  Future<List<Transaction>> getForGoal(String goalId) async =>
      _transactions.where((t) => t.goalId == goalId).toList();

  @override
  Future<void> addTransaction({
    required String accountId,
    required TransactionKind kind,
    String? goalId,
    String? groupId,
    required int amountCents,
    DateTime? occurredAt,
    String? note,
    bool isRecurring = false,
    TransactionFrequency frequency = TransactionFrequency.none,
  }) async {
    addTransactionCalls++;
    lastAdded = Transaction(
      id: 'tx-$addTransactionCalls',
      userId: 'user',
      accountId: accountId,
      kind: kind,
      goalId: goalId,
      groupId: groupId,
      amountCents: amountCents,
      occurredAt: occurredAt ?? DateTime.now(),
      note: note,
      pendingSync: false,
      isRecurring: isRecurring,
      recurringEnabled: isRecurring,
      frequency: frequency,
    );
    _transactions.add(lastAdded!);
    _notify();
  }

  @override
  Future<void> updateTransactionNote({
    required String transactionId,
    required String? note,
  }) async {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index < 0) return;
    final existing = _transactions[index];
    _transactions[index] = Transaction(
      id: existing.id,
      userId: existing.userId,
      accountId: existing.accountId,
      kind: existing.kind,
      goalId: existing.goalId,
      groupId: existing.groupId,
      amountCents: existing.amountCents,
      occurredAt: existing.occurredAt,
      note: note,
      pendingSync: existing.pendingSync,
      isRecurring: existing.isRecurring,
      recurringEnabled: existing.recurringEnabled,
      frequency: existing.frequency,
      nextScheduledDate: existing.nextScheduledDate,
    );
    _notify();
  }

  @override
  Future<void> updateTransactionRecurringConfig({
    required String transactionId,
    required bool isRecurring,
    required TransactionFrequency frequency,
  }) async {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index < 0) return;
    final existing = _transactions[index];
    final enabled = isRecurring && frequency != TransactionFrequency.none;
    final updated = Transaction(
      id: existing.id,
      userId: existing.userId,
      accountId: existing.accountId,
      kind: existing.kind,
      goalId: existing.goalId,
      groupId: existing.groupId,
      amountCents: existing.amountCents,
      occurredAt: existing.occurredAt,
      note: existing.note,
      pendingSync: existing.pendingSync,
      isRecurring: existing.isRecurring || enabled,
      recurringEnabled: enabled,
      frequency: enabled
          ? frequency
          : (existing.frequency == TransactionFrequency.none
                ? TransactionFrequency.monthly
                : existing.frequency),
      nextScheduledDate: enabled ? existing.nextScheduledDate : null,
    );
    _transactions[index] = updated;
    lastUpdatedRecurring = updated;
    _notify();
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    _transactions.removeWhere((t) => t.id == transactionId);
    _notify();
  }

  @override
  Future<void> markTransactionSynced(String id) async {
    markedSyncedIds.add(id);
  }

  @override
  Future<void> pullRemote() async {}

  @override
  Future<void> clearLocal() async {
    _transactions.clear();
    _notify();
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class FakeGoalsRepository implements GoalsRepository {
  FakeGoalsRepository({List<Goal>? initial}) {
    if (initial != null) _goals.addAll(initial);
  }

  final _controller = StreamController<void>.broadcast();
  final List<Goal> _goals = [];

  Goal? lastUpserted;
  Object? upsertError;
  Object? deleteError;
  Completer<void>? pullRemoteHold;

  void _notify() {
    if (!_controller.isClosed) _controller.add(null);
  }

  @override
  Stream<List<Goal>> watchGoals() async* {
    yield List.unmodifiable(_goals);
    await for (final _ in _controller.stream) {
      yield List.unmodifiable(_goals);
    }
  }

  @override
  Future<List<Goal>> getGoals() async => List.unmodifiable(_goals);

  @override
  Future<void> upsertGoal(Goal goal) async {
    final error = upsertError;
    if (error != null) throw error;
    lastUpserted = goal;
    final idx = _goals.indexWhere((g) => g.id == goal.id);
    if (idx == -1) {
      _goals.add(goal);
    } else {
      _goals[idx] = goal;
    }
    _notify();
  }

  @override
  Future<void> deleteGoal(String id) async {
    final error = deleteError;
    if (error != null) throw error;
    _goals.removeWhere((g) => g.id == id);
    _notify();
  }

  @override
  Future<void> pullRemote() async {
    final hold = pullRemoteHold;
    if (hold != null) await hold.future;
  }

  @override
  Future<void> clearLocal() async {
    _goals.clear();
    _notify();
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class FakeAccountsRepository implements AccountsRepository {
  FakeAccountsRepository({List<Account>? initial}) {
    if (initial != null) _accounts.addAll(initial);
  }

  final _controller = StreamController<void>.broadcast();
  final List<Account> _accounts = [];

  Account? lastUpserted;
  Object? upsertError;
  Object? deleteError;
  Completer<void>? pullRemoteHold;

  void _notify() {
    if (!_controller.isClosed) _controller.add(null);
  }

  @override
  Stream<List<Account>> watchAccounts() async* {
    yield List.unmodifiable(_accounts);
    await for (final _ in _controller.stream) {
      yield List.unmodifiable(_accounts);
    }
  }

  @override
  Future<List<Account>> getAccounts() async => List.unmodifiable(_accounts);

  @override
  Future<void> upsertAccount(Account account) async {
    final error = upsertError;
    if (error != null) throw error;
    lastUpserted = account;
    final idx = _accounts.indexWhere((a) => a.id == account.id);
    if (idx == -1) {
      _accounts.add(account);
    } else {
      _accounts[idx] = account;
    }
    _notify();
  }

  @override
  Future<void> deleteAccount(String id) async {
    final error = deleteError;
    if (error != null) throw error;
    _accounts.removeWhere((a) => a.id == id);
    _notify();
  }

  @override
  Future<void> pullRemote() async {
    final hold = pullRemoteHold;
    if (hold != null) await hold.future;
  }

  @override
  Future<void> clearLocal() async {
    _accounts.clear();
    _notify();
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class FakeBudgetRepository implements BudgetRepository {
  FakeBudgetRepository({List<BudgetGroup>? initial}) {
    if (initial != null) _groups.addAll(initial);
  }

  final _controller = StreamController<void>.broadcast();
  final List<BudgetGroup> _groups = [];

  BudgetGroup? lastUpserted;
  Object? upsertError;

  void _notify() {
    if (!_controller.isClosed) _controller.add(null);
  }

  @override
  Stream<List<BudgetGroup>> watchBudgetGroups() async* {
    yield List.unmodifiable(_groups);
    await for (final _ in _controller.stream) {
      yield List.unmodifiable(_groups);
    }
  }

  @override
  Future<List<BudgetGroup>> getBudgetGroups() async =>
      List.unmodifiable(_groups);

  @override
  Future<void> upsertBudgetGroup(BudgetGroup group) async {
    final error = upsertError;
    if (error != null) throw error;
    lastUpserted = group;
    final idx = _groups.indexWhere((g) => g.id == group.id);
    if (idx == -1) {
      _groups.add(group);
    } else {
      _groups[idx] = group;
    }
    _notify();
  }

  @override
  Future<void> deleteBudgetGroup(String id) async {
    _groups.removeWhere((g) => g.id == id);
    _notify();
  }

  @override
  Future<void> pullRemote() async {}

  @override
  Future<void> clearLocal() async {
    _groups.clear();
    _notify();
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
