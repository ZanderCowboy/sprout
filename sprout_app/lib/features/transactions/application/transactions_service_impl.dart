import '../domain/portfolio_summary.dart';
import '../domain/transaction.dart';
import '../domain/transaction_frequency.dart';
import '../domain/transactions_repository.dart';
import 'transactions_service.dart';

class TransactionsServiceImpl implements TransactionsService {
  TransactionsServiceImpl(this._repository);

  final TransactionsRepository _repository;

  @override
  Stream<List<Transaction>> watchTransactions() =>
      _repository.watchTransactions();

  @override
  Stream<PortfolioSummary> watchPortfolioSummary() =>
      _repository.watchPortfolioSummary();

  @override
  Future<List<Transaction>> getForAccount(String accountId) =>
      _repository.getForAccount(accountId);

  @override
  Future<List<Transaction>> getForGoal(String goalId) =>
      _repository.getForGoal(goalId);

  @override
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

  @override
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

  @override
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

  @override
  Future<void> updateNote({
    required String transactionId,
    required String? note,
  }) =>
      _repository.updateTransactionNote(
        transactionId: transactionId,
        note: note,
      );

  @override
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

  @override
  Future<void> deleteTransaction(String transactionId) =>
      _repository.deleteTransaction(transactionId);

  @override
  Future<void> pullRemote() => _repository.pullRemote();
}
