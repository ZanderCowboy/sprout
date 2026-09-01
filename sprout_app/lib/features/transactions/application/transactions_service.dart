import 'dart:async';

import 'package:sprout/core/constants/constants.dart';
import 'package:sprout/core/error/error.dart';

import '../domain/funds_calculator.dart';
import '../domain/funds_snapshot.dart';
import '../domain/portfolio_summary.dart';
import '../domain/transaction.dart';
import '../domain/transaction_frequency.dart';
import '../domain/transaction_rules.dart';
import '../domain/transactions_repository.dart';
import 'deposit_flow.dart';

class TransactionsService {
  TransactionsService(this._repository);

  final TransactionsRepository _repository;

  Stream<List<Transaction>> watchTransactions() =>
      _repository.watchTransactions();

  Stream<PortfolioSummary> watchPortfolioSummary() =>
      _repository.watchPortfolioSummary();

  Stream<FundsSnapshot> watchFundsSnapshot({
    required Stream<List<String>> accountIdsStream,
  }) {
    return Stream<FundsSnapshot>.multi((controller) {
      List<Transaction> transactions = [];
      List<String> accountIds = [];

      void emitSnapshot() {
        controller.add(computeFundsSnapshot(
          transactions: transactions,
          accountIds: accountIds,
        ));
      }

      final txSub = watchTransactions().listen(
        (txs) {
          transactions = txs;
          emitSnapshot();
        },
        onError: controller.addError,
      );
      final accountsSub = accountIdsStream.listen(
        (ids) {
          accountIds = ids;
          emitSnapshot();
        },
        onError: controller.addError,
      );

      controller.onCancel = () {
        txSub.cancel();
        accountsSub.cancel();
      };
    });
  }

  FundsSnapshot computeFundsSnapshot({
    required List<Transaction> transactions,
    required List<String> accountIds,
    DateTime? now,
  }) {
    return FundsSnapshot(
      savedCentsByGoalId: FundsCalculator.savedCentsByGoalId(transactions, now: now),
      unallocatedCents: FundsCalculator.totalUnallocatedCents(
        transactions,
        accountIds,
        now: now,
      ),
      accountCurrentDepositTotalsById: FundsCalculator.accountDepositTotalsById(
        transactions,
        scheduled: false,
        now: now,
      ),
      accountScheduledDepositTotalsById: FundsCalculator.accountDepositTotalsById(
        transactions,
        scheduled: true,
        now: now,
      ),
    );
  }

  int unallocatedCentsForAccount(
    List<Transaction> transactions,
    String accountId, {
    DateTime? now,
  }) =>
      FundsCalculator.unallocatedCentsForAccount(
        transactions,
        accountId,
        now: now,
      );

  ({List<Transaction> scheduled, List<Transaction> history})
      splitScheduledAndHistory(
    List<Transaction> txs, {
    DateTime? now,
  }) =>
      TransactionRules.splitScheduledAndHistory(txs, now: now);

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

  Future<void> submitDepositFlow({
    required DepositFlowMode mode,
    required String accountId,
    String? goalId,
    required int? depositAmountCents,
    required List<DepositAllocationInput> allocations,
    required DateTime occurredAt,
    required String groupId,
    bool isRecurring = false,
    TransactionFrequency frequency = TransactionFrequency.none,
    int? availableUnallocatedCents,
  }) async {
    switch (mode) {
      case DepositFlowMode.fullDepositToGoal:
        if (depositAmountCents == null || depositAmountCents <= 0) {
          throw ValidationAppException(AppStrings.invalidAmount);
        }
        if (goalId == null || goalId.isEmpty) {
          throw ValidationAppException(AppStrings.pickAGoal);
        }
        await recordDeposit(
          accountId: accountId,
          goalId: goalId,
          groupId: null,
          amountCents: depositAmountCents,
          occurredAt: occurredAt,
          isRecurring: isRecurring,
          frequency: isRecurring ? frequency : TransactionFrequency.none,
        );
      case DepositFlowMode.allocateExistingUnallocated:
        final maxAllowed = availableUnallocatedCents;
        if (maxAllowed == null || maxAllowed <= 0) {
          throw ValidationAppException(AppStrings.noUnallocatedForAccount);
        }
        var allocatedTotal = 0;
        for (final row in allocations) {
          if (row.amountCents <= 0) continue;
          allocatedTotal += row.amountCents;
        }
        if (allocatedTotal <= 0) {
          throw ValidationAppException(AppStrings.enterAtLeastOneAllocation);
        }
        if (allocatedTotal > maxAllowed) {
          throw ValidationAppException(AppStrings.allocationsExceedUnallocated);
        }
        for (final row in allocations) {
          if (row.goalId.isEmpty || row.amountCents <= 0) continue;
          await recordAllocation(
            accountId: accountId,
            goalId: row.goalId,
            groupId: groupId,
            amountCents: row.amountCents,
            occurredAt: occurredAt,
          );
        }
      case DepositFlowMode.depositToAccountThenAllocate:
        if (depositAmountCents == null || depositAmountCents <= 0) {
          throw ValidationAppException(AppStrings.invalidAmount);
        }
        await recordAccountDeposit(
          accountId: accountId,
          groupId: groupId,
          amountCents: depositAmountCents,
          occurredAt: occurredAt,
          isRecurring: isRecurring,
          frequency: isRecurring ? frequency : TransactionFrequency.none,
        );
        var allocatedTotal = 0;
        for (final row in allocations) {
          if (row.amountCents <= 0) continue;
          allocatedTotal += row.amountCents;
        }
        if (allocatedTotal > depositAmountCents) {
          throw ValidationAppException(AppStrings.allocationsExceedDeposit);
        }
        for (final row in allocations) {
          if (row.goalId.isEmpty || row.amountCents <= 0) continue;
          await recordAllocation(
            accountId: accountId,
            goalId: row.goalId,
            groupId: groupId,
            amountCents: row.amountCents,
            occurredAt: occurredAt,
          );
        }
    }
  }

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
