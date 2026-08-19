import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sprout/core/storage/hive_adapters.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/auth/application/auth_service.dart';
import 'package:sprout/features/auth/domain/auth_user.dart';
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
  late UserContext userContext;
  late AuthService authService;
  var flushCalls = 0;
  var pullCalls = 0;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('sprout_auth_service_');
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
    userContext = UserContext(settingsBox);
    flushCalls = 0;
    pullCalls = 0;
    authService = AuthService(
      authRepository: fakeAuth,
      userContext: userContext,
      accountsBox: accountsBox,
      goalsBox: goalsBox,
      budgetGroupsBox: budgetGroupsBox,
      transactionsBox: transactionsBox,
      pendingSyncQueue: PendingSyncQueue(pendingBox),
      flushPending: () async {
        flushCalls++;
      },
      pullRemote: () async {
        pullCalls++;
      },
    );
  });

  tearDown(() async {
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

  test('first sign-in clears leftover local then pull', () async {
    final localUid = await userContext.resolveUserId();
    final now = DateTime.now().millisecondsSinceEpoch;
    await accountsBox.put(
      'a1',
      AccountHiveModel(
        id: 'a1',
        userId: localUid,
        name: 'Cash',
        color: 1,
        createdAtMillis: now,
        updatedAtMillis: now,
      ),
    );
    await PendingSyncQueue(
      pendingBox,
    ).enqueue(PendingSyncOperationType.upsertAccount, '{}');

    final user = await authService.verifyEmailOtp(
      email: 'guest@example.com',
      token: '123456',
    );

    expect(user.id, 'verified-uid');
    expect(accountsBox.isEmpty, isTrue);
    expect(pendingBox.isEmpty, isTrue);
    expect(userContext.cachedUserId, 'verified-uid');
    expect(userContext.lastVerifiedUserId, 'verified-uid');
    expect(flushCalls, 0);
    expect(pullCalls, 1);
  });

  test('same uid re-login only flush+pull', () async {
    await userContext.setActiveUserId('verified-uid');
    await userContext.markVerifiedUserId('verified-uid');
    final now = DateTime.now().millisecondsSinceEpoch;
    await accountsBox.put(
      'a1',
      AccountHiveModel(
        id: 'a1',
        userId: 'verified-uid',
        name: 'Cash',
        color: 1,
        createdAtMillis: now,
        updatedAtMillis: now,
      ),
    );

    await authService.verifyEmailOtp(
      email: 'same@example.com',
      token: '123456',
    );

    expect(accountsBox.length, 1);
    expect(accountsBox.get('a1')!.userId, 'verified-uid');
    expect(flushCalls, 1);
    expect(pullCalls, 1);
  });

  test('verified A to B clears local data then pull', () async {
    await userContext.setActiveUserId('user-a');
    await userContext.markVerifiedUserId('user-a');
    final now = DateTime.now().millisecondsSinceEpoch;
    await accountsBox.put(
      'a1',
      AccountHiveModel(
        id: 'a1',
        userId: 'user-a',
        name: 'Old',
        color: 1,
        createdAtMillis: now,
        updatedAtMillis: now,
      ),
    );
    await PendingSyncQueue(
      pendingBox,
    ).enqueue(PendingSyncOperationType.upsertAccount, '{}');

    fakeAuth.verifyOtpError = null;
    // Override default verify uid via setting user manually through custom flow.
    // Fake returns verified-uid; mark A as previous verified.
    await authService.bindAfterVerifiedSignIn(
      const AuthUser(id: 'user-b', email: 'b@example.com', isAnonymous: false),
    );

    expect(accountsBox.isEmpty, isTrue);
    expect(pendingBox.isEmpty, isTrue);
    expect(userContext.cachedUserId, 'user-b');
    expect(userContext.lastVerifiedUserId, 'user-b');
    expect(flushCalls, 0);
    expect(pullCalls, 1);
  });

  test('signOut clears session but keeps Hive rows', () async {
    await userContext.setActiveUserId('verified-uid');
    await userContext.markVerifiedUserId('verified-uid');
    fakeAuth.setUser(
      const AuthUser(id: 'verified-uid', email: 'a@b.com', isAnonymous: false),
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    await accountsBox.put(
      'a1',
      AccountHiveModel(
        id: 'a1',
        userId: 'verified-uid',
        name: 'Cash',
        color: 1,
        createdAtMillis: now,
        updatedAtMillis: now,
      ),
    );

    await authService.signOut();

    expect(fakeAuth.currentUser, isNull);
    expect(accountsBox.get('a1')!.userId, 'verified-uid');
    expect(userContext.cachedUserId, 'verified-uid');
  });
}
