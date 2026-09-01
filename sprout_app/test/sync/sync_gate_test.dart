import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/config/app_environment.dart';
import 'package:sprout/core/storage/hive_adapters.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/auth/application/auth_service_impl.dart';
import 'package:sprout/features/sync/application/sync_service_impl.dart';
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

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('sprout_sync_gate_');
    Hive.init(tempDir.path);
    registerHiveAdapters();
  });

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    accountsBox = await Hive.openBox<AccountHiveModel>('accounts_$stamp');
    goalsBox = await Hive.openBox<GoalHiveModel>('goals_$stamp');
    budgetGroupsBox =
        await Hive.openBox<BudgetGroupHiveModel>('budget_$stamp');
    transactionsBox =
        await Hive.openBox<TransactionHiveModel>('tx_$stamp');
    pendingBox = await Hive.openBox<PendingSyncHiveModel>('pending_$stamp');
    settingsBox = await Hive.openBox<dynamic>('settings_$stamp');
  });

  tearDown(() async {
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

  AppConfig config({required bool supabase}) {
    return AppConfig(
      environment: AppEnvironment.development,
      supabaseUrl: supabase ? 'https://example.supabase.co' : '',
      supabaseAnonKey: supabase ? 'sb_publishable_test_key_1234567890' : '',
      googleWebClientId: '',
      androidApplicationId: 'app.stackmint.sprout.dev',
      revenueCatAndroidApiKey: '',
      firebaseApiKey: '',
      firebaseAppId: '',
      firebaseMessagingSenderId: '',
      firebaseProjectId: '',
      firebaseStorageBucket: '',
    );
  }

  test('AuthService.canSync is false for guests and anonymous users', () {
    final fake = FakeAuthRepository();
    final service = AuthServiceImpl(
      authRepository: fake,
      userContext: UserContext(settingsBox),
      appConfig: config(supabase: true),
      accountsBox: accountsBox,
      goalsBox: goalsBox,
      budgetGroupsBox: budgetGroupsBox,
      transactionsBox: transactionsBox,
      pendingSyncQueue: PendingSyncQueue(pendingBox),
      flushPending: () async {},
      pullRemote: () async {},
    );

    expect(service.canSync, isFalse);

    fake.setUser(
      const AuthUser(id: 'anon', email: null, isAnonymous: true),
    );
    expect(service.canSync, isFalse);

    fake.setUser(
      const AuthUser(id: 'user-1', email: 'a@b.com', isAnonymous: false),
    );
    expect(service.canSync, isTrue);
  });

  test('guest cannot enqueue pending sync operations', () async {
    final queue = PendingSyncQueue(pendingBox);
    var canSync = false;
    final userContext = UserContext(settingsBox);
    await userContext.resolveUserId();

    final repo = AccountsRepositoryImpl(
      box: accountsBox,
      userContext: userContext,
      appConfig: config(supabase: true),
      canSync: () => canSync,
      pendingSyncQueue: queue,
    );

    final now = DateTime.now().toUtc();
    await repo.upsertAccount(
      Account(
        id: 'a1',
        userId: userContext.cachedUserId!,
        name: 'Cash',
        color: 0xFF000000,
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(queue.length, 0);

    canSync = true;
    await repo.upsertAccount(
      Account(
        id: 'a2',
        userId: userContext.cachedUserId!,
        name: 'Bank',
        color: 0xFF111111,
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect(queue.length, 1);
  });

  test('SyncService.flushPending no-ops when canSync is false', () async {
    final queue = PendingSyncQueue(pendingBox);
    await queue.enqueue(
      PendingSyncOperationType.upsertAccount,
      '{"id":"x"}',
    );
    var flushed = false;
    final sync = SyncServiceImpl(
      queue: queue,
      config: config(supabase: true),
      supabase: null,
      transactionsRepository: _UnusedTransactionsRepository(),
      canSync: () => false,
      onAfterFlush: () => flushed = true,
    );

    await sync.flushPending();
    expect(queue.length, 1);
    expect(flushed, isTrue);
  });
}

class _UnusedTransactionsRepository implements TransactionsRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
