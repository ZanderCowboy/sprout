import '../domain/portfolio_summary.dart';
import '../domain/transaction.dart';
import '../domain/transaction_frequency.dart';

/// Transaction use-cases: deposits, allocations, and portfolio streams.
abstract class TransactionsService {
  /// Emits all transactions whenever local data changes.
  Stream<List<Transaction>> watchTransactions();

  /// Emits portfolio summary derived from transactions.
  Stream<PortfolioSummary> watchPortfolioSummary();

  /// Returns transactions linked to [accountId].
  Future<List<Transaction>> getForAccount(String accountId);

  /// Returns transactions allocated to [goalId].
  Future<List<Transaction>> getForGoal(String goalId);

  /// Records a deposit allocated to [goalId].
  Future<void> recordDeposit({
    required String accountId,
    required String goalId,
    String? groupId,
    required int amountCents,
    DateTime? occurredAt,
    String? note,
    bool isRecurring = false,
    TransactionFrequency frequency = TransactionFrequency.none,
  });

  /// Records a deposit to [accountId] without goal allocation.
  Future<void> recordAccountDeposit({
    required String accountId,
    String? groupId,
    required int amountCents,
    DateTime? occurredAt,
    String? note,
    bool isRecurring = false,
    TransactionFrequency frequency = TransactionFrequency.none,
  });

  /// Moves funds from unallocated balance to [goalId].
  Future<void> recordAllocation({
    required String accountId,
    required String goalId,
    String? groupId,
    required int amountCents,
    DateTime? occurredAt,
    String? note,
  });

  /// Updates the note on an existing transaction.
  Future<void> updateNote({
    required String transactionId,
    required String? note,
  });

  /// Updates recurring configuration on a deposit transaction.
  Future<void> updateRecurringDeposit({
    required String transactionId,
    required bool isRecurring,
    required TransactionFrequency frequency,
  });

  /// Deletes a transaction locally and enqueues remote sync.
  Future<void> deleteTransaction(String transactionId);

  /// Pulls transactions from Supabase when sync is allowed.
  Future<void> pullRemote();
}
