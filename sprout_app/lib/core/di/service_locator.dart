import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/flags/remote_config_service.dart';
import 'package:sprout/core/flags/remote_config_service_impl.dart';
import 'package:sprout/features/accounts/application/accounts_service_impl.dart';
import 'package:sprout/features/auth/application/auth_service_impl.dart';
import 'package:sprout/features/auth/application/privacy_policy_service_impl.dart';
import 'package:sprout/features/auth/application/terms_of_service_service_impl.dart';
import 'package:sprout/features/budget/application/budget_service_impl.dart';
import 'package:sprout/features/goals/application/goals_service_impl.dart';
import 'package:sprout/features/sync/application/sync_service_impl.dart';
import 'package:sprout/features/transactions/application/transactions_service_impl.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/accounts/application/accounts_service.dart';
import 'package:sprout/features/accounts/data/accounts_repository_impl.dart';
import 'package:sprout/features/accounts/data/local/account_hive_model.dart';
import 'package:sprout/features/accounts/domain/accounts_repository.dart';
import 'package:sprout/features/auth/application/auth_service.dart';
import 'package:sprout/features/auth/application/privacy_policy_service.dart';
import 'package:sprout/features/auth/application/terms_of_service_service.dart';
import 'package:sprout/features/auth/data/auth_repository_impl.dart';
import 'package:sprout/features/auth/domain/auth_repository.dart';
import 'package:sprout/features/budget/application/budget_service.dart';
import 'package:sprout/features/budget/data/budget_repository_impl.dart';
import 'package:sprout/features/budget/data/local/models/budget_group_hive_model.dart';
import 'package:sprout/features/budget/domain/budget_repository.dart';
import 'package:sprout/features/goals/application/goals_service.dart';
import 'package:sprout/features/goals/data/goals_repository_impl.dart';
import 'package:sprout/features/goals/data/local/models/goal_hive_model.dart';
import 'package:sprout/features/goals/domain/goals_repository.dart';
import 'package:sprout/features/purchases/presentation/premium_paywall_helper.dart';
import 'package:sprout/features/sync/application/sync_service.dart';
import 'package:sprout/features/sync/data/pending_sync_queue.dart';
import 'package:sprout/features/transactions/application/transactions_service.dart';
import 'package:sprout/features/transactions/data/local/pending_sync_hive_model.dart';
import 'package:sprout/features/transactions/data/local/transaction_hive_model.dart';
import 'package:sprout/features/transactions/data/transactions_repository_impl.dart';
import 'package:sprout/features/transactions/domain/transactions_repository.dart';

final sl = GetIt.instance;

bool _googleSignInInitialized = false;

Future<void> configureDependencies({
  required AppConfig appConfig,
  required Box<dynamic> settingsBox,
  required Box<AccountHiveModel> accountsBox,
  required Box<GoalHiveModel> goalsBox,
  required Box<BudgetGroupHiveModel> budgetGroupsBox,
  required Box<TransactionHiveModel> transactionsBox,
  required Box<PendingSyncHiveModel> pendingSyncBox,
  SupabaseClient? supabaseClient,
  RemoteConfigService? remoteConfigService,
}) async {
  sl.registerSingleton<AppConfig>(appConfig);
  sl.registerSingleton<RemoteConfigService>(
    remoteConfigService ?? RemoteConfigServiceImpl(),
  );
  sl.registerLazySingleton<TermsOfServiceService>(
    () => TermsOfServiceServiceImpl(remoteConfig: sl()),
  );
  sl.registerLazySingleton<PrivacyPolicyService>(
    () => PrivacyPolicyServiceImpl(remoteConfig: sl()),
  );

  // Entity boxes are owned by repositories, not registered on GetIt.
  // Settings is held by UserContext only.
  final pendingQueue = PendingSyncQueue(pendingSyncBox);
  sl.registerSingleton<PendingSyncQueue>(pendingQueue);

  final userContext = UserContext(settingsBox, supabaseClient: supabaseClient);
  sl.registerSingleton<UserContext>(userContext);

  GoogleSignIn? googleSignIn;
  if (appConfig.isGoogleSignInConfigured) {
    googleSignIn = GoogleSignIn.instance;
    if (!_googleSignInInitialized) {
      await googleSignIn.initialize(
        serverClientId: appConfig.googleWebClientId,
      );
      _googleSignInInitialized = true;
    }
    sl.registerSingleton<GoogleSignIn>(googleSignIn);
  }

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      supabase: supabaseClient,
      googleSignIn: googleSignIn,
    ),
  );

  sl.registerLazySingleton<AuthService>(
    () => AuthServiceImpl(
      authRepository: sl(),
      userContext: sl(),
      appConfig: sl(),
      clearLocalData: () async {
        await sl<AccountsRepository>().clearLocal();
        await sl<GoalsRepository>().clearLocal();
        await sl<BudgetRepository>().clearLocal();
        await sl<TransactionsRepository>().clearLocal();
        await sl<PendingSyncQueue>().clear();
      },
      flushPending: () => sl<SyncService>().flushPending(),
      pullRemote: () async {
        await sl<AccountsRepository>().pullRemote();
        await sl<GoalsRepository>().pullRemote();
        await sl<BudgetRepository>().pullRemote();
        await sl<TransactionsRepository>().pullRemote();
      },
      logOutPurchases: PremiumPaywall.logOutIfConfigured,
    ),
  );

  bool canSync() => sl<AuthService>().canSync;

  final pendingForRepos = appConfig.isSupabaseConfigured ? pendingQueue : null;

  sl.registerLazySingleton<AccountsRepository>(
    () => AccountsRepositoryImpl(
      box: accountsBox,
      userContext: sl(),
      appConfig: sl(),
      supabase: supabaseClient,
      pendingSyncQueue: pendingForRepos,
      canSync: canSync,
    ),
  );

  sl.registerLazySingleton<GoalsRepository>(
    () => GoalsRepositoryImpl(
      box: goalsBox,
      userContext: sl(),
      appConfig: sl(),
      supabase: supabaseClient,
      pendingSyncQueue: pendingForRepos,
      canSync: canSync,
    ),
  );

  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(
      box: budgetGroupsBox,
      userContext: sl(),
      appConfig: sl(),
      supabase: supabaseClient,
      pendingSyncQueue: pendingForRepos,
      canSync: canSync,
    ),
  );

  sl.registerLazySingleton<TransactionsRepository>(
    () => TransactionsRepositoryImpl(
      box: transactionsBox,
      userContext: sl(),
      appConfig: sl(),
      supabase: supabaseClient,
      pendingSyncQueue: pendingForRepos,
      canSync: canSync,
    ),
  );

  sl.registerLazySingleton<AccountsService>(() => AccountsServiceImpl(sl()));
  sl.registerLazySingleton<GoalsService>(() => GoalsServiceImpl(sl(), sl()));
  sl.registerLazySingleton<BudgetService>(() => BudgetServiceImpl(sl()));
  sl.registerLazySingleton<TransactionsService>(
    () => TransactionsServiceImpl(sl()),
  );

  sl.registerLazySingleton<SyncService>(
    () => SyncServiceImpl(
      queue: sl(),
      config: sl(),
      supabase: supabaseClient,
      transactionsRepository: sl(),
      canSync: canSync,
    ),
  );

  pendingQueue.onEnqueued = () {
    if (!canSync()) return;
    unawaited(sl<SyncService>().flushPending());
  };

  if (supabaseClient != null) {
    sl.registerSingleton<SupabaseClient>(supabaseClient);
  }
}
