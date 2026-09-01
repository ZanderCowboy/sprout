import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/error/error.dart';
import 'package:sprout/features/accounts/application/accounts_service_impl.dart';
import 'package:sprout/features/accounts/domain/account.dart';

import '../mocks/mocks.dart';

void main() {
  late FakeAccountsRepository repo;
  late AccountsServiceImpl service;

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

  setUp(() {
    repo = FakeAccountsRepository();
    service = AccountsServiceImpl(repo);
  });

  tearDown(() async {
    await repo.dispose();
  });

  test('saveAccount rejects a duplicate name', () async {
    await repo.upsertAccount(account(id: '1', name: 'Cheque'));

    expect(
      () => service.saveAccount(account(id: '2', name: 'cheque')),
      throwsA(
        isA<ValidationAppException>().having(
          (e) => e.message,
          'message',
          AppStrings.duplicateAccountName,
        ),
      ),
    );
  });

  test('saveAccount allows renaming the same account', () async {
    final existing = account(id: '1', name: 'Cheque');
    await repo.upsertAccount(existing);

    await service.saveAccount(account(id: '1', name: 'Cheque'));
    expect(repo.lastUpserted?.id, '1');
  });
}
