import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/error/error.dart';
import 'package:sprout/features/goals/application/goals_service.dart';
import 'package:sprout/features/goals/domain/goal.dart';
import 'package:sprout/features/transactions/application/transactions_service.dart';
import 'package:sprout/features/transactions/domain/transaction.dart';

import '../mocks/mocks.dart';

void main() {
  late FakeGoalsRepository goalsRepo;
  late FakeTransactionsRepository txRepo;
  late GoalsService goalsService;

  setUp(() {
    goalsRepo = FakeGoalsRepository();
    txRepo = FakeTransactionsRepository();
    goalsService = GoalsService(goalsRepo, TransactionsService(txRepo));
  });

  tearDown(() async {
    await goalsRepo.dispose();
    await txRepo.dispose();
  });

  test('createGoalWithOpeningBalance saves goal and writes deposit + allocation', () async {
    final goal = Goal(
      id: 'g1',
      userId: 'u',
      name: 'House',
      targetAmountCents: 100000,
      color: 0xFF0000,
      createdAt: DateTime(2026, 3, 1),
      updatedAt: DateTime(2026, 3, 1),
    );

    await goalsService.createGoalWithOpeningBalance(
      goal: goal,
      openingBalanceCents: 5000,
      openingBalanceAccountId: 'a1',
      groupId: 'grp',
      occurredAt: DateTime(2026, 3, 1),
    );

    expect(goalsRepo.lastUpserted?.id, 'g1');
    expect(txRepo.addTransactionCalls, 2);
    expect(txRepo.lastAdded?.kind, TransactionKind.allocation);
  });

  test('createGoalWithOpeningBalance requires account when balance positive', () async {
    final goal = Goal(
      id: 'g1',
      userId: 'u',
      name: 'House',
      targetAmountCents: 100000,
      color: 0xFF0000,
      createdAt: DateTime(2026, 3, 1),
      updatedAt: DateTime(2026, 3, 1),
    );

    expect(
      () => goalsService.createGoalWithOpeningBalance(
        goal: goal,
        openingBalanceCents: 100,
        openingBalanceAccountId: null,
        groupId: 'grp',
      ),
      throwsA(isA<ValidationAppException>().having(
        (e) => e.message,
        'message',
        AppStrings.pickAccountForOpeningBalance,
      )),
    );
  });
}
