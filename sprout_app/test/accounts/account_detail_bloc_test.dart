import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/features/accounts/application/accounts_service_impl.dart';
import 'package:sprout/features/accounts/domain/account.dart';
import 'package:sprout/features/accounts/presentation/bloc/account_detail_bloc.dart';
import 'package:sprout/features/goals/application/goals_service_impl.dart';
import 'package:sprout/features/transactions/application/transactions_service_impl.dart';

import '../mocks/mocks.dart';

void main() {
  late FakeAccountsRepository accountsRepo;
  late FakeTransactionsRepository txRepo;
  late FakeGoalsRepository goalsRepo;
  late AccountDetailBloc bloc;

  Account account({required String id, required String name}) {
    return Account(
      id: id,
      userId: 'u',
      name: name,
      color: 0xFF000000,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  Future<AccountDetailReady> waitReady() async {
    final state = await bloc.stream.firstWhere((s) => s is AccountDetailReady);
    return state as AccountDetailReady;
  }

  setUp(() {
    accountsRepo = FakeAccountsRepository(
      initial: [account(id: 'a1', name: 'Cheque')],
    );
    txRepo = FakeTransactionsRepository();
    goalsRepo = FakeGoalsRepository();
    final txService = TransactionsServiceImpl(txRepo);
    bloc = AccountDetailBloc(
      accountsService: AccountsServiceImpl(accountsRepo),
      transactionsService: txService,
      goalsService: GoalsServiceImpl(goalsRepo, txService),
    );
  });

  tearDown(() async {
    await bloc.close();
    await accountsRepo.dispose();
    await txRepo.dispose();
    await goalsRepo.dispose();
  });

  test('refresh completes only after pullRemote finishes', () async {
    bloc.add(const AccountDetailSubscriptionRequested(accountId: 'a1'));
    await waitReady();

    accountsRepo.pullRemoteHold = Completer<void>();
    final event = AccountDetailRefreshRequested();
    bloc.add(event);
    await Future<void>.delayed(Duration.zero);
    expect(event.onComplete.isCompleted, isFalse);

    accountsRepo.pullRemoteHold!.complete();
    await event.onComplete.future;
    expect(event.onComplete.isCompleted, isTrue);
  });

  test('failed delete resumes the watch and reports an error', () async {
    bloc.add(const AccountDetailSubscriptionRequested(accountId: 'a1'));
    await waitReady();

    accountsRepo.deleteError = StateError('hive down');
    bloc.add(const AccountDetailDeleteRequested());
    final failed = await bloc.stream.firstWhere(
      (s) => s is AccountDetailReady && s.actionError != null,
    );
    expect(failed, isA<AccountDetailReady>());
    expect((failed as AccountDetailReady).actionError, AppStrings.couldNotDelete);
    expect(failed.account.name, 'Cheque');

    final nextFuture = bloc.stream.firstWhere(
      (s) => s is AccountDetailReady && s.account.name == 'Updated',
    );
    await accountsRepo.upsertAccount(account(id: 'a1', name: 'Updated'));
    final next = await nextFuture;
    expect((next as AccountDetailReady).account.name, 'Updated');
  });
}
