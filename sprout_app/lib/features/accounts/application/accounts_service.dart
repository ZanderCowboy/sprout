import '../domain/account.dart';

/// Account use-cases: unique-name validation and persist/delete/pull.
abstract class AccountsService {
  /// Emits accounts whenever local data changes.
  Stream<List<Account>> watchAccounts();

  /// Returns the current account list from local storage.
  Future<List<Account>> getAccounts();

  /// Saves [account] after rejecting duplicate names.
  ///
  /// Throws [ValidationAppException] if the name is taken.
  Future<void> saveAccount(Account account);

  /// Deletes the account with [id] locally and enqueues remote sync.
  Future<void> removeAccount(String id);

  /// Pulls accounts from Supabase when sync is allowed.
  Future<void> pullRemote();
}
