import 'dart:async';

import 'package:sprout/core/flags/remote_config_service.dart';
import 'package:sprout/features/accounts/domain/account.dart';
import 'package:sprout/features/accounts/domain/accounts_repository.dart';
import 'package:sprout/features/auth/domain/auth_repository.dart';
import 'package:sprout/features/auth/domain/auth_user.dart';
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

class FakeRemoteConfigService extends RemoteConfigService {
  FakeRemoteConfigService({Map<String, String> strings = const {}})
    : _strings = Map.of(strings);

  final Map<String, String> _strings;

  @override
  bool get isReady => true;

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
  }) async {}

  @override
  Future<void> updateTransactionRecurringConfig({
    required String transactionId,
    required bool isRecurring,
    required TransactionFrequency frequency,
  }) async {}

  @override
  Future<void> deleteTransaction(String transactionId) async {
    _transactions.removeWhere((t) => t.id == transactionId);
    _notify();
  }

  @override
  Future<void> markTransactionSynced(String id) async {}

  @override
  Future<void> pullRemote() async {}

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
    _goals.removeWhere((g) => g.id == id);
    _notify();
  }

  @override
  Future<void> pullRemote() async {}

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
    _accounts.removeWhere((a) => a.id == id);
    _notify();
  }

  @override
  Future<void> pullRemote() async {}

  Future<void> dispose() async {
    await _controller.close();
  }
}
