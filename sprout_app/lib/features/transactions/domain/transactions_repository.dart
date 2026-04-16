import 'portfolio_summary.dart';
import 'transaction.dart';
import 'transaction_frequency.dart';

abstract class TransactionsRepository {
  Stream<List<Transaction>> watchTransactions();
  Stream<PortfolioSummary> watchPortfolioSummary();
  Future<List<Transaction>> getForAccount(String accountId);
  Future<List<Transaction>> getForGoal(String goalId);

  Future<void> addTransaction({
    required String accountId,
    required TransactionKind kind,
    String? goalId,
    String? groupId,
    required int amountCents,
    DateTime? occurredAt,
    String? note,
    bool isRecurring,
    TransactionFrequency frequency,
  });

  Future<void> updateTransactionNote({
    required String transactionId,
    required String? note,
  });

  Future<void> updateTransactionRecurringConfig({
    required String transactionId,
    required bool isRecurring,
    required TransactionFrequency frequency,
  });

  Future<void> deleteTransaction(String transactionId);

  /// Called after a successful remote insert (e.g. from [SyncService]).
  Future<void> markTransactionSynced(String id);

  Future<void> pullRemote();
}
