import 'account.dart';

abstract class AccountsRepository {
  Stream<List<Account>> watchAccounts();
  Future<List<Account>> getAccounts();
  Future<void> upsertAccount(Account account);
  Future<void> deleteAccount(String id);
  Future<void> pullRemote();
}
