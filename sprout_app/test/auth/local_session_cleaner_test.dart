import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sprout/core/storage/hive_adapters.dart';
import 'package:sprout/features/accounts/domain/account.dart';
import 'package:sprout/features/auth/data/local_session_cleaner_impl.dart';
import 'package:sprout/features/goals/domain/goal.dart';
import 'package:sprout/features/sync/data/pending_sync_queue.dart';
import 'package:sprout/features/sync/domain/pending_sync_operation.dart';
import 'package:sprout/features/transactions/data/local/pending_sync_hive_model.dart';
import 'package:sprout/features/transactions/domain/transaction.dart';

import '../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<PendingSyncHiveModel> pendingBox;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('sprout_session_cleaner_');
    Hive.init(tempDir.path);
    registerHiveAdapters();
  });

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    pendingBox = await Hive.openBox<PendingSyncHiveModel>('pending_$stamp');
  });

  tearDown(() async {
    await pendingBox.deleteFromDisk();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('clears entity repositories and the pending queue', () async {
    final now = DateTime.utc(2026, 1, 1);
    final accounts = FakeAccountsRepository(
      initial: [
        Account(
          id: 'a1',
          userId: 'u1',
          name: 'Cash',
          color: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    final goals = FakeGoalsRepository(
      initial: [
        Goal(
          id: 'g1',
          userId: 'u1',
          name: 'Save',
          targetAmountCents: 1000,
          color: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    final budget = FakeBudgetRepository();
    final transactions = FakeTransactionsRepository(
      initial: [
        Transaction(
          id: 't1',
          userId: 'u1',
          accountId: 'a1',
          kind: TransactionKind.deposit,
          amountCents: 100,
          occurredAt: now,
          pendingSync: true,
        ),
      ],
    );
    final queue = PendingSyncQueue(pendingBox);
    await queue.enqueue(PendingSyncOperationType.upsertAccount, '{}');

    final cleaner = LocalSessionCleanerImpl(
      accountsRepository: accounts,
      goalsRepository: goals,
      budgetRepository: budget,
      transactionsRepository: transactions,
      pendingQueue: queue,
    );

    await cleaner.clearLocalEntityData();

    expect(await accounts.getAccounts(), isEmpty);
    expect(await goals.getGoals(), isEmpty);
    expect(await budget.getBudgetGroups(), isEmpty);
    expect(transactions.items, isEmpty);
    expect(queue.length, 0);
  });
}
