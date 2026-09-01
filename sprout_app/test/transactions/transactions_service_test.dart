import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/error/error.dart';
import 'package:sprout/features/transactions/application/deposit_flow.dart';
import 'package:sprout/features/transactions/application/transactions_service_impl.dart';
import 'package:sprout/features/transactions/domain/transaction.dart';

import '../mocks/mocks.dart';

Transaction _deposit({
  required String accountId,
  String? goalId,
  required int cents,
  DateTime? occurredAt,
}) =>
    Transaction(
      id: 'd-$accountId-$cents',
      userId: 'u',
      accountId: accountId,
      kind: TransactionKind.deposit,
      goalId: goalId,
      amountCents: cents,
      occurredAt: occurredAt ?? DateTime(2026, 3, 1),
      pendingSync: false,
    );

void main() {
  late FakeTransactionsRepository repo;
  late TransactionsServiceImpl service;

  setUp(() {
    repo = FakeTransactionsRepository();
    service = TransactionsServiceImpl(repo);
  });

  tearDown(() async {
    await repo.dispose();
  });

  test('computeFundsSnapshot aggregates saved and unallocated cents', () {
    final now = DateTime(2026, 3, 15);
    final txs = [
      _deposit(accountId: 'a1', goalId: 'g1', cents: 500),
      _deposit(accountId: 'a1', goalId: null, cents: 1000),
    ];

    final snapshot = service.computeFundsSnapshot(
      transactions: txs,
      accountIds: ['a1'],
      now: now,
    );

    expect(snapshot.savedCentsByGoalId['g1'], 500);
    expect(snapshot.unallocatedCents, 1000);
  });

  test('unallocatedCentsForAccount delegates to calculator', () {
    final txs = [
      _deposit(accountId: 'a1', goalId: null, cents: 800),
    ];
    expect(service.unallocatedCentsForAccount(txs, 'a1'), 800);
  });

  group('submitDepositFlow', () {
    test('fullDepositToGoal writes one deposit', () async {
      await service.submitDepositFlow(
        mode: DepositFlowMode.fullDepositToGoal,
        accountId: 'a1',
        goalId: 'g1',
        depositAmountCents: 500,
        allocations: const [],
        occurredAt: DateTime(2026, 3, 1),
        groupId: 'grp',
      );

      expect(repo.addTransactionCalls, 1);
      expect(repo.lastAdded?.kind, TransactionKind.deposit);
      expect(repo.lastAdded?.goalId, 'g1');
    });

    test('allocateExistingUnallocated validates max', () async {
      expect(
        () => service.submitDepositFlow(
          mode: DepositFlowMode.allocateExistingUnallocated,
          accountId: 'a1',
          depositAmountCents: null,
          allocations: const [
            DepositAllocationInput(goalId: 'g1', amountCents: 500),
          ],
          occurredAt: DateTime(2026, 3, 1),
          groupId: 'grp',
          availableUnallocatedCents: 100,
        ),
        throwsA(isA<ValidationAppException>().having(
          (e) => e.message,
          'message',
          AppStrings.allocationsExceedUnallocated,
        )),
      );
    });

    test('depositToAccountThenAllocate writes deposit then allocations', () async {
      await service.submitDepositFlow(
        mode: DepositFlowMode.depositToAccountThenAllocate,
        accountId: 'a1',
        depositAmountCents: 1000,
        allocations: const [
          DepositAllocationInput(goalId: 'g1', amountCents: 400),
          DepositAllocationInput(goalId: 'g2', amountCents: 200),
        ],
        occurredAt: DateTime(2026, 3, 1),
        groupId: 'grp',
      );

      expect(repo.addTransactionCalls, 3);
    });
  });
}
