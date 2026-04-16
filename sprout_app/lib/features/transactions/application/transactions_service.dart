import '../domain/portfolio_summary.dart';
import '../domain/transaction.dart';
import '../domain/transaction_frequency.dart';
import '../domain/transactions_repository.dart';

class TransactionsService {
  TransactionsService(this._repository);

  final TransactionsRepository _repository;

  Stream<List<Transaction>> watchTransactions() =>
      _repository.watchTransactions();

  Stream<PortfolioSummary> watchPortfolioSummary() =>
      _repository.watchPortfolioSummary();

  Future<List<Transaction>> getForAccount(String accountId) =>
      _repository.getForAccount(accountId);

  Future<List<Transaction>> getForGoal(String goalId) =>
      _repository.getForGoal(goalId);

  Future<void> recordDeposit({
    required String accountId,
    required String goalId,
    String? groupId,
    required int amountCents,
    DateTime? occurredAt,
    String? note,
    bool isRecurring = false,
    TransactionFrequency frequency = TransactionFrequency.none,
  }) =>
      _repository.addTransaction(
        accountId: accountId,
        kind: TransactionKind.deposit,
        goalId: goalId,
        groupId: groupId,
        amountCents: amountCents,
        occurredAt: occurredAt,
        note: note,
        isRecurring: isRecurring,
        frequency: frequency,
      );

  Future<void> recordAccountDeposit({
    required String accountId,
    String? groupId,
    required int amountCents,
    DateTime? occurredAt,
    String? note,
    bool isRecurring = false,
    TransactionFrequency frequency = TransactionFrequency.none,
  }) =>
      _repository.addTransaction(
        accountId: accountId,
        kind: TransactionKind.deposit,
        goalId: null,
        groupId: groupId,
        amountCents: amountCents,
        occurredAt: occurredAt,
        note: note,
        isRecurring: isRecurring,
        frequency: frequency,
      );

  Future<void> recordAllocation({
    required String accountId,
    required String goalId,
    String? groupId,
    required int amountCents,
    DateTime? occurredAt,
    String? note,
  }) =>
      _repository.addTransaction(
        accountId: accountId,
        kind: TransactionKind.allocation,
        goalId: goalId,
        groupId: groupId,
        amountCents: amountCents,
        occurredAt: occurredAt,
        note: note,
        isRecurring: false,
        frequency: TransactionFrequency.none,
      );

  Future<void> updateNote({
    required String transactionId,
    required String? note,
  }) =>
      _repository.updateTransactionNote(
        transactionId: transactionId,
        note: note,
      );

  Future<void> updateRecurringDeposit({
    required String transactionId,
    required bool isRecurring,
    required TransactionFrequency frequency,
  }) =>
      _repository.updateTransactionRecurringConfig(
        transactionId: transactionId,
        isRecurring: isRecurring,
        frequency: frequency,
      );

  Future<void> deleteTransaction(String transactionId) =>
      _repository.deleteTransaction(transactionId);

  Future<void> pullRemote() => _repository.pullRemote();
}
