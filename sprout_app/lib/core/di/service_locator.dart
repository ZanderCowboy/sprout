import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/flags/remote_config_service.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/auth/export.dart';
import 'package:sprout/features/budget/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/sync/export.dart';
import 'package:sprout/features/transactions/export.dart';

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
    remoteConfigService ?? RemoteConfigService(),
  );
  sl.registerLazySingleton<TermsOfServiceService>(
    () => TermsOfServiceService(remoteConfig: sl()),
  );

  sl.registerSingleton<Box<AccountHiveModel>>(accountsBox);
  sl.registerSingleton<Box<GoalHiveModel>>(goalsBox);
  sl.registerSingleton<Box<BudgetGroupHiveModel>>(budgetGroupsBox);
  sl.registerSingleton<Box<TransactionHiveModel>>(transactionsBox);
  sl.registerSingleton<Box<PendingSyncHiveModel>>(pendingSyncBox);

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
    () => AuthService(
      authRepository: sl(),
      userContext: sl(),
      accountsBox: sl(),
      goalsBox: sl(),
      budgetGroupsBox: sl(),
      transactionsBox: sl(),
      pendingSyncQueue: sl(),
      flushPending: () => sl<SyncService>().flushPending(),
      pullRemote: () async {
        await sl<AccountsRepository>().pullRemote();
        await sl<GoalsRepository>().pullRemote();
        await sl<BudgetRepository>().pullRemote();
        await sl<TransactionsRepository>().pullRemote();
      },
    ),
  );

  bool canSync() => sl<AuthService>().canSync;

  final pendingForRepos = appConfig.isSupabaseConfigured ? pendingQueue : null;

  sl.registerLazySingleton<AccountsRepository>(
    () => AccountsRepositoryImpl(
      box: sl(),
      userContext: sl(),
      appConfig: sl(),
      supabase: supabaseClient,
      pendingSyncQueue: pendingForRepos,
      canSync: canSync,
    ),
  );

  sl.registerLazySingleton<GoalsRepository>(
    () => GoalsRepositoryImpl(
      box: sl(),
      userContext: sl(),
      appConfig: sl(),
      supabase: supabaseClient,
      pendingSyncQueue: pendingForRepos,
      canSync: canSync,
    ),
  );

  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(
      box: sl(),
      userContext: sl(),
      appConfig: sl(),
      supabase: supabaseClient,
      pendingSyncQueue: pendingForRepos,
      canSync: canSync,
    ),
  );

  sl.registerLazySingleton<TransactionsRepository>(
    () => TransactionsRepositoryImpl(
      box: sl(),
      userContext: sl(),
      appConfig: sl(),
      supabase: supabaseClient,
      pendingSyncQueue: pendingForRepos,
      canSync: canSync,
    ),
  );

  sl.registerLazySingleton<AccountsService>(() => AccountsService(sl()));
  sl.registerLazySingleton<GoalsService>(() => GoalsService(sl()));
  sl.registerLazySingleton<BudgetService>(() => BudgetService(sl()));
  sl.registerLazySingleton<TransactionsService>(
    () => TransactionsService(sl()),
  );

  sl.registerLazySingleton<SyncService>(
    () => SyncService(
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
