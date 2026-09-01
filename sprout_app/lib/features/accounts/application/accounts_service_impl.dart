import 'package:sprout/core/constants/constants.dart';
import 'package:sprout/core/error/error.dart';

import '../domain/account.dart';
import '../domain/accounts_repository.dart';
import 'accounts_service.dart';

class AccountsServiceImpl implements AccountsService {
  AccountsServiceImpl(this._repository);

  final AccountsRepository _repository;

  @override
  Stream<List<Account>> watchAccounts() => _repository.watchAccounts();

  @override
  Future<List<Account>> getAccounts() => _repository.getAccounts();

  @override
  Future<void> saveAccount(Account account) async {
    final existing = await _repository.getAccounts();
    final normalized = account.name.trim().toLowerCase();
    final duplicate = existing.any(
      (a) => a.id != account.id && a.name.trim().toLowerCase() == normalized,
    );
    if (duplicate) {
      throw ValidationAppException(AppStrings.duplicateAccountName);
    }
    await _repository.upsertAccount(account);
  }

  @override
  Future<void> removeAccount(String id) => _repository.deleteAccount(id);

  @override
  Future<void> pullRemote() => _repository.pullRemote();
}
