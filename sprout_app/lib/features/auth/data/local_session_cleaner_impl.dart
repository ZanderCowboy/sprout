import 'package:sprout/features/accounts/domain/accounts_repository.dart';
import 'package:sprout/features/budget/domain/budget_repository.dart';
import 'package:sprout/features/goals/domain/goals_repository.dart';
import 'package:sprout/features/sync/data/pending_sync_queue.dart';
import 'package:sprout/features/transactions/domain/transactions_repository.dart';

import '../domain/local_session_cleaner.dart';

class LocalSessionCleanerImpl implements LocalSessionCleaner {
  LocalSessionCleanerImpl({
    required AccountsRepository accountsRepository,
    required GoalsRepository goalsRepository,
    required BudgetRepository budgetRepository,
    required TransactionsRepository transactionsRepository,
    required PendingSyncQueue pendingQueue,
  }) : _accountsRepository = accountsRepository,
       _goalsRepository = goalsRepository,
       _budgetRepository = budgetRepository,
       _transactionsRepository = transactionsRepository,
       _pendingQueue = pendingQueue;

  final AccountsRepository _accountsRepository;
  final GoalsRepository _goalsRepository;
  final BudgetRepository _budgetRepository;
  final TransactionsRepository _transactionsRepository;
  final PendingSyncQueue _pendingQueue;

  @override
  Future<void> clearLocalEntityData() async {
    await _accountsRepository.clearLocal();
    await _goalsRepository.clearLocal();
    await _budgetRepository.clearLocal();
    await _transactionsRepository.clearLocal();
    await _pendingQueue.clear();
  }
}
