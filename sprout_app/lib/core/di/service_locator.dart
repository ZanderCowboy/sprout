import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/budget/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/sync/export.dart';
import 'package:sprout/features/transactions/export.dart';

final sl = GetIt.instance;

Future<void> configureDependencies({
  required AppConfig appConfig,
  required Box<dynamic> settingsBox,
  required Box<AccountHiveModel> accountsBox,
  required Box<GoalHiveModel> goalsBox,
  required Box<BudgetGroupHiveModel> budgetGroupsBox,
  required Box<TransactionHiveModel> transactionsBox,
  required Box<PendingSyncHiveModel> pendingSyncBox,
  SupabaseClient? supabaseClient,
}) async {
  sl.registerSingleton<AppConfig>(appConfig);

  sl.registerSingleton<Box<AccountHiveModel>>(accountsBox);
  sl.registerSingleton<Box<GoalHiveModel>>(goalsBox);
  sl.registerSingleton<Box<BudgetGroupHiveModel>>(budgetGroupsBox);
  sl.registerSingleton<Box<TransactionHiveModel>>(transactionsBox);
  sl.registerSingleton<Box<PendingSyncHiveModel>>(pendingSyncBox);

  final pendingQueue = PendingSyncQueue(pendingSyncBox);
  sl.registerSingleton<PendingSyncQueue>(pendingQueue);

  final userContext = UserContext(
    settingsBox,
    supabaseClient: supabaseClient,
  );
  sl.registerSingleton<UserContext>(userContext);

  final pendingForRepos =
      appConfig.isSupabaseConfigured ? pendingQueue : null;

  sl.registerLazySingleton<AccountsRepository>(
    () => AccountsRepositoryImpl(
      box: sl(),
      userContext: sl(),
      appConfig: sl(),
      supabase: supabaseClient,
      pendingSyncQueue: pendingForRepos,
    ),
  );

  sl.registerLazySingleton<GoalsRepository>(
    () => GoalsRepositoryImpl(
      box: sl(),
      userContext: sl(),
      appConfig: sl(),
      supabase: supabaseClient,
      pendingSyncQueue: pendingForRepos,
    ),
  );

  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(
      box: sl(),
      userContext: sl(),
      appConfig: sl(),
      supabase: supabaseClient,
      pendingSyncQueue: pendingForRepos,
    ),
  );

  sl.registerLazySingleton<TransactionsRepository>(
    () => TransactionsRepositoryImpl(
      box: sl(),
      userContext: sl(),
      appConfig: sl(),
      supabase: supabaseClient,
      pendingSyncQueue: pendingForRepos,
    ),
  );

  sl.registerLazySingleton<AccountsService>(
    () => AccountsService(sl()),
  );
  sl.registerLazySingleton<GoalsService>(
    () => GoalsService(sl()),
  );
  sl.registerLazySingleton<BudgetService>(
    () => BudgetService(sl()),
  );
  sl.registerLazySingleton<TransactionsService>(
    () => TransactionsService(sl()),
  );

  sl.registerLazySingleton<SyncService>(
    () => SyncService(
      queue: sl(),
      config: sl(),
      supabase: supabaseClient,
      transactionsRepository: sl(),
    ),
  );

  pendingQueue.onEnqueued = () {
    unawaited(sl<SyncService>().flushPending());
  };

  if (supabaseClient != null) {
    sl.registerSingleton<SupabaseClient>(supabaseClient);
  }
}
